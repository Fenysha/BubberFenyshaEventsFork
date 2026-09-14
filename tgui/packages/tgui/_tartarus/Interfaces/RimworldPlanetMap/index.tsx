import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';

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
          position: 'relative',
          width: '100%',
          height: '100%',
        }}
      >
        {/* Карта планеты во весь экран */}
        <Planet
          data={data}
          selectedX={data.selectedTile?.x}
          selectedY={data.selectedTile?.y}
          onTileClick={handleTileClick}
          onObjectClick={handleObjectClick}
        />

        {/* Наложенная плавающая панель управления в правом нижнем углу */}
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
          {viewType === 'admin' && <AdminPanel localTile={localTile} />}
          {viewType === 'caravan' && <CaravanPanel localTile={localTile} />}
          {viewType === 'overview' && <OverviewPanel localTile={localTile} />}
        </div>
      </Window.Content>
    </Window>
  );
};
