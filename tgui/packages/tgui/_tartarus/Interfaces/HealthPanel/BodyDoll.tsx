import { useEffect, useState } from 'react';
import { Box, Button, Stack } from 'tgui-core/components';
import { type BodyDollZone, getBodyDollOffset } from './bodyDollOffsets';
import type { BodypartData, OrganData } from './types';

type Props = {
  bodyparts: Record<string, BodypartData>;
  organs: {
    brain: OrganData;
    heart: OrganData;
    lungs: OrganData;
  };
  selectedZone: string | null;
  onSelect: (zone: string) => void;
  /** Current shock 0..SHOCK_MAX — drives whole-doll tremor */
  shock?: number;
};

const SCALE = 2;

/**
 * Cache generated clip paths so the same DMI sprite does not have to be
 * decoded and scanned multiple times.
 */
const alphaClipPathCache = new Map<string, Promise<string | null>>();

const getPartState = (
  data?: BodypartData,
): 'missing' | 'good' | 'warning' | 'bad' => {
  if (!data?.present) {
    return 'missing';
  }

  const structuralDamage = 1 - data.structural_integrity / 100;
  const skinDamage = 1 - data.skin_integrity / 100;

  const severeInjury = data.injuries.some((injury) => injury.severity >= 3);

  if (data.bleed_rate >= 3 || structuralDamage >= 0.75 || severeInjury) {
    return 'bad';
  }

  if (
    data.bleed_rate > 0 ||
    structuralDamage >= 0.35 ||
    skinDamage >= 0.35 ||
    data.disabled
  ) {
    return 'warning';
  }

  return 'good';
};

/**
 * The DMI sprites are grayscale-oriented.
 * These filters provide the medical-state tint without requiring
 * separate icon states for healthy/wounded/missing bodyparts.
 */
const getIconFilter = (state: ReturnType<typeof getPartState>): string => {
  switch (state) {
    case 'bad':
      return 'brightness(0) saturate(100%) invert(21%) sepia(97%) saturate(4880%) hue-rotate(350deg) brightness(98%) contrast(94%)';

    case 'warning':
      return 'brightness(0) saturate(100%) invert(76%) sepia(95%) saturate(1410%) hue-rotate(347deg) brightness(101%) contrast(101%)';

    case 'good':
      return 'brightness(0) saturate(100%) invert(52%) sepia(88%) saturate(1165%) hue-rotate(174deg) brightness(96%) contrast(96%)';

    default:
      return 'grayscale(1) opacity(0.3)';
  }
};

const zoneLabel = (data: BodypartData | undefined, zone: string) => {
  if (!data?.present) {
    return `${zone} — absent`;
  }

  const state = getPartState(data);

  if (state === 'bad') {
    return `${data.name} — critical`;
  }

  if (state === 'warning') {
    if (data.bleed_rate > 0) {
      return `${data.name} — bleeding`;
    }

    if (data.disabled) {
      return `${data.name} — disabled`;
    }

    return `${data.name} — injured`;
  }

  return `${data.name} — intact`;
};

function toPngSrc(value: string) {
  if (value.startsWith('data:')) {
    return value;
  }

  return `data:image/png;base64,${value}`;
}

/**
 * Creates a CSS path from the non-transparent pixels of a PNG.
 */
