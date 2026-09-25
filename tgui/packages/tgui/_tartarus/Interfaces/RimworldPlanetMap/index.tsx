import { useEffect, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Button, Stack } from 'tgui-core/components';

import { FullscreenWindow } from '../../layouts/FullscreenWindow';
import { type CellInteraction, Planet } from './planet';
import type { PlanetMapData, PlanetTile } from './types';

import { AdminPanel } from './views/AdminPanel';
import { CaravanPanel } from './views/CaravanPanel';
import { OverviewPanel } from './views/OverviewPanel';
import { SettlementPanel } from './views/SettlementPanel';
import { TileDetails } from './views/TileDetails';

export const RimworldPlanetMap = () => {
  const { data, act } = useBackend<PlanetMapData>();

  const [localTile, setLocalTile] = useState<PlanetTile | null>(null);
  const [showRightPanel, setShowRightPanel] = useState(true);
  const [isPlanetLoading, setIsPlanetLoading] = useState(true);

  // State toggles for visual effects
  const [showAtmosphere, setShowAtmosphere] = useState(true);
  const [showClouds, setShowClouds] = useState(true);

  // Bump to request camera recenter on player tile
  const [centerOnPlayerRequest, setCenterOnPlayerRequest] = useState(0);

  const hasPlayerOnMap =
    data.playerX != null &&
    data.playerY != null &&
    Number.isFinite(data.playerX) &&
    Number.isFinite(data.playerY);

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

  // Not handled DM-side yet; the payload is what a cell action is likely to need
  const actOnCell = (action: string, cell: CellInteraction) => {
    act(action, {
      x: cell.x,
      y: cell.y,
      biome: cell.tile.biome,
      subBiome: cell.tile.subBiome,
      elevation: cell.tile.elevation,
      material: cell.tile.material,
      objectId: cell.object?.id ?? null,
      shift: cell.shift,
      ctrl: cell.ctrl,
      alt: cell.alt,
    });
  };

  const handleObjectClick = (object: PlanetMapData['objects'][number]) => {
    act('select_object', {
      id: object.id,
    });
  };

  const handleCenterOnSelf = () => {
    if (!hasPlayerOnMap) return;
    setCenterOnPlayerRequest((n) => n + 1);
  };

  const viewType = data.viewType || 'overview';
  const activeTile: PlanetTile | null = (() => {
    if (localTile && data.selectedTile) {
      return {
        ...localTile,
        ...data.selectedTile,
        river: Boolean(data.selectedTile.river ?? localTile.river),
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
        river: Boolean(data.selectedTile.river),
        objects: data.selectedTile.objects ?? [],
      };
    }

    return null;
  })();

  const selectedX = localTile?.x ?? data.selectedTile?.x;
  const selectedY = localTile?.y ?? data.selectedTile?.y;

  return (
    <FullscreenWindow theme="tartarus">
      <FullscreenWindow.Content
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
          playerX={data.playerX}
          playerY={data.playerY}
          centerOnPlayerRequest={centerOnPlayerRequest}
          showAtmosphere={showAtmosphere}
          showClouds={showClouds}
          onTileClick={handleTileClick}
          onObjectClick={handleObjectClick}
          onTileDoubleClick={(cell) => actOnCell('tile_double_click', cell)}
          onTileRightClick={(cell) => actOnCell('tile_right_click', cell)}
          onLoadingChange={setIsPlanetLoading}
        />

        {!isPlanetLoading && (
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
                  tooltip={
                    showAtmosphere ? 'Hide Atmosphere' : 'Show Atmosphere'
                  }
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

              {hasPlayerOnMap && (
                <Stack.Item>
                  <Button
                    icon="crosshairs"
                    tooltip="Center map on your current tile"
                    onClick={handleCenterOnSelf}
                  >
                    Center on Self
                  </Button>
                </Stack.Item>
              )}

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
        )}

        {!isPlanetLoading && activeTile && (
          <div
            className="rimworld-planet-map__tile-overlay"
            style={{
              position: 'absolute',
              bottom: '16px',
              left: '16px',
              width: '340px',
              maxHeight: 'calc(100% - 32px)',
              backgroundColor: 'hsla(0, 0%, 4%, 0.92)',
              backdropFilter: 'blur(8px)',
              border: '1px solid var(--tartarus-border)',
              padding: '12px',
              overflowY: 'auto',
              zIndex: 30,
            }}
          >
            <TileDetails tile={activeTile} title="Selected Tile" />
          </div>
        )}

        {!isPlanetLoading && showRightPanel && (
          <div
            className="rimworld-planet-map__overlay"
            style={{
              position: 'absolute',
              bottom: '16px',
              right: '16px',
              width: '350px',
              maxHeight: 'calc(100% - 32px)',
              backgroundColor: 'hsla(0, 0%, 4%, 0.92)',
              backdropFilter: 'blur(8px)',
              border: '1px solid var(--tartarus-border)',
              padding: '12px',
              overflowY: 'auto',
              zIndex: 10,
              pointerEvents: 'auto',
            }}
          >
            {viewType === 'admin' && <AdminPanel />}

            {viewType === 'caravan' && <CaravanPanel />}

            {viewType === 'overview' && <OverviewPanel />}

            {viewType === 'settlement' && <SettlementPanel />}
          </div>
        )}
      </FullscreenWindow.Content>
    </FullscreenWindow>
  );
};
