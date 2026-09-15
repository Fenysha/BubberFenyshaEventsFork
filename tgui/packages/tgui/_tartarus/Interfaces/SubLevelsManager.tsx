import { useCallback, useEffect, useRef, useState } from 'react';
import {
  Box,
  Button,
  Divider,
  Dropdown,
  Input,
  LabeledList,
  NumberInput,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { useBackend } from '../../backend';
import { Window } from '../../layouts';

const DEFAULT_MAP_SIZE = 255;
const DEFAULT_SCALE = 2.2;

export interface SubLevelObject {
  id: number;
  name: string;
  width: number;
  height: number;
  z: number;
  x_min: number;
  y_min: number;
  x_max: number;
  y_max: number;
  created_at: number;
}

export interface SubLevelsManagerData {
  sub_levels: SubLevelObject[];
  z_levels: Record<string, number>;
  total_roots: number;
  max_size: number;
}

function clamp(v: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, v));
}

function getColorForId(id: number): string {
  const hue = (id * 137.5) % 360;
  return `hsl(${hue}, 65%, 55%)`;
}

type CanvasFrameState = {
  subLevels: SubLevelObject[];
  selectedId: number | null;
  activeZ: number;
  scale: number;
  offsetX: number;
  offsetY: number;
  mapSize: number;
  canvasSize: { width: number; height: number };
};

// ─── 2D Canvas Map Component ──────────────────────────────────────────────────

type SubLevelsCanvasProps = {
  subLevels: SubLevelObject[];
  selectedId: number | null;
  activeZ: number;
  scale: number;
  offsetX: number;
  offsetY: number;
  mapSize: number;
  onSelect: (id: number) => void;
  onZoom: (newScale: number, newOffsetX: number, newOffsetY: number) => void;
  onPan: (newOffsetX: number, newOffsetY: number) => void;
};

