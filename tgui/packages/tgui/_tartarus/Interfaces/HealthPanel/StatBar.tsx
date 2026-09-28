import { ProgressBar } from 'tgui-core/components';

type Props = {
  label: string;
  value: number;
  max?: number;
  color?: 'good' | 'average' | 'bad';
  format?: (value: number) => string;
};

export const StatBar = (props: Props) => {
  const { label, value, max = 100, color = 'good', format } = props;
  const safeValue = Math.max(0, Math.min(value, max));

  return (
    <div className="HealthPanel__stat">
      <div className="HealthPanel__stat-label">{label}</div>
      <ProgressBar value={safeValue / max} color={color}>
        {format ? format(value) : Math.round(value)}
      </ProgressBar>
    </div>
  );
};
