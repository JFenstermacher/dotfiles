import type { PrivateBoxConfig } from "./schema.js";

export interface KmsPolicyArgs {
  accountId: string;
  region: string;
  ownerPrincipalArn: string;
  deletionPrincipalArns?: string[];
}

function buildPolicyDocument(args: KmsPolicyArgs): any {
  const statements: any[] = [
    {
      Sid: "OwnerAccess",
      Effect: "Allow",
      Principal: {
        AWS: args.ownerPrincipalArn,
      },
      Action: [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:PutKeyPolicy",
        "kms:GetKeyPolicy",
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
        "kms:EnableKey",
        "kms:DisableKey",
        "kms:TagResource",
        "kms:UntagResource",
      ],
      Resource: "*",
    },
    {
      Sid: "OwnerEC2EBSServiceUse",
      Effect: "Allow",
      Principal: {
        AWS: args.ownerPrincipalArn,
      },
      Action: [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ],
      Resource: "*",
      Condition: {
        StringEquals: {
          "kms:ViaService": `ec2.${args.region}.amazonaws.com`,
          "kms:CallerAccount": args.accountId,
        },
      },
    },
    {
      Sid: "OwnerEC2EBSGrantManagement",
      Effect: "Allow",
      Principal: {
        AWS: args.ownerPrincipalArn,
      },
      Action: [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant",
      ],
      Resource: "*",
      Condition: {
        StringEquals: {
          "kms:ViaService": `ec2.${args.region}.amazonaws.com`,
          "kms:CallerAccount": args.accountId,
        },
        Bool: {
          "kms:GrantIsForAWSResource": true,
        },
      },
    },
  ];

  if (args.deletionPrincipalArns && args.deletionPrincipalArns.length > 0) {
    statements.push({
      Sid: "DeletionPrincipals",
      Effect: "Allow",
      Principal: {
        AWS: args.deletionPrincipalArns,
      },
      Action: [
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
        "kms:DescribeKey",
      ],
      Resource: "*",
    });
  }

  return {
    Version: "2012-10-17",
    Statement: statements,
  };
}

export function generateDefaultKmsPolicy(args: KmsPolicyArgs): string {
  return JSON.stringify(buildPolicyDocument(args));
}

export function resolveKmsPolicy(
  _config: PrivateBoxConfig,
  args: KmsPolicyArgs
): string {
  return generateDefaultKmsPolicy(args);
}