export const SubLevelsCanvas = (props: SubLevelsCanvasProps) => {
  const { onSelect, onZoom, onPan } = props;
  const containerRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [canvasSize, setCanvasSize] = useState({ width: 600, height: 600 });
  const [isDragging, setIsDragging] = useState(false);
  const dragStartRef = useRef({ x: 0, y: 0, ox: 0, oy: 0 });

  const frameRef = useRef<CanvasFrameState>({
    subLevels: props.subLevels,
    selectedId: props.selectedId,
    activeZ: props.activeZ,
    scale: props.scale,
    offsetX: props.offsetX,
    offsetY: props.offsetY,
    mapSize: props.mapSize,
    canvasSize,
  });

  frameRef.current = {
    subLevels: props.subLevels,
    selectedId: props.selectedId,
    activeZ: props.activeZ,
    scale: props.scale,
    offsetX: props.offsetX,
    offsetY: props.offsetY,
    mapSize: props.mapSize,
    canvasSize,
  };

  useEffect(() => {
    const updateSize = () => {
      if (containerRef.current) {
        const { width, height } = containerRef.current.getBoundingClientRect();
        setCanvasSize({ width: Math.round(width), height: Math.round(height) });
      }
    };
    updateSize();
    window.addEventListener('resize', updateSize);
    return () => window.removeEventListener('resize', updateSize);
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (canvas) {
      canvas.width = canvasSize.width;
      canvas.height = canvasSize.height;
    }
  }, [canvasSize]);

  // Render Loop
  const drawMap = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const s = frameRef.current;
    const { scale, offsetX, offsetY, mapSize, activeZ, selectedId } = s;
    const W = canvas.width;
    const H = canvas.height;

    ctx.clearRect(0, 0, W, H);
    ctx.save();
    ctx.translate(offsetX, offsetY);
    ctx.scale(scale, scale);

    // Render Z-Level Border Boundary
    ctx.strokeStyle = 'rgba(100, 150, 255, 0.4)';
    ctx.lineWidth = 2 / scale;
    ctx.strokeRect(1, 1, mapSize, mapSize);

    // Spatial Grid Lines (Quadtree subdivisions helper: 32x32 tiles)
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
    ctx.lineWidth = 1 / scale;
    ctx.beginPath();
    for (let x = 32; x < mapSize; x += 32) {
      ctx.moveTo(x, 0);
      ctx.lineTo(x, mapSize);
    }
    for (let y = 32; y < mapSize; y += 32) {
      ctx.moveTo(0, y);
      ctx.lineTo(mapSize, y);
    }
    ctx.stroke();

    // Render Sub-Level Rectangles
    const zFilteredLevels = s.subLevels.filter((lvl) => lvl.z === activeZ);

    for (const lvl of zFilteredLevels) {
      const isSelected = lvl.id === selectedId;
      const baseColor = getColorForId(lvl.id);
      const w = lvl.x_max - lvl.x_min + 1;
      const h = lvl.y_max - lvl.y_min + 1;
      // Invert Y coordinate to match standard DM screen orientation
      const drawY = mapSize - lvl.y_max;

      // Fill area
      ctx.fillStyle = isSelected
        ? 'rgba(46, 204, 113, 0.35)'
        : 'rgba(52, 152, 219, 0.2)';
      ctx.fillRect(lvl.x_min, drawY, w, h);

      // Border outline
      ctx.strokeStyle = isSelected ? '#2ecc71' : baseColor;
      ctx.lineWidth = (isSelected ? 3 : 1.5) / scale;
      ctx.strokeRect(lvl.x_min, drawY, w, h);

      // Label text inside sub-level box
      if (scale > 0.8) {
        ctx.save();
        ctx.font = `${Math.max(10, 12 / scale)}px sans-serif`;
        ctx.fillStyle = '#ffffff';
        ctx.textBaseline = 'top';
        const labelText = `#${lvl.id} ${lvl.name}`;
        ctx.fillText(labelText, lvl.x_min + 2, drawY + 2);
        ctx.restore();
      }
    }

    ctx.restore();
  }, []);

  useEffect(() => {
    let raf = 0;
    const render = () => {
      drawMap();
      raf = requestAnimationFrame(render);
    };
    raf = requestAnimationFrame(render);
    return () => cancelAnimationFrame(raf);
  }, [drawMap]);

  const handleMouseDown = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (e.button !== 0) return;
    setIsDragging(true);
    dragStartRef.current = {
      x: e.clientX,
      y: e.clientY,
      ox: props.offsetX,
      oy: props.offsetY,
    };
  };

  const handleMouseMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!isDragging) return;
    const dx = e.clientX - dragStartRef.current.x;
    const dy = e.clientY - dragStartRef.current.y;
    onPan(dragStartRef.current.ox + dx, dragStartRef.current.oy + dy);
  };

  const handleMouseUp = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!isDragging) return;
    setIsDragging(false);

    // If mouse movement was negligible, treat as click selection
    const dx = Math.abs(e.clientX - dragStartRef.current.x);
    const dy = Math.abs(e.clientY - dragStartRef.current.y);
    if (dx < 5 && dy < 5 && canvasRef.current) {
      const rect = canvasRef.current.getBoundingClientRect();
      const clickX = e.clientX - rect.left;
      const clickY = e.clientY - rect.top;

      // Map canvas click back to DM world coordinates
      const worldX = Math.floor((clickX - props.offsetX) / props.scale);
      const invY = Math.floor((clickY - props.offsetY) / props.scale);
      const worldY = props.mapSize - invY;

      const hit = props.subLevels.find(
        (lvl) =>
          lvl.z === props.activeZ &&
          worldX >= lvl.x_min &&
          worldX <= lvl.x_max &&
          worldY >= lvl.y_min &&
          worldY <= lvl.y_max,
      );

      if (hit) {
        onSelect(hit.id);
      }
    }
  };

  const handleWheel = (e: React.WheelEvent<HTMLCanvasElement>) => {
    e.preventDefault();
    const canvas = canvasRef.current;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    const mouseX = e.clientX - rect.left;
    const mouseY = e.clientY - rect.top;

    const factor = e.deltaY > 0 ? 0.9 : 1.1;
    const newScale = clamp(props.scale * factor, 0.5, 10);
    const newOffsetX =
      mouseX - ((mouseX - props.offsetX) / props.scale) * newScale;
    const newOffsetY =
      mouseY - ((mouseY - props.offsetY) / props.scale) * newScale;

    onZoom(newScale, newOffsetX, newOffsetY);
  };

  return (
    <div
      ref={containerRef}
      style={{
        width: '100%',
        height: '100%',
        position: 'relative',
        overflow: 'hidden',
        background: 'linear-gradient(160deg, #121620 0%, #0a0c10 100%)',
        borderRadius: '6px',
        border: '1px solid rgba(255, 255, 255, 0.1)',
      }}
    >
      <canvas
        ref={canvasRef}
        style={{
          position: 'absolute',
          inset: 0,
          cursor: isDragging ? 'grabbing' : 'grab',
          touchAction: 'none',
        }}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={() => setIsDragging(false)}
        onWheel={handleWheel}
      />
    </div>
  );
};

