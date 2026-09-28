import { ProgressBar } from 'tgui-core/components';

type Props = {
  label: string;
  value: number;
  max?: number;
  ranges?: Record<string, [number, number]>;
  dangerAt?: number;
};

export const StatBar = (props: Props) => {
  const { label, value, max = 100, ranges, dangerAt } = props;
  const ratio = value / max;

  let color = 'good';
  if (dangerAt !== undefined) {
    if (value >= dangerAt) color = 'bad';
    else if (value >= dangerAt * 0.6) color = 'average';
  } else if (ranges) {
    // fallback to ranges if provided
  } else {
    if (ratio < 0.3) color = 'bad';
    else if (ratio < 0.6) color = 'average';
  }

  return (
    <div className="HealthPanel__stat">
      <div className="HealthPanel__stat-label">{label}</div>
      <ProgressBar value={value} maxValue={max} ranges={ranges} color={color}>
        {Math.round(value)}
      </ProgressBar>
    </div>
  );
};
