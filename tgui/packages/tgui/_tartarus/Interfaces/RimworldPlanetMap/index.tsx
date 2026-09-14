import { useEffect, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Button, Stack } from 'tgui-core/components';

import { Planet } from './planet';
import {
  type PlanetMapData,
  type PlanetTile,
  type SelectedPlanetTile,
  selectedPlanetTileToPlanetTile,
} from './types';
import { AdminPanel } from './views/AdminPanel';
import { CaravanPanel } from './views/CaravanPanel';
import { OverviewPanel } from './views/OverviewPanel';
import { TileDetails } from './views/TileDetails';

export const RimworldPlanetMap = () => {
  const { data, act } = useBackend<PlanetMapData>();

  const [localTile, setLocalTile] = useState<PlanetTile | null>(null);
  const [showRightPanel, setShowRightPanel] = useState(true);

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
    setLocalTile(tile);
    act('select_tile', { x, y });
  };

  const handleObjectClick = (object: PlanetMapData['objects'][number]) => {
    act('select_object', { id: object.id });
  };

  const viewType = data.viewType || 'overview';
  const activeTile = data.selectedTile || localTile;
  const hasSelectedTile = !!activeTile;

  return (
    <Window
      width={1280}
      height={800}
      title={data.windowTitle || 'Planet Map'}
      theme="generic"
    >
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
        {/* Карта планеты */}
        <Planet
          data={data}
          selectedX={data.selectedTile?.x}
          selectedY={data.selectedTile?.y}
          onTileClick={handleTileClick}
          onObjectClick={handleObjectClick}
        />

        {/* Прозрачная панель кнопок в левом верхнем углу */}
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
                icon={showRightPanel ? 'eye-slash' : 'eye'}
                selected={showRightPanel}
                tooltip={showRightPanel ? 'Hide Controls' : 'Show Controls'}
                onClick={() => setShowRightPanel((prev) => !prev)}
              >
                {showRightPanel ? 'Hide Panel' : 'Show Panel'}
              </Button>
            </Stack.Item>
            {/* Дополнительные кнопки на будущее вставлять сюда */}
          </Stack>
        </div>

        {/* Панель информации о тайле в левом нижнем углу */}
        {hasSelectedTile && (
          <div
            className="rimworld-planet-map__tile-overlay"
            style={{
              position: 'absolute',
              bottom: '16px',
              left: '16px',
              width: '300px',
              maxHeight: '320px',
              backgroundColor: 'rgba(18, 22, 30, 0.92)',
              backdropFilter: 'blur(8px)',
              border: '1px solid rgba(255, 255, 255, 0.15)',
              borderRadius: '6px',
              padding: '12px',
              boxShadow: '0 8px 24px rgba(0, 0, 0, 0.65)',
              overflowY: 'auto',
              zIndex: 10,
            }}
          >
            <TileDetails
              tile={selectedPlanetTileToPlanetTile(
                activeTile as SelectedPlanetTile,
              )}
              title="Selected Tile Info"
            />
          </div>
        )}

        {/* Наложенная боковая панель управления в правом углу */}
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
            }}
          >
            {viewType === 'admin' && <AdminPanel />}
            {viewType === 'caravan' && <CaravanPanel />}
            {viewType === 'overview' && <OverviewPanel />}
          </div>
        )}
      </Window.Content>
    </Window>
  );
};