export const SubLevelsManager = () => {
  const { act, data } = useBackend<SubLevelsManagerData>();
  const {
    sub_levels = [],
    z_levels = {},
    total_roots = 1,
    max_size = DEFAULT_MAP_SIZE,
  } = data;

  const availableZList = Object.values(z_levels);
  const [activeZ, setActiveZ] = useState<number>(
    availableZList.length > 0 ? availableZList[0] : 1,
  );

  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [scale, setScale] = useState(DEFAULT_SCALE);
  const [offsetX, setOffsetX] = useState(30);
  const [offsetY, setOffsetY] = useState(30);

  // Creation State
  const [newWidth, setNewWidth] = useState(32);
  const [newHeight, setNewHeight] = useState(32);
  const [newName, setNewName] = useState('');

  const selectedLevel = sub_levels.find((l) => l.id === selectedId);

  const handleCreate = () => {
    act('create', {
      width: newWidth,
      height: newHeight,
      name: newName,
    });
    setNewName('');
  };

  return (
    <Window title="Sub-Levels Spatial Manager" width={980} height={680}>
      <Window.Content style={{ padding: '8px' }}>
        <Stack fill>
          {/* LEFT: Interactive Canvas Viewport */}
          <Stack.Item grow={3} style={{ position: 'relative' }}>
            <Stack vertical fill>
              <Stack.Item grow>
                <SubLevelsCanvas
                  subLevels={sub_levels}
                  selectedId={selectedId}
                  activeZ={activeZ}
                  scale={scale}
                  offsetX={offsetX}
                  offsetY={offsetY}
                  mapSize={max_size}
                  onSelect={(id) => setSelectedId(id)}
                  onZoom={(s, ox, oy) => {
                    setScale(s);
                    setOffsetX(ox);
                    setOffsetY(oy);
                  }}
                  onPan={(ox, oy) => {
                    setOffsetX(ox);
                    setOffsetY(oy);
                  }}
                />
              </Stack.Item>

              {/* Canvas Navigation Toolbar */}
              <Stack.Item>
                <Section p={1}>
                  <Stack align="center" justify="space-between">
                    <Stack.Item>
                      <Stack align="center">
                        <Box color="label" bold>
                          Z-Level:
                        </Box>
                        <Dropdown
                          options={availableZList.map((z) => `Z-${z}`)}
                          selected={`Z-${activeZ}`}
                          onSelected={(val) => {
                            const num = parseInt(val.replace('Z-', ''), 10);
                            if (num) setActiveZ(num);
                          }}
                        />
                      </Stack>
                    </Stack.Item>

                    <Stack.Item>
                      <Stack>
                        <Button
                          icon="magnifying-glass-minus"
                          onClick={() =>
                            setScale((s) => clamp(s * 0.8, 0.5, 10))
                          }
                        />
                        <Button
                          icon="crosshairs"
                          onClick={() => {
                            setScale(DEFAULT_SCALE);
                            setOffsetX(30);
                            setOffsetY(30);
                          }}
                        >
                          Сброс вида
                        </Button>
                        <Button
                          icon="magnifying-glass-plus"
                          onClick={() =>
                            setScale((s) => clamp(s * 1.2, 0.5, 10))
                          }
                        />
                      </Stack>
                    </Stack.Item>
                  </Stack>
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>

          {/* RIGHT: Control Inspector Side Panel */}
          <Stack.Item grow={2} style={{ minWidth: '360px', maxWidth: '400px' }}>
            <Stack vertical fill>
              {/* Creator Section */}
              <Stack.Item>
                <Section title="Создать подуровень">
                  <LabeledList>
                    <LabeledList.Item label="Название">
                      <Input
                        fluid
                        value={newName}
                        placeholder="Напр. Arena Chunk"
                        onChange={(val) => setNewName(val)}
                      />
                    </LabeledList.Item>
                    <LabeledList.Item label="Ширина (X)">
                      <NumberInput
                        fluid
                        value={newWidth}
                        minValue={8}
                        maxValue={255}
                        step={8}
                        onChange={(val) => setNewWidth(val)}
                      />
                    </LabeledList.Item>
                    <LabeledList.Item label="Высота (Y)">
                      <NumberInput
                        fluid
                        value={newHeight}
                        minValue={8}
                        maxValue={255}
                        step={8}
                        onChange={(val) => setNewHeight(val)}
                      />
                    </LabeledList.Item>
                  </LabeledList>
                  <Button
                    icon="layer-group"
                    content="Выделить пространство"
                    color="green"
                    fluid
                    mt={1.5}
                    onClick={handleCreate}
                  />
                </Section>
              </Stack.Item>

              {/* Selected Sub-level Inspector */}
              <Stack.Item>
                <Section
                  title={
                    selectedLevel
                      ? `Инспектор: #${selectedLevel.id} ${selectedLevel.name}`
                      : 'Инспектор'
                  }
                >
                  {selectedLevel ? (
                    <>
                      <LabeledList>
                        <LabeledList.Item label="Размерность">
                          {selectedLevel.width} x {selectedLevel.height}
                        </LabeledList.Item>
                        <LabeledList.Item label="Z-Уровень">
                          Z-{selectedLevel.z}
                        </LabeledList.Item>
                        <LabeledList.Item label="Координаты X">
                          [{selectedLevel.x_min} .. {selectedLevel.x_max}]
                        </LabeledList.Item>
                        <LabeledList.Item label="Координаты Y">
                          [{selectedLevel.y_min} .. {selectedLevel.y_max}]
                        </LabeledList.Item>
                      </LabeledList>

                      <Divider />

                      <Stack wrap>
                        <Button
                          icon="arrow-right-to-bracket"
                          color="blue"
                          onClick={() => act('jump', { id: selectedLevel.id })}
                        >
                          Прыжок
                        </Button>
                        <Button
                          icon="border-all"
                          color="orange"
                          onClick={() =>
                            act('rebuild_cordon', { id: selectedLevel.id })
                          }
                        >
                          Кордон
                        </Button>
                        <Button
                          icon="broom"
                          color="yellow"
                          onClick={() => act('clear', { id: selectedLevel.id })}
                        >
                          Очистить
                        </Button>
                        <Button
                          icon="trash"
                          color="red"
                          onClick={() => {
                            act('delete', { id: selectedLevel.id });
                            setSelectedId(null);
                          }}
                        >
                          Удалить
                        </Button>
                      </Stack>
                    </>
                  ) : (
                    <Box italic color="label" textAlign="center" p={2}>
                      Выберите подуровень на карте или в таблице ниже для
                      управления
                    </Box>
                  )}
                </Section>
              </Stack.Item>

              {/* All Sub-levels List Table */}
              <Stack.Item grow style={{ overflowY: 'auto' }}>
                <Section
                  title={`Список подуровней (${sub_levels.length})`}
                  fill
                >
                  <Table>
                    <Table.Row header>
                      <Table.Cell>ID</Table.Cell>
                      <Table.Cell>Имя</Table.Cell>
                      <Table.Cell>Размер</Table.Cell>
                      <Table.Cell align="right">Z</Table.Cell>
                    </Table.Row>
                    {sub_levels.map((lvl) => (
                      <Table.Row
                        key={lvl.id}
                        onClick={() => {
                          setSelectedId(lvl.id);
                          setActiveZ(lvl.z);
                        }}
                        className={
                          lvl.id === selectedId ? 'Table__row--selected' : ''
                        }
                        style={{ cursor: 'pointer' }}
                      >
                        <Table.Cell bold color="label">
                          #{lvl.id}
                        </Table.Cell>
                        <Table.Cell>{lvl.name}</Table.Cell>
                        <Table.Cell>
                          {lvl.width}x{lvl.height}
                        </Table.Cell>
                        <Table.Cell align="right">{lvl.z}</Table.Cell>
                      </Table.Row>
                    ))}
                  </Table>
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
