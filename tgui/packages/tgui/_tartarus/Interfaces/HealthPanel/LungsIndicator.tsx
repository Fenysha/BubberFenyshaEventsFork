import type { CSSProperties } from 'react';
import { Box } from 'tgui-core/components';
import { TOOLTIPS } from './tooltips';
import type { LungsData } from './types';

export const LUNGS_FRAME_HEIGHT = 112;

type Props = {
  lungs: LungsData;
  oxygenation?: number;
  ventilation?: number;
  iconSize?: number;
  iconScale?: number;
  /**
   * Pixel offset of the icon from the center of the icon slot.
   * +X right, +Y down. Does not affect frame size.
   */
  offsetX?: number;
  offsetY?: number;
  absolutePosition?: boolean;
  /** Override frame height (defaults to LUNGS_FRAME_HEIGHT). */
  frameHeight?: number;
};

const wordScale = (
  value: number,
  danger: number,
  warning: number,
  higherIsBetter = true,
): { text: string; color: string } => {
  const v = higherIsBetter ? value : 100 - value;
  const d = higherIsBetter ? danger : 100 - danger;
  const w = higherIsBetter ? warning : 100 - warning;

  if (v <= d) return { text: 'bad', color: 'bad' };
  if (v <= w) return { text: 'poor', color: 'average' };
  if (v < (higherIsBetter ? 90 : 20)) return { text: 'fair', color: 'average' };
  return { text: 'normal', color: 'good' };
};

function toPngSrc(value: string) {
  if (value.startsWith('data:')) return value;
  return `data:image/png;base64,${value}`;
}

function buildIconPlacement(opts: {
  iconSize: number;
  iconScale: number;
  offsetX: number;
  offsetY: number;
  absolutePosition: boolean;
}): CSSProperties {
  const { iconSize, iconScale, offsetX, offsetY, absolutePosition } = opts;

  if (absolutePosition) {
    return {
      position: 'absolute',
      left: offsetX,
      top: offsetY,
      width: iconSize,
      height: iconSize,
      transform: `scale(${iconScale})`,
      transformOrigin: 'top left',
      pointerEvents: 'none',
    };
  }

  return {
    position: 'absolute',
    left: '50%',
    top: '50%',
    width: iconSize,
    height: iconSize,
    transform: `translate(calc(-50% + ${offsetX}px), calc(-50% + ${offsetY}px)) scale(${iconScale})`,
    transformOrigin: 'center center',
    pointerEvents: 'none',
  };
}

export const LungsIndicator = (props: Props) => {
  const {
    lungs,
    iconSize = 40,
    iconScale = 1,
    offsetX = 0,
    offsetY = 0,
    absolutePosition = false,
    frameHeight = LUNGS_FRAME_HEIGHT,
  } = props;

  const oxygenation = props.oxygenation ?? lungs.oxygenation ?? 0;
  const ventilationPct =
    props.ventilation ??
    (lungs.ventilation > 1 ? lungs.ventilation : lungs.ventilation * 100);
  const fluidRatio = Math.max(0, Math.min(1, lungs.fluid_ratio ?? 0));

  const spo2 = wordScale(oxygenation, 55, 85, true);
  const vent = wordScale(ventilationPct, 30, 70, true);

  const hasIcon = !!lungs.iconSrc;
  const iconSrc = hasIcon ? toPngSrc(lungs.iconSrc!) : null;

  const placement = buildIconPlacement({
    iconSize,
    iconScale,
    offsetX,
    offsetY,
    absolutePosition,
  });

  // Fixed layout slot for the icon — does not drive frame width/height.
  const slotSize = 36;

  return (
    <div className="HealthPanel__lungs">
      <div className="HealthPanel__lungs-frame" style={{ height: frameHeight }}>
        <Box
          className="HealthPanel__lungs-metric HealthPanel__lungs-metric--left"
          //title={TOOLTIPS.ventilation}
        >
          <div className="HealthPanel__lungs-side-label">Vent</div>
          <Box bold color={vent.color} fontSize="0.9em">
            {vent.text}
          </Box>
          <Box color="label" fontSize="0.65em">
            {Math.round(ventilationPct)}%
          </Box>
        </Box>

        <div
          className="HealthPanel__lungs-stage"
          style={{ width: slotSize, height: slotSize }}
          title={TOOLTIPS.lungFluid}
        >
          {hasIcon && iconSrc ? (
            <>
              <img
                className="HealthPanel__lungs-icon"
                src={iconSrc}
                alt=""
                draggable={false}
                style={placement}
              />
              <div
                className="HealthPanel__lungs-fluid"
                style={{
                  ...placement,
                  WebkitMaskImage: `url(${iconSrc})`,
                  WebkitMaskSize: '100% 100%',
                  WebkitMaskRepeat: 'no-repeat',
                  WebkitMaskPosition: 'center',
                  maskImage: `url(${iconSrc})`,
                  maskSize: '100% 100%',
                  maskRepeat: 'no-repeat',
                  maskPosition: 'center',
                  backgroundImage: `linear-gradient(
                    to top,
                    rgba(180, 30, 40, 0.92) 0%,
                    rgba(220, 60, 50, 0.75) 55%,
                    rgba(220, 60, 50, 0.35) 100%
                  )`,
                  backgroundRepeat: 'no-repeat',
                  backgroundPosition: 'bottom center',
                  backgroundSize: `100% ${fluidRatio * 100}%`,
                }}
              />
            </>
          ) : (
            <div
              className="HealthPanel__lungs-icon HealthPanel__lungs-icon--fallback"
              style={placement}
            >
              Lungs
            </div>
          )}

          {!lungs.present && (
            <div className="HealthPanel__lungs-missing">×</div>
          )}
        </div>

        <Box
          className="HealthPanel__lungs-metric HealthPanel__lungs-metric--right"
          //title={TOOLTIPS.oxygenation}
        >
          <div className="HealthPanel__lungs-side-label">SpO₂</div>
          <Box bold color={spo2.color} fontSize="0.9em">
            {spo2.text}
          </Box>
          <Box color="label" fontSize="0.65em">
            {Math.round(oxygenation)}%
          </Box>
        </Box>
      </div>
    </div>
  );
};
