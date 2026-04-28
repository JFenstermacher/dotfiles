import { parse, stringify } from "yaml";
import type {
  CreateNodeOptions,
  DocumentOptions,
  ParseOptions,
  SchemaOptions,
  ToStringOptions,
} from "yaml";

const yamlStringifyOptions: DocumentOptions &
  SchemaOptions &
  ParseOptions &
  CreateNodeOptions &
  ToStringOptions = {
  lineWidth: 0,
  aliasDuplicateObjects: false,
  sortMapEntries: false,
};

export function parseYaml(content: string): unknown {
  return parse(content);
}

export function stringifyYaml(value: unknown): string {
  return stringify(value, yamlStringifyOptions);
}
