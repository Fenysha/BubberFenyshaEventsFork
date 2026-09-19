import { useEffect, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Button, Stack } from 'tgui-core/components';

import { FullscreenWindow } from '../../layouts/FullscreenWindow';
import { Planet } from './planet';
import type { PlanetMapData, PlanetTile } from './types';

import { AdminPanel } from './views/AdminPanel';
import { CaravanPanel } from './views/CaravanPanel';
import { OverviewPanel } from './views/OverviewPanel';
import { TileDetails } from './views/TileDetails';

export const RimworldPlanetMap = () => {
  const { data, act } = useBackend<PlanetMapData>();

  const [localTile, setLocalTile] = useState<PlanetTile | null>(null);
  const [showRightPanel, setShowRightPanel] = useState(true);

  // State toggles for visual effects
  const [showAtmosphere, setShowAtmosphere] = useState(true);
  const [showClouds, setShowClouds] = useState(true);

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        act('close');
      }
    };

    window.addEventListener('keydown', handleKeyDown);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [act]);

  const handleTileClick = (x: number, y: number, tile: PlanetTile) => {
    const selectedTile: PlanetTile = {
      ...tile,
      x,
      y,
    };

    setLocalTile(selectedTile);
    act('select_tile', {
      x,
      y,
    });
  };

  const handleObjectClick = (object: PlanetMapData['objects'][number]) => {
    act('select_object', {
      id: object.id,
    });
  };

  const viewType = data.viewType || 'overview';
  const activeTile: PlanetTile | null = (() => {
    if (localTile && data.selectedTile) {
      return {
        ...localTile,
        ...data.selectedTile,
      };
    }

    if (localTile) {
      return localTile;
    }

    if (data.selectedTile) {
      return {
        x: data.selectedTile.x,
        y: data.selectedTile.y,
        biome: data.selectedTile.biome ?? 'Unknown',
        subBiome: data.selectedTile.subBiome ?? 'plains',
        material: data.selectedTile.material ?? 'none',
        latitude: data.selectedTile.latitude ?? 0,
        temperature: data.selectedTile.temperature ?? 0,
        heat: data.selectedTile.heat ?? '0',
        humidity: data.selectedTile.humidity ?? '0',
        precipitation: data.selectedTile.precipitation ?? 0,
        rainfall: data.selectedTile.rainfall ?? 0,
        snowfall: data.selectedTile.snowfall ?? 0,
        waterAvailability: data.selectedTile.waterAvailability ?? 0,
        elevation: data.selectedTile.elevation ?? '0',
        objects: data.selectedTile.objects ?? [],
      };
    }

    return null;
  })();

  const selectedX = localTile?.x ?? data.selectedTile?.x;
  const selectedY = localTile?.y ?? data.selectedTile?.y;

  return (
    <FullscreenWindow theme="generic">
      <Window.Content
        className="rimworld-planet-map"
        style={{
          padding: 0,
          overflow: 'hidden',
          position: 'relative',
          width: '100%',
          height: '100%',
        }}
      >
        <Planet
          data={data}
          selectedX={selectedX}
          selectedY={selectedY}
          showAtmosphere={showAtmosphere}
          showClouds={showClouds}
          onTileClick={handleTileClick}
          onObjectClick={handleObjectClick}
        />

        <div
          style={{
            position: 'absolute',
            top: '16px',
            left: '16px',
            zIndex: 20,
            pointerEvents: 'none',
          }}
        >
          <Stack style={{ pointerEvents: 'auto' }}>
            <Stack.Item>
              <Button
                color="danger"
                icon="times"
                tooltip="Close (Esc)"
                onClick={() => act('close')}
              >
                Close
              </Button>
            </Stack.Item>

            <Stack.Item>
              <Button
                icon={showAtmosphere ? 'globe' : 'globe-americas'}
                selected={showAtmosphere}
                tooltip={showAtmosphere ? 'Hide Atmosphere' : 'Show Atmosphere'}
                onClick={() => setShowAtmosphere((prev) => !prev)}
              >
                Atmosphere
              </Button>
            </Stack.Item>

            <Stack.Item>
              <Button
                icon={showClouds ? 'cloud' : 'cloud-sun'}
                selected={showClouds}
                tooltip={showClouds ? 'Hide Clouds' : 'Show Clouds'}
                onClick={() => setShowClouds((prev) => !prev)}
              >
                Clouds
              </Button>
            </Stack.Item>

            <Stack.Item>
              <Button
                icon={showRightPanel ? 'eye-slash' : 'eye'}
                selected={showRightPanel}
                tooltip={showRightPanel ? 'Hide Controls' : 'Show Controls'}
                onClick={() => setShowRightPanel((previous) => !previous)}
              >
                {showRightPanel ? 'Hide Panel' : 'Show Panel'}
              </Button>
            </Stack.Item>
          </Stack>
        </div>

        {activeTile && (
          <div
            className="rimworld-planet-map__tile-overlay"
            style={{
              position: 'absolute',
              bottom: '16px',
              left: '16px',
              width: '340px',
              maxHeight: 'calc(100% - 32px)',
              backgroundColor: 'rgba(18, 22, 30, 0.94)',
              backdropFilter: 'blur(8px)',
              border: '1px solid rgba(255, 255, 255, 0.15)',
              borderRadius: '6px',
              padding: '12px',
              boxShadow: '0 8px 24px rgba(0, 0, 0, 0.65)',
              overflowY: 'auto',
              zIndex: 30,
            }}
          >
            <TileDetails tile={activeTile} title="Selected Tile" />
          </div>
        )}

        {showRightPanel && (
          <div
            className="rimworld-planet-map__overlay"
            style={{
              position: 'absolute',
              bottom: '16px',
              right: '16px',
              width: '350px',
              maxHeight: 'calc(100% - 32px)',
              backgroundColor: 'rgba(18, 22, 30, 0.92)',
              backdropFilter: 'blur(8px)',
              border: '1px solid rgba(255, 255, 255, 0.15)',
              borderRadius: '6px',
              padding: '12px',
              boxShadow: '0 8px 24px rgba(0, 0, 0, 0.65)',
              overflowY: 'auto',
              zIndex: 10,
              pointerEvents: 'auto',
            }}
          >
            {viewType === 'admin' && <AdminPanel />}

            {viewType === 'caravan' && <CaravanPanel />}

            {viewType === 'overview' && <OverviewPanel />}
          </div>
        )}
      </Window.Content>
    </FullscreenWindow>
  );
};
