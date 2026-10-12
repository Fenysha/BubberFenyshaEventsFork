/** Verb line parsing and suggestions, shared by the command bar and the say popup. */
import {
  isEntityArg,
  isListArg,
  isTextArg,
  isTypepathArg,
  type VerbArgBase,
} from './verb-constants';

export type VerbArg = VerbArgBase & {
  name: string;
};

export type Verb = {
  type: string;
  name: string;
  args: VerbArg[];
  category?: string;
  /** False when the server has no argument metadata for it */
  metadata?: boolean;
};

export type Target = {
  name: string;
  ref: string;
};

/** BYOND runs verbs with dashes for spaces. */
export function toKebab(name: string): string {
  return name.replaceAll(' ', '-');
}

/** Splits typed arguments, keeping quoted runs together. */
export function parseArgs(raw: string): string[] {
  const result: string[] = [];
  let i = 0;
  while (i < raw.length) {
    if (raw[i] === ' ') {
      i++;
      continue;
    }
    if (raw[i] === '"') {
      const end = raw.indexOf('"', i + 1);
      if (end === -1) {
        result.push(raw.slice(i + 1));
        break;
      }
      result.push(raw.slice(i + 1, end));
      i = end + 1;
    } else {
      const end = raw.indexOf(' ', i);
      if (end === -1) {
        result.push(raw.slice(i));
        break;
      }
      result.push(raw.slice(i, end));
      i = end;
    }
  }
  return result;
}

export function isInQuotedArg(raw: string): boolean {
  let inQuote = false;
  for (let i = 0; i < raw.length; i++) {
    if (raw[i] === '"') {
      inQuote = !inQuote;
    }
  }
  return inQuote;
}

export function serializeInput(
  verb: Verb,
  filled: string[],
  suffix = '',
): string {
  const kebab = toKebab(verb.name);
  if (filled.length === 0) return kebab + suffix;
  const parts = filled.map((a, i) => {
    const arg = verb.args[i];
    return arg && isTextArg(arg) ? `"${a}"` : a;
  });
  return `${kebab} ${parts.join(' ')}${suffix}`;
}

export function suffixForArg(arg: VerbArg | undefined): string {
  if (!arg) return '';
  if (isTextArg(arg)) return ' "';
  return ' ';
}

/** Prefix matches first, then substring matches. */
export function suggestVerbs(
  verbs: Verb[],
  query: string,
  limit = 8,
  compare: (a: Verb, b: Verb) => number = (a, b) =>
    a.name.length - b.name.length,
): Verb[] {
  if (!query) return [];
  const lower = query.toLowerCase();
  const prefix: Verb[] = [];
  const substring: Verb[] = [];
  for (const verb of verbs) {
    if (!verb.name) continue;
    const kebab = toKebab(verb.name).toLowerCase();
    if (kebab.startsWith(lower)) {
      prefix.push(verb);
    } else if (kebab.includes(lower)) {
      substring.push(verb);
    }
  }
  prefix.sort(compare);
  substring.sort(compare);
  return [...prefix, ...substring].slice(0, limit);
}

export function suggestForArg(
  arg: VerbArg | null,
  token: string,
  data: { targets: Target[]; typepaths: string[] },
  limit = 8,
): { kind: 'typepath' | 'target' | 'list' | 'none'; values: string[] } {
  if (!arg) {
    return { kind: 'none', values: [] };
  }
  const lower = token.toLowerCase();
  if (isTypepathArg(arg)) {
    return {
      kind: 'typepath',
      values: token.startsWith('/')
        ? data.typepaths
            .filter((path) => path.toLowerCase().startsWith(lower))
            .slice(0, limit)
        : [],
    };
  }
  if (isListArg(arg)) {
    return {
      kind: 'list',
      values: (arg.options ?? [])
        .filter((option) => !token || option.toLowerCase().startsWith(lower))
        .slice(0, limit),
    };
  }
  if (isEntityArg(arg)) {
    return {
      kind: 'target',
      values: data.targets
        .filter((target) => !token || target.name.toLowerCase().includes(lower))
        .slice(0, limit)
        .map((target) => target.name),
    };
  }
  return { kind: 'none', values: [] };
}
