import {
  type PropsWithChildren,
  type ReactNode,
  type Ref,
  useEffect,
} from 'react';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { globalEvents } from 'tgui-core/events';
import { classes } from 'tgui-core/react';
import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { Layout } from '../../layouts/Layout';
import '../Styles/Minigame.scss';

/** DM's transparent host control over the map pane (MINIGAME_BROWSER) */
const MINIGAME_BROWSER = 'minigame_browser';

export type MinigameChip = { text: string; color?: 'good' | 'bad' | null };

export type MinigameRow = {
  label: string;
  value?: string;
  chips?: MinigameChip[];
};

export type MinigameProgress = {
  label: string;
  title: string;
  value: number;
  max: number;
  per_point: number;
  abandon_ratio: number;
};

export type MinigameResult<S> = {
  outcome: string;
  score: number;
  played_time: number;
  stats: S;
};

export type MinigameData<G, S> = {
  name: string;
  phase: 'briefing' | 'playing' | 'results';
  time_limit: number;
  context: MinigameRow[];
  progress: MinigameProgress | null;
  briefing_text: string | null;
  briefing: MinigameRow[];
  modifiers: MinigameChip[];
  decline_text: string;
  decline_hint: string | null;
  game: G;
  result?: MinigameResult<S>;
};

type WindowProps = PropsWithChildren<{
  theme?: string;
  width?: number;
  height?: number;
}>;

/**
 * Inside the transparent host it draws a dimming backdrop over the (greyed) map and centres the
 * game on it. Without the host, such as for clients with no chat panel, it is a normal window.
 */
export function MinigameWindow(props: WindowProps) {
  const { theme, width = 960, height = 720, children } = props;
  const { suspended } = useBackend();
  const embedded = Byond.windowId === MINIGAME_BROWSER;

  useEffect(() => {
    if (!embedded || suspended) {
      return;
    }
    // tgui.html paints the body; the host only shows through where nothing is drawn
    document.body.style.background = 'transparent';
    Byond.sendMessage('visible');
    globalEvents.emit('window-geometry-finished');
  }, [suspended]);

  if (!embedded) {
    return (
      <Window theme={theme} width={width} height={height}>
        <Window.Content scrollable>{children}</Window.Content>
      </Window>
    );
  }
  if (suspended) {
    return null;
  }
  return (
    <Layout theme={theme} className="MinigameHost">
      <div className="MinigameHost__backdrop" />
      <div className="MinigameHost__center">
        <div className="MinigameHost__panel">{children}</div>
      </div>
    </Layout>
  );
}

export function MinigameChips(props: { chips?: MinigameChip[] }) {
  return (
    <>
      {props.chips?.map((chip) => (
        <span
          key={chip.text}
          className={classes([
            'MinigameChip',
            chip.color && `MinigameChip--${chip.color}`,
          ])}
        >
          {chip.text}
        </span>
      ))}
    </>
  );
}

function Rows(props: { rows: MinigameRow[] }) {
  return (
    <>
      {props.rows.map((row) => (
        <LabeledList.Item key={row.label} label={row.label}>
          {row.value} <MinigameChips chips={row.chips} />
        </LabeledList.Item>
      ))}
    </>
  );
}

type ProgressProps = {
  progress: MinigameProgress;
  /** Progress this session would add, drawn as a striped segment */
  pending?: number;
  barRef?: Ref<HTMLDivElement>;
};

/** tgui's ProgressBar markup, plus the pending segment it has no prop for */
export function MinigameProgressBar(props: ProgressProps) {
  const { progress, pending = 0, barRef } = props;
  const max = Math.max(1, progress.max);
  const base = Math.min(progress.value, max);
  const added = Math.max(0, Math.min(pending, max - base));
  return (
    <div
      ref={barRef}
      className="ProgressBar ProgressBar--color--default MinigameProgress"
    >
      <div
        className="ProgressBar__fill ProgressBar__fill--animated"
        style={{ width: `${(base / max) * 100}%` }}
      />
      <div
        className="MinigameProgress__pending"
        style={{
          left: `${(base / max) * 100}%`,
          width: `${(added / max) * 100}%`,
        }}
      />
      <div className="ProgressBar__content">
        {base.toFixed(1)}
        {added > 0 && ` + ${added.toFixed(1)}`} / {max}
      </div>
    </div>
  );
}

type HeaderProps = {
  timer?: ReactNode;
  pending?: number;
  barRef?: Ref<HTMLDivElement>;
  onClose: () => void;
};