function buildAlphaClipPath(
  src: string,
  targetWidth: number,
  targetHeight: number,
): Promise<string | null> {
  const cacheKey = `${src}|${targetWidth}|${targetHeight}`;

  const cached = alphaClipPathCache.get(cacheKey);
  if (cached) {
    return cached;
  }

  const promise = new Promise<string | null>((resolve) => {
    const image = new Image();

    image.onload = () => {
      const width = image.naturalWidth || image.width;
      const height = image.naturalHeight || image.height;

      if (!width || !height) {
        resolve(null);
        return;
      }

      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;

      const context = canvas.getContext('2d', {
        willReadFrequently: true,
      });

      if (!context) {
        resolve(null);
        return;
      }

      context.clearRect(0, 0, width, height);
      context.drawImage(image, 0, 0);

      let pixels: ImageData;

      try {
        pixels = context.getImageData(0, 0, width, height);
      } catch {
        resolve(null);
        return;
      }

      const scaleX = targetWidth / width;
      const scaleY = targetHeight / height;
      const pathParts: string[] = [];

      const format = (value: number) => Number(value.toFixed(2));

      for (let y = 0; y < height; y++) {
        let x = 0;

        while (x < width) {
          const pixelIndex = (y * width + x) * 4;
          const alpha = pixels.data[pixelIndex + 3];

          if (alpha === 0) {
            x++;
            continue;
          }

          const startX = x;

          while (x < width) {
            const currentIndex = (y * width + x) * 4;

            if (pixels.data[currentIndex + 3] === 0) {
              break;
            }

            x++;
          }

          const endX = x;

          const left = format(startX * scaleX);
          const right = format(endX * scaleX);
          const top = format(y * scaleY);
          const bottom = format((y + 1) * scaleY);

          pathParts.push(
            `M ${left} ${top}` +
              `H ${right}` +
              `V ${bottom}` +
              `H ${left}` +
              'Z',
          );
        }
      }

      resolve(pathParts.length > 0 ? pathParts.join(' ') : null);
    };

    image.onerror = () => {
      resolve(null);
    };

    image.src = src;
  });

  alphaClipPathCache.set(cacheKey, promise);

  return promise;
}

function useAlphaClipPath(
  src: string | undefined,
  width: number,
  height: number,
) {
  const [clipPath, setClipPath] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    setClipPath(null);

    if (!src) {
      return;
    }

    buildAlphaClipPath(src, width, height).then((path) => {
      if (!cancelled) {
        setClipPath(path);
      }
    });

    return () => {
      cancelled = true;
    };
  }, [src, width, height]);

  return clipPath;
}

const getSelectedOutlineColor = (
  state: ReturnType<typeof getPartState>,
): string => {
  switch (state) {
    case 'bad':
      return 'rgba(255, 80, 80, 0.95)';

    case 'warning':
      return 'rgba(255, 205, 70, 0.95)';

    case 'good':
      return 'rgba(80, 220, 255, 0.95)';

    default:
      return 'rgba(180, 180, 180, 0.75)';
  }
};

/** Shock 0–100 → CSS animation intensity class */
const shockClass = (shock = 0): string => {
  if (shock >= 75) return 'HealthPanel__doll--shake-heavy';
  if (shock >= 50) return 'HealthPanel__doll--shake-medium';
  if (shock >= 25) return 'HealthPanel__doll--shake-light';
  return '';
};

function BodypartArt(props: {
  data?: BodypartData;
  state: ReturnType<typeof getPartState>;
  selected: boolean;
}) {
  const { data, state, selected } = props;

  if (!data?.present || !data.iconSrc) {
    return <Box className="HealthPanel__doll-missing">×</Box>;
  }

  const iconFilter = getIconFilter(state);
  const outlineColor = getSelectedOutlineColor(state);

  const selectedFilter = selected
    ? `
      drop-shadow(1px 0 0 ${outlineColor})
      drop-shadow(-1px 0 0 ${outlineColor})
      drop-shadow(0 1px 0 ${outlineColor})
      drop-shadow(0 -1px 0 ${outlineColor})
      drop-shadow(1px 1px 0 ${outlineColor})
      drop-shadow(-1px -1px 0 ${outlineColor})
      drop-shadow(1px -1px 0 ${outlineColor})
      drop-shadow(-1px 1px 0 ${outlineColor})
    `
    : '';

  return (
    <img
      className="HealthPanel__doll-icon"
      src={toPngSrc(data.iconSrc)}
      alt=""
      draggable={false}
      style={{
        filter: `${iconFilter} ${selectedFilter}`,
        width: '100%',
        height: '100%',
        objectFit: 'contain',
        objectPosition: 'center center',
        imageRendering: 'pixelated',
        pointerEvents: 'none',
        display: 'block',
      }}
    />
  );
}

