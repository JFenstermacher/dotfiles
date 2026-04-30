# PrivateBox

A CLI tool for managing ephemeral AWS EC2 "private boxes" — personal dev/research
instances with configurable networking, owner-scoped KMS encryption for all storage,
and optional encrypted EBS-backed home volumes.

PrivateBox uses [Pulumi](https://www.pulumi.com/) under the hood (via the Automation
API) to provision and manage cloud resources, while providing a fast, interactive
CLI experience built on [Bun](https://bun.sh/).

## Features

- **Ephemeral EC2 instances** — spin up personal dev boxes on demand, tear them down
  when done
- **Owner-scoped KMS encryption** — all EBS volumes (root + optional home) are
  encrypted with a per-box customer-managed KMS key. The generated key policy
  restricts decrypt/admin access to the owner principal only; root/admin do not
  get implicit access
- **Optional encrypted home volume** — an independent EBS volume mounted at
  `/home/<user>` that persists across AMI updates and instance replacements
- **Auto-generated or BYO SSH keys** — use an existing key (`file://` or inline),
  or let PrivateBox generate and manage an ed25519 key pair
- **Fuzzy-finder UI** — interactive selection when you omit a config name
- **AWS profile & region aware** — respects `AWS_PROFILE`, `AWS_REGION`, and
  `~/.aws/config`
- **Local state** — Pulumi state is stored locally under `$XDG_DATA_HOME`; no
  Pulumi Cloud account required

## Prerequisites

- [Bun](https://bun.sh/) (used as both runtime and package manager)
- AWS credentials configured (`~/.aws/credentials` or SSO)
- `ssh-keygen` (bundled with OpenSSH on macOS and Linux)

## Installation

```bash
cd apps/privatebox
bun install
```

For global CLI access, link the bin:

```bash
bun link
privatebox --help
```

Or run directly:

```bash
bun run src/index.ts --help
```

## Quick Start

```bash
# Create and review a config in $EDITOR
privatebox configure my-dev-box

# Provision or update the box. Add --ssh-config to create Host pb-my-dev-box.
privatebox apply my-dev-box --ssh-config

# Connect, then stop/start as needed
privatebox connect my-dev-box
privatebox down my-dev-box
privatebox up my-dev-box

# Tear down cloud resources, then optionally remove the local config
privatebox destroy my-dev-box
privatebox delete my-dev-box
```

## Configuration

Configs are stored as YAML files under:

```text
$XDG_CONFIG_HOME/privatebox/configs/<name>.yml
```

### Example Config

```yaml
name: my-dev-box
ami: ami-0abcdef1234567890
instance_type: t4g.medium
aws_profile: default
aws_region: us-east-1
username: ubuntu
owner_principal_arn: ""
kms_deletion_principal_arns: []
kms_deletion_window_days: 30
vpc_id: ""
subnet_id: ""
enable_public_ip: true
ingress:
  - name: ssh
    description: Allow SSH from office
    protocol: tcp
    from_port: 22
    to_port: 22
    ipv4_cidrs:
      - 203.0.113.0/24
    ipv6_cidrs: []
egress:
  - name: allow-all-out
    description: Allow all outbound traffic
    protocol: "-1"
    from_port: 0
    to_port: 65535
    ipv4_cidrs:
      - 0.0.0.0/0
    ipv6_cidrs:
      - "::/0"
use_volume: false
volume_size: 20
volume_device: /dev/sdf
public_key: "file:///home/user/.ssh/id_ed25519.pub"
connect_command: "ssh ${username}@${public_ip}"
userdata: ""
```

### Key Fields

| Field | Description |
|-------|-------------|
| `ami` | AMI ID for the EC2 instance. The `configure` command pre-fills the latest Ubuntu 24.04 LTS ARM64 AMI. |
| `aws_profile` / `aws_region` | AWS profile and region used for all API calls and Pulumi operations. |
| `username` | Linux user created/managed on the instance and used for SSH. |
| `owner_principal_arn` | IAM user or role ARN that owns the generated KMS key policy. If empty, defaults to the current caller at apply time. |
| `kms_deletion_principal_arns` | Additional principals allowed only to schedule/cancel KMS key deletion (not decrypt). |
| `enable_public_ip` | Whether to associate a public IPv4 address. |
| `ingress` / `egress` | Security group rules. Supports TCP, UDP, ICMP, and all traffic (`-1`). |
| `public_key` | `file://<path>`, inline SSH key, or `""` to auto-generate. |
| `connect_command` | Command template used by `privatebox connect`. Defaults to `ssh ${username}@${public_ip}`. Supports `${username}`, `${public_ip}`, `${private_ip}`, and `${public_key_path}`. |
| `use_volume` / `volume_size` | Create an encrypted EBS home volume of the given size (GiB). |
| `userdata` | `file://<path>` or inline shell script appended after the PrivateBox bootstrap. |

## CLI Reference

```text
PrivateBox — Manage ephemeral AWS EC2 instances

Usage:
  privatebox <command> [options]

Commands:
  configure [--from <name>] [--skip-ami] <name>
                                      Create a new private box config
  apply [name] [--ssh-config]       Reconcile cloud resources to latest config
  create [name] [--ssh-config]      Alias for apply
  up [name]                         Start a stopped instance
  down [name]                       Stop a running instance
  connect [name]                    Connect using the configured command
  destroy [name]                    Destroy all cloud resources
  delete [name]                     Delete a config file (requires destroy first)
  edit [name]                       Edit an existing config
  list configs|cfg|instances|inst   List configs or instances
  get config [name]                 Show a single config's details
  get instance [name]               Show instance state (IP, status, uptime, etc.)

Options:
  --help, -h     Show this help
  --version, -v  Show version
```

### Commands

#### `configure [--from <source>] [--skip-ami] <name>`

Create a new config. Opens `$EDITOR` with a scaffold pre-filled with the latest
AMI, current AWS profile/region, and sensible defaults. The `name` field is
omitted from the editor — the CLI argument is enforced.

Use `--from <source>` to clone an existing config as a template. The name is
cleared, the AMI is re-resolved, and the current profile/region are injected.

Use `--skip-ami` to avoid the AMI lookup and fill in the AMI manually before
saving the editor buffer.

#### `apply [name] [--ssh-config]` / `create [name] [--ssh-config]`

Reconcile cloud resources to match the config:

1. Loads and validates the config
2. Resolves AWS identity, VPC/subnet/AZ, generated KMS policy, and SSH key
3. Generates the EC2 bootstrap script
4. Shows a formatted summary and asks for confirmation
5. Runs Pulumi preview with streamed output
6. Asks for final confirmation
7. Runs Pulumi up to create/update resources
8. Displays outputs (instance ID, IPs, KMS key, volume)
9. Optionally appends an SSH config snippet to `~/.ssh/config` (`--ssh-config`)

`create` is an alias for `apply`.

#### `up [name]` / `down [name]`

Start or stop the EC2 instance using the AWS SDK. These are fast operations
that preserve all other resources (KMS key, security group, volume, etc.).

Both are no-ops if the instance is already in the target state.

#### `connect [name]`

Render the config's `connect_command` and replace the command process with it.
The default command is `ssh ${username}@${public_ip}`. Available template
variables are `${username}`, `${public_ip}`, `${private_ip}`, and
`${public_key_path}`. Template values are shell-quoted before execution.

If `${public_key_path}` is used and `public_key` is an inline SSH public key,
PrivateBox writes it to `$XDG_DATA_HOME/privatebox/keys/<name>/public_key.pub`
so the variable can refer to that file. For `file://` keys, it resolves to the
referenced path; for auto-generated keys, it resolves to the generated
`id_ed25519.pub` path.

#### `destroy [name]`

Tear down **all** cloud resources for a private box using Pulumi destroy. This
requires typing the config name to confirm. After destruction, the local Pulumi
stack workspace is cleaned up. The config YAML file is **preserved**.

#### `delete [name]`

Delete the local config YAML file. **Blocked** if a Pulumi stack still exists.
Run `destroy` first.

#### `edit [name]`

Open an existing config in `$EDITOR`. Validates on save. Supports renaming the
config, but rejects the rename if a Pulumi stack exists for the old name.

#### `list configs|cfg|instances|inst`

`list configs` shows all configs as a table.
`list instances` shows configs with active stacks, including live EC2 status.

#### `get config [name]` / `get instance [name]`

`get config` displays the full YAML, file path, and last modified date.
`get instance` displays a detailed card with live EC2 metadata merged with
Pulumi stack outputs.

If `[name]` is omitted for any command that accepts it, a fuzzy finder launches
to let you interactively select a config or instance.

## Security Model

### KMS Key Policy

PrivateBox always generates a **strict owner-scoped KMS key policy**. Custom
KMS policies are intentionally not supported; the config surface is limited to
the owner principal, optional deletion-only principals, and deletion window.

The generated policy has these properties:

- **No root-account statement** — account admins/root do not get implicit
  decrypt or policy-edit access.
- **Owner principal** gets full admin and cryptographic use of the key.
- **Deletion-only principals** (if configured) can only schedule/cancel key
  deletion — they cannot decrypt, encrypt, or edit the policy.
- **EC2/EBS service access** is granted only when the owner principal calls EC2/EBS
  in the configured account/region; other account principals cannot use a self-created
  EC2 instance, EBS volume, or snapshot path to obtain decrypt access. Grant creation
  is additionally constrained by `kms:GrantIsForAWSResource`.

> ⚠️ **Warning**: Because the policy deliberately excludes root/admin, loss of
> the owner principal can make data unrecoverable. Ensure the owner principal
> ARN is durable (use an IAM role ARN, not a temporary assumed-role session).

### SSH Keys

Three modes are supported:

| Mode | Config Value | Behavior |
|---|---|---|
| File reference | `file:///home/user/.ssh/id_ed25519.pub` | Reads public key from disk |
| Inline key | `ssh-ed25519 AAAAC3... user@host` | Uses material directly |
| Auto-generate | `""` or omitted | Generates/reuses ed25519 pair at `$XDG_DATA_HOME/privatebox/keys/<name>/id_ed25519` |

Auto-generated keys are created with directory permissions `0700` and file
permissions `0600`.

## Storage

### Root Volume

The root EBS volume is always encrypted with the PrivateBox KMS key and set to
`deleteOnTermination: true`. It is destroyed when the instance is replaced or
the stack is destroyed.

### Home Volume (Optional)

When `use_volume: true`, PrivateBox creates an independent encrypted EBS volume
and mounts it at `/home/<username>`. The bootstrap script:

- Waits for the device (handles `/dev/sdX` → `/dev/xvdX` mapping)
- Formats **only when empty** (preserves data across instance replacements)
- Mounts via UUID in `/etc/fstab`

The home volume is preserved across AMI updates and instance type changes,
provided the Availability Zone does not change.

## Migrating Older Configs

If you have configs from an earlier PrivateBox version, remove these fields:

```yaml
ssh_user: ...
kms_policy: ...
schedule: ...
```

Use `username` for both the Linux user and SSH user. KMS policy generation is
now always managed by PrivateBox. Automatic cron-based start/stop scheduling has
been removed; use `privatebox up` and `privatebox down` manually.

## Development

```bash
cd apps/privatebox
bun run src/index.ts --help
./test/smoke.sh
npx tsc --noEmit
```

## XDG Base Directories

PrivateBox respects XDG conventions:

| Purpose | Path |
|---------|------|
| Config files | `$XDG_CONFIG_HOME/privatebox/configs/<name>.yml` |
| Pulumi workspaces | `$XDG_DATA_HOME/privatebox/stacks/<name>/` |
| Pulumi state backend | `$XDG_DATA_HOME/privatebox/pulumi-state/` |
| SSH keys | `$XDG_DATA_HOME/privatebox/keys/<name>/` |
| Cache (drafts) | `$XDG_CACHE_HOME/privatebox/` |

Defaults follow `~/.config`, `~/.local/share`, and `~/.cache`.

## License

MIT