/** Title row and the caller's context: what is being worked on, where and by whom */
export function MinigameHeader<G, S>(props: HeaderProps) {
  const { timer, pending, barRef, onClose } = props;
  const { data } = useBackend<MinigameData<G, S>>();
  const { name, phase, context, progress } = data;
  return (
    <Section
      title={name}
      buttons={
        <Stack align="center">
          {timer && <Stack.Item>{timer}</Stack.Item>}
          <Stack.Item>
            <Button color="transparent" icon="times" onClick={onClose}>
              {phase === 'playing' ? 'Abandon' : 'Close'}
            </Button>
          </Stack.Item>
        </Stack>
      }
    >
      <Stack>
        <Stack.Item grow basis={0}>
          <LabeledList>
            <Rows rows={context} />
          </LabeledList>
        </Stack.Item>
        {progress && (
          <Stack.Item grow basis={0}>
            <Box className="MinigameLabel">{progress.label}</Box>
            <MinigameProgressBar
              progress={progress}
              pending={pending}
              barRef={barRef}
            />
            {phase === 'playing' && (
              <Box className="MinigameHint" mt={0.5}>
                Striped: what this session adds when you finish.
              </Box>
            )}
          </Stack.Item>
        )}
      </Stack>
    </Section>
  );
}

/** Rules, modifiers and the begin / decline choice */
export function MinigameBriefing<G, S>(props: { controls?: ReactNode }) {
  const { act, data } = useBackend<MinigameData<G, S>>();
  const { briefing_text, briefing, modifiers, decline_text, decline_hint } =
    data;
  return (
    <>
      <Section title="Briefing">
        {briefing_text && <NoticeBox>{briefing_text}</NoticeBox>}
        <LabeledList>
          <Rows rows={briefing} />
          {modifiers.length > 0 && (
            <LabeledList.Item label="Modifiers">
              <MinigameChips chips={modifiers} />
            </LabeledList.Item>
          )}
          {props.controls && (
            <LabeledList.Item label="Controls">
              {props.controls}
            </LabeledList.Item>
          )}
        </LabeledList>
      </Section>
      <Stack align="center" mt={0.5}>
        <Stack.Item grow className="MinigameHint">
          {decline_hint}
        </Stack.Item>
        <Stack.Item>
          <Button onClick={() => act('decline')}>{decline_text}</Button>
        </Stack.Item>
        <Stack.Item>
          <Button color="good" onClick={() => act('begin')}>
            Begin session
          </Button>
        </Stack.Item>
      </Stack>
    </>
  );
}

type ResultsProps = {
  /** Big letter or number summarising the run */
  grade?: string;
  /** The game's own report rows */
  children?: ReactNode;
};

/** Session report on the left, what it is worth to the caller's progress on the right */
export function MinigameResults<G, S>(props: ResultsProps) {
  const { act, data } = useBackend<MinigameData<G, S>>();
  const { progress, result } = data;
  const gained = result && progress ? result.score * progress.per_point : 0;
  return (
    <>
      <Stack>
        <Stack.Item grow basis={0}>
          <Section title="Session report" fill>
            <Stack align="center">
              {props.grade && (
                <Stack.Item className="MinigameGrade" mr={1}>
                  {props.grade}
                  <Box className="MinigameLabel">grade</Box>
                </Stack.Item>
              )}
              <Stack.Item grow>
                <LabeledList>{props.children}</LabeledList>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
        {progress && (
          <Stack.Item grow basis={0}>
            <Section title={`Filed to ${progress.title}`} fill>
              <LabeledList>
                <LabeledList.Item label="Score">
                  {result?.score ?? 0}
                </LabeledList.Item>
                <LabeledList.Item label="Rate">
                  {(progress.per_point * 100).toFixed(1)} per 100 points
                </LabeledList.Item>
                <LabeledList.Item label="Research">
                  <Box inline bold color="good">
                    +{gained.toFixed(1)}
                  </Box>
                </LabeledList.Item>
              </LabeledList>
              <Box mt={1}>
                <MinigameProgressBar
                  progress={{
                    ...progress,
                    value: Math.min(progress.max, progress.value + gained),
                  }}
                />
              </Box>
            </Section>
          </Stack.Item>
        )}
      </Stack>
      <Stack align="center" mt={0.5}>
        <Stack.Item grow className="MinigameHint">
          Closing hands the result back, which applies it.
        </Stack.Item>
        <Stack.Item>
          <Button color="good" onClick={() => act('close')}>
            Return
          </Button>
        </Stack.Item>
      </Stack>
    </>
  );
}
