import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Stack } from 'tgui-core/components';

import { Planet } from './planet';
import type { PlanetMapData, PlanetTile } from './types';
import { AdminPanel } from './views/AdminPanel';
import { CaravanPanel } from './views/CaravanPanel';
import { OverviewPanel } from './views/OverviewPanel';

export const RimworldPlanetMap = () => {
  const { data, act } = useBackend<PlanetMapData>();

  const [localTile, setLocalTile] = useState<PlanetTile | null>(null);

  const handleTileClick = (x: number, y: number, tile: PlanetTile) => {
    setLocalTile(tile);
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
        }}
      >
        <Stack fill>
          <Stack.Item grow>
            <Planet
              data={data}
              selectedX={data.selectedTile?.x}
              selectedY={data.selectedTile?.y}
              onTileClick={handleTileClick}
              onObjectClick={handleObjectClick}
            />
          </Stack.Item>
          <Stack.Item width="300px">
            <div className="rimworld-planet-map__sidebar">
              {viewType === 'admin' && <AdminPanel localTile={localTile} />}
              {viewType === 'caravan' && <CaravanPanel localTile={localTile} />}
              {viewType === 'overview' && (
                <OverviewPanel localTile={localTile} />
              )}
            </div>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
