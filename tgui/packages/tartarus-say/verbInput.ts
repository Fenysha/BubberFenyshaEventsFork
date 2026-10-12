// FENYSHA ADDITION - SAY_VERB_INPUT - shares the command bar's argument handling

import { isEntityArg, isTextArg, isTypepathArg } from 'common/verb-constants';
import {
  isInQuotedArg,
  parseArgs,
  serializeInput,
  suffixForArg,
  suggestForArg,
  suggestVerbs,
  type Target,
  toKebab,
  type Verb,
} from 'common/verb-input';
import { useState } from 'react';
import type { Channel } from './ChannelIterator';

/** Speech verbs switch the popup to that channel rather than running */
const CHANNEL_VERBS: Record<string, Channel> = {
  say: 'Say',
  whisper: 'Whis',
  me: 'Me',
  ooc: 'OOC',
  looc: 'LOOC',
  pray: 'Pray',
};

export type Suggestion = {
  label: string;
  detail: string;
  apply: () => void;
};

type Options = {
  value: string;
  setValue: (value: string) => void;
  onChannel: (channel: Channel) => void;
  onDone: () => void;
};

export function useVerbInput({ value, setValue, onChannel, onDone }: Options) {
  const [verbs, setVerbs] = useState<Verb[]>([]);
  const [targets, setTargets] = useState<Target[]>([]);
  const [typepaths, setTypepaths] = useState<string[]>([]);
  const [verb, setVerb] = useState<Verb | null>(null);
  const [filled, setFilled] = useState<string[]>([]);
  const [selected, setSelected] = useState(0);
  const [lastTypepathRequest, setLastTypepathRequest] = useState('');

  const argPortion = verb ? value.slice(toKebab(verb.name).length + 1) : '';
  const parsed = verb ? parseArgs(argPortion) : [];
  const currentArg = verb ? (verb.args[filled.length] ?? null) : null;
  const currentToken =
    parsed.length > filled.length ? parsed[filled.length] : '';

  function onInput(raw: string): void {
    let next = raw;
    let current = verb;

    if (!current) {
      next = next.replaceAll(' ', '');
    } else if (!next.startsWith(`${toKebab(current.name)} `)) {
      current = null;
      setVerb(null);
      setFilled([]);
      setLastTypepathRequest('');
      next = next.split(' ')[0] || '';
    }

    setValue(next);
    setSelected(0);
    if (!current) {
      return;
    }

    const afterVerb = next.slice(toKebab(current.name).length + 1);
    const arg = current.args[filled.length];

    // A string argument ends at its closing quote
    if (arg && isTextArg(arg)) {
      const typedArgs = parseArgs(afterVerb);
      if (typedArgs.length > filled.length && !isInQuotedArg(afterVerb)) {
        const filledNow = [...filled, typedArgs[filled.length]];
        setFilled(filledNow);
        const nextArg = current.args[filledNow.length];
        if (nextArg) {
          setValue(serializeInput(current, filledNow, suffixForArg(nextArg)));
          if (isEntityArg(nextArg)) {
            Byond.sendMessage('verbs/request_targets', {
              verb_type: current.type,
            });
          }
        }
      }
      return;
    }

    if (!arg || !isTypepathArg(arg)) {
      return;
    }
    const token = afterVerb.slice(
      filled.join(' ').length + (filled.length > 0 ? 1 : 0),
    );
    const lastSlash = token.lastIndexOf('/');
    if (lastSlash < 0) {
      return;
    }
    const parentPrefix = token.slice(0, lastSlash + 1);
    if (parentPrefix !== lastTypepathRequest) {
      setLastTypepathRequest(parentPrefix);
      Byond.sendMessage('verbs/request_typepaths', {
        parent: token.slice(0, lastSlash) || '/datum',
      });
    }
  }

  function reset(): void {
    setLastTypepathRequest('');
    setVerb(null);
    setFilled([]);
    setSelected(0);
    setTargets([]);
    setTypepaths([]);
  }

  function startVerb(next: Verb): void {
    const channel = CHANNEL_VERBS[toKebab(next.name).toLowerCase()];
    if (channel) {
      reset();
      onChannel(channel);
      return;
    }
    if (next.metadata === false) {
      // No metadata, so BYOND prompts for the arguments
      Byond.command(toKebab(next.name));
      reset();
      onDone();
      return;
    }
    if (next.args.length === 0) {
      runVerb(next, []);
      return;
    }
    setVerb(next);
    setFilled([]);
    setSelected(0);
    setValue(serializeInput(next, [], suffixForArg(next.args[0])));
    if (isEntityArg(next.args[0])) {
      Byond.sendMessage('verbs/request_targets', { verb_type: next.type });
    }
  }

  function fillArg(next: Verb, value: string): void {
    const filledNow = [...filled, value];
    setFilled(filledNow);
    setSelected(0);
    const nextArg = next.args[filledNow.length];
    setValue(serializeInput(next, filledNow, suffixForArg(nextArg)));
    if (nextArg && isEntityArg(nextArg)) {
      Byond.sendMessage('verbs/request_targets', { verb_type: next.type });
    }
  }

  function browseTypepath(next: Verb, path: string): void {
    Byond.sendMessage('verbs/request_typepaths', { parent: path });
    const prefix = filled.length > 0 ? `${filled.join(' ')} ` : '';
    setValue(`${toKebab(next.name)} ${prefix}${path}/`);
    setSelected(0);
  }

  function runVerb(next: Verb, args: string[]): void {
    const values: Record<string, string> = {};
    next.args.forEach((arg, index) => {
      if (index >= args.length) return;
      values[arg.name] = isTypepathArg(arg)
        ? args[index].replace(/\/+$/, '')
        : args[index];
    });
    Byond.sendMessage('verbs/invoke', { verb_type: next.type, args: values });
    reset();
    onDone();
  }

  const argSuggestions = (() => {
    if (!verb || !currentArg) return [];
    const { kind, values } = suggestForArg(currentArg, currentToken, {
      targets,
      typepaths,
    });
    return values.map((label) => ({
      label,
      detail: kind === 'target' ? 'target' : '',
      apply: () => {
        if (kind === 'typepath') {
          browseTypepath(verb, label);
          return;
        }
        if (kind === 'target') {
          const match = targets.find((target) => target.name === label);
          fillArg(verb, match ? match.ref : label);
          return;
        }
        fillArg(verb, label);
      },
    }));
  })();

  const verbSuggestions = verb
    ? []
    : suggestVerbs(verbs, value).map((option) => ({
        label: toKebab(option.name),
        detail: option.category ?? '',
        apply: () => startVerb(option),
      }));

  const suggestions: Suggestion[] = verb ? argSuggestions : verbSuggestions;
  const active = suggestions[Math.min(selected, suggestions.length - 1)];

  function submit(): void {
    if (active) {
      active.apply();
      return;
    }
    if (verb) {
      runVerb(verb, parsed);
      return;
    }
    const line = value.trim();
    if (!line) {
      onDone();
      return;
    }
    const typed = verbs.find(
      (option) =>
        toKebab(option.name).toLowerCase() ===
        line.split(/\s+/)[0].toLowerCase(),
    );
    if (typed) {
      startVerb(typed);
      return;
    }
    Byond.command(line);
    reset();
    onDone();
  }

  return {
    onInput,
    suggestions,
    selected: Math.min(selected, Math.max(suggestions.length - 1, 0)),
    setSelected,
    hasVerb: !!verb,
    complete: () => active?.apply(),
    submit,
    reset,
    setVerbs: (list: Verb[]) => setVerbs(list ?? []),
    setTargets: (list: Target[]) => setTargets(list ?? []),
    setTypepaths: (list: string[]) => setTypepaths(list ?? []),
  };
}