export const BodyDoll = (props: Props) => {
  const { bodyparts, organs, selectedZone, onSelect, shock = 0 } = props;

  const zones: BodyDollZone[] = [
    'head',
    'l_arm',
    'chest',
    'r_arm',
    'l_leg',
    'r_leg',
  ];

  const shake = shockClass(shock);

  return (
    <Stack vertical fill align="center">
      <Stack.Item>
        <Box className={['HealthPanel__doll', shake].filter(Boolean).join(' ')}>
          {zones.map((zone) => (
            <ZoneButton
              key={zone}
              zone={zone}
              data={bodyparts[zone]}
              selected={selectedZone === zone}
              onSelect={onSelect}
            />
          ))}
        </Box>
      </Stack.Item>

      <Stack.Item>
        <Stack className="HealthPanel__doll-organs" justify="center">
          <Stack.Item>
            <OrganButton
              label="Brain"
              data={organs.brain}
              selected={selectedZone === 'brain'}
              onClick={() => onSelect('brain')}
              critical={
                !organs.brain.present || (organs.brain.oxygen ?? 100) < 30
              }
            />
          </Stack.Item>

          <Stack.Item>
            <OrganButton
              label="Heart"
              data={organs.heart}
              selected={selectedZone === 'heart'}
              onClick={() => onSelect('heart')}
              critical={
                !organs.heart.present ||
                organs.heart.state === 'stopped' ||
                organs.heart.state === 'missing' ||
                organs.heart.state === 'fibrillating' ||
                organs.heart.fibrillating === true ||
                organs.heart.rhythm === 'asystole' ||
                organs.heart.rhythm === 'ventricular_fibrillation'
              }
            />
          </Stack.Item>

          <Stack.Item>
            <OrganButton
              label="Lungs"
              data={organs.lungs}
              selected={selectedZone === 'lungs'}
              onClick={() => onSelect('lungs')}
              critical={!organs.lungs.present || !organs.lungs.functional}
            />
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

const ZoneButton = (props: {
  zone: BodyDollZone;
  data?: BodypartData;
  selected: boolean;
  onSelect: (zone: string) => void;
}) => {
  const { zone, data, selected, onSelect } = props;

  const offset = getBodyDollOffset(data?.sprite_id, data?.limb_gender, zone);

  const state = getPartState(data);

  /**
   * Scale the visual slot, but keep the geometric center on the original
   * offset so differently-sized DMI sprites still land on the silhouette.
   */
  const width = offset.width * SCALE;
  const height = offset.height * SCALE;

  const left = offset.x - (width - offset.width) / 2;
  const top = offset.y - (height - offset.height) / 2;

  const iconSrc = data?.iconSrc ? toPngSrc(data.iconSrc) : undefined;

  const clipPath = useAlphaClipPath(iconSrc, width, height);

  const selectedClass = selected ? 'HealthPanel__doll-part--selected' : '';

  return (
    <Box
      className={[
        'HealthPanel__doll-part',
        `HealthPanel__doll-part--${state}`,
        selectedClass,
      ]
        .filter(Boolean)
        .join(' ')}
      style={{
        left: `${left}px`,
        top: `${top}px`,
        width: `${width}px`,
        height: `${height}px`,
        pointerEvents: 'none',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        overflow: 'hidden',
      }}
    >
      <Button
        className="HealthPanel__doll-hitbox"
        onClick={() => onSelect(zone)}
        tooltip={zoneLabel(data, zone)}
        style={{
          pointerEvents: clipPath ? 'auto' : 'none',
          clipPath: clipPath ? `path('${clipPath}')` : 'none',
        }}
      />

      <BodypartArt data={data} state={state} selected={selected} />

      {data?.present && data.bleed_rate > 0 && (
        <span className="HealthPanel__doll-bleed" />
      )}

      {data?.present && data.disabled && (
        <span className="HealthPanel__doll-disabled">!</span>
      )}
    </Box>
  );
};

const OrganButton = (props: {
  label: string;
  data: OrganData;
  selected: boolean;
  critical: boolean;
  onClick: () => void;
}) => {
  const { label, data, critical, onClick } = props;

  const warning = !critical && (data.health < 50 || data.failing);

  return (
    <Button
      className="HealthPanel__doll-organ"
      color={critical ? 'bad' : warning ? 'average' : 'good'}
      onClick={onClick}
      tooltip={data.status}
    >
      {label}
    </Button>
  );
};
