import { Window } from 'tgui/layouts';
import { useBackend } from 'tgui/backend';

import { Planet } from './planet';
import type {
  PlanetMapData,
  PlanetObject,
  PlanetTile,
} from './types';

type PlanetMapProps = PlanetMapData;

export const RimworldPlanetMap = () => {
  const { data, act } =
    useBackend<PlanetMapProps>();

  const handleTileClick = (
    x: number,
    y: number,
    tile: PlanetTile,
  ) => {
    act('select_tile', {
      x,
      y,
      biome: tile.biome,
    });
  };

  const handleObjectClick = (
    object: PlanetObject,
  ) => {
    act('select_object', {
      id: object.id,
    });
  };

  return (
    <Window
      width={1100}
      height={800}
      theme="generic"
    >
      <Window.Content
        style={{
          padding: 0,
          overflow: 'hidden',
        }}
      >
        <Planet
          data={data}
          onTileClick={handleTileClick}
          onObjectClick={handleObjectClick}
        />
      </Window.Content>
    </Window>
  );
};
