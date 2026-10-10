import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  Box,
  Button,
  LabeledList,
  NumberInput,
  Section,
  Stack,
} from 'tgui-core/components';
import { useBackend } from '../../backend';
import { Window } from '../../layouts';

type TileCell = {
  x: number;
  y: number;
  exists: boolean;
  is_boundary: number;
  area_id: number;
  kind: number;
  is_zone: boolean;
};

type ZoneEntry = {
  key: string;
  name: string;
  rust_area_id: number;
  color: string;
  size: number;
};

type Selection = {
  x: number;
  y: number;
  info: Record<string, number> | null;
  bounds: Record<string, number> | null;
  dm_area: string;
  dm_area_type: string;
  turf_type: string;
};

type ZoneGridData = {
  z: number;
  origin_x: number;
  origin_y: number;
  grid_size: number;
  selected_x: number;
  selected_y: number;
  static_rev: number;
  initialised: boolean;
  selection: Selection | null;
  // static
  stats: Record<string, number> | null;
  rows: TileCell[][];
  zones: ZoneEntry[];
};

const KIND_LABEL: Record<number, string> = {
  0: 'other',
  1: 'floor',
  2: 'wall',
  3: 'door',
  4: 'window',
};

function colorForCell(cell: TileCell): string {
  if (cell.is_boundary) return '#2a2a2a';
  if (!cell.area_id) return '#111111';
  if (cell.is_zone) {
    const hue = (cell.area_id * 57) % 360;
    return `hsl(${hue}, 70%, 42%)`;
  }
  const hue = (cell.area_id * 37) % 360;
  return `hsl(${hue}, 35%, 28%)`;
}

function clamp(v: number, lo: number, hi: number) {
  return Math.max(lo, Math.min(hi, v));
}

export const ZoneGridInspector = () => {
  const { act, data } = useBackend<ZoneGridData>();
  const {
    z,
    origin_x,
    origin_y,
    grid_size,
    selected_x,
    selected_y,
    static_rev,
    initialised,
    selection,
    stats,
    rows = [],
    zones = [],
  } = data;

  // Local camera (does not hit BYOND until Refresh)
  const [scale, setScale] = useState(1);
  const [panX, setPanX] = useState(0);
  const [panY, setPanY] = useState(0);
  const [dragging, setDragging] = useState(false);
  const dragRef = useRef({ x: 0, y: 0, px: 0, py: 0, moved: false });

  const containerRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [viewSize, setViewSize] = useState({ w: 520, h: 520 });

  // Flat lookup for click hit-testing
  const cellMap = useMemo(() => {
    const m = new Map<string, TileCell>();
    for (const row of rows) {
      for (const cell of row) {
        m.set(`${cell.x},${cell.y}`, cell);
      }
    }
    return m;
  }, [rows, static_rev]);

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const ro = new ResizeObserver(() => {
      const r = el.getBoundingClientRect();
      setViewSize({ w: Math.round(r.width), h: Math.round(r.height) });
    });
    ro.observe(el);
    const r = el.getBoundingClientRect();
    setViewSize({ w: Math.round(r.width), h: Math.round(r.height) });
    return () => ro.disconnect();
  }, []);

  const baseCell = useMemo(() => {
    if (grid_size <= 0) return 12;
    return Math.max(
      4,
      Math.floor(Math.min(viewSize.w, viewSize.h) / grid_size),
    );
  }, [grid_size, viewSize]);

  const cellPx = baseCell * scale;

  // Draw
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    canvas.width = viewSize.w;
    canvas.height = viewSize.h;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.save();
    ctx.translate(panX, panY);

    for (const row of rows) {
      for (const cell of row) {
        const lx = cell.x - origin_x;
        const ly = origin_y + grid_size - 1 - cell.y; // rows are top=max y
        const px = lx * cellPx;
        const py = ly * cellPx;
        ctx.fillStyle = colorForCell(cell);
        ctx.globalAlpha = cell.exists ? 1 : 0.25;
        ctx.fillRect(px, py, cellPx + 0.5, cellPx + 0.5);

        if (cell.x === selected_x && cell.y === selected_y) {
          ctx.globalAlpha = 1;
          ctx.strokeStyle = '#ffffff';
          ctx.lineWidth = Math.max(1, 2 * scale);
          ctx.strokeRect(px + 0.5, py + 0.5, cellPx - 1, cellPx - 1);
        } else if (cell.is_zone && !cell.is_boundary) {
          ctx.globalAlpha = 0.5;
          ctx.strokeStyle = 'rgba(255,255,255,0.35)';
          ctx.lineWidth = 1;
          ctx.strokeRect(px + 0.5, py + 0.5, cellPx - 1, cellPx - 1);
        }
      }
    }

    // Grid outline
    ctx.globalAlpha = 0.4;
    ctx.strokeStyle = 'rgba(100,150,255,0.5)';
    ctx.lineWidth = 1;
    ctx.strokeRect(0, 0, grid_size * cellPx, grid_size * cellPx);

    ctx.restore();
  }, [
    rows,
    static_rev,
    origin_x,
    origin_y,
    grid_size,
    cellPx,
    panX,
    panY,
    selected_x,
    selected_y,
    scale,
    viewSize,
  ]);

  const screenToWorld = useCallback(
    (clientX: number, clientY: number) => {
      const canvas = canvasRef.current;
      if (!canvas) return null;
      const rect = canvas.getBoundingClientRect();
      const sx = clientX - rect.left - panX;
      const sy = clientY - rect.top - panY;
      const lx = Math.floor(sx / cellPx);
      const ly = Math.floor(sy / cellPx);
      if (lx < 0 || ly < 0 || lx >= grid_size || ly >= grid_size) return null;
      const wx = origin_x + lx;
      const wy = origin_y + grid_size - 1 - ly;
      return { x: wx, y: wy };
    },
    [panX, panY, cellPx, grid_size, origin_x, origin_y],
  );

  const onMouseDown = (e: React.MouseEvent) => {
    if (e.button !== 0) return;
    setDragging(true);
    dragRef.current = {
      x: e.clientX,
      y: e.clientY,
      px: panX,
      py: panY,
      moved: false,
    };
  };

  const onMouseMove = (e: React.MouseEvent) => {
    if (!dragging) return;
    const dx = e.clientX - dragRef.current.x;
    const dy = e.clientY - dragRef.current.y;
    if (Math.abs(dx) > 3 || Math.abs(dy) > 3) {
      dragRef.current.moved = true;
    }
    setPanX(dragRef.current.px + dx);
    setPanY(dragRef.current.py + dy);
  };

  const onMouseUp = (e: React.MouseEvent) => {
    if (!dragging) return;
    setDragging(false);
    if (!dragRef.current.moved) {
      const world = screenToWorld(e.clientX, e.clientY);
      if (world) {
        act('select', { x: world.x, y: world.y });
      }
    }
  };

  const onDoubleClick = (e: React.MouseEvent) => {
    const world = screenToWorld(e.clientX, e.clientY);
    if (world) {
      act('jump', { x: world.x, y: world.y });
    }
  };

  const onWheel = (e: React.WheelEvent) => {
    e.preventDefault();
    const canvas = canvasRef.current;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;
    const factor = e.deltaY > 0 ? 0.9 : 1.1;
    const next = clamp(scale * factor, 0.25, 6);
    // Zoom toward cursor
    const ratio = next / scale;
    setPanX(mx - (mx - panX) * ratio);
    setPanY(my - (my - panY) * ratio);
    setScale(next);
  };

  const doRefresh = () => {
    act('refresh', { x: origin_x, y: origin_y, size: grid_size });
  };

  return (
    <Window title="Zone Grid Inspector" width={960} height={720}>
      <Window.Content>
        <Stack fill>
          <Stack.Item grow>
            <Section
              fill
              title={`Z=${z}  origin=(${origin_x},${origin_y})  ${grid_size}×${grid_size}  scale=${scale.toFixed(2)}`}
              buttons={
                <>
                  <Button icon="sync" color="good" onClick={doRefresh}>
                    Refresh grid
                  </Button>
                  <Button icon="crosshairs" onClick={() => act('center_on_me')}>
                    Center on me
                  </Button>
                  <Button icon="rotate" onClick={() => act('resync')}>
                    Resync zones
                  </Button>
                  <Button
                    icon="hammer"
                    color="orange"
                    onClick={() => act('rebuild_rust')}
                  >
                    Rebuild Rust
                  </Button>
                </>
              }
            >
              {!initialised && (
                <Box color="bad" mb={1}>
                  Z not initialised in SSarea_rust
                </Box>
              )}
              <div
                ref={containerRef}
                style={{
                  width: '100%',
                  height: 'calc(100% - 8px)',
                  minHeight: 480,
                  position: 'relative',
                  overflow: 'hidden',
                  background: 'linear-gradient(160deg,#121620,#0a0c10)',
                  borderRadius: 6,
                  border: '1px solid rgba(255,255,255,0.1)',
                }}
              >
                <canvas
                  ref={canvasRef}
                  style={{
                    position: 'absolute',
                    inset: 0,
                    cursor: dragging ? 'grabbing' : 'grab',
                    touchAction: 'none',
                  }}
                  onMouseDown={onMouseDown}
                  onMouseMove={onMouseMove}
                  onMouseUp={onMouseUp}
                  onMouseLeave={() => setDragging(false)}
                  onDoubleClick={onDoubleClick}
                  onWheel={onWheel}
                />
              </div>
              <Box mt={0.5} color="label" fontSize="11px">
                Drag to pan · Wheel to zoom · Click select · Double-click jump ·
                Refresh reloads Rust snapshot
              </Box>
            </Section>
          </Stack.Item>

          <Stack.Item style={{ width: 300 }}>
            <Stack vertical fill>
              <Stack.Item>
                <Section title="Camera (local until Refresh)">
                  <LabeledList>
                    <LabeledList.Item label="Grid size">
                      <NumberInput
                        value={grid_size}
                        minValue={8}
                        maxValue={64}
                        step={4}
                        onChange={(v) => act('set_size', { size: v })}
                      />
                    </LabeledList.Item>
                    <LabeledList.Item label="Origin X">
                      <NumberInput
                        value={origin_x}
                        minValue={1}
                        maxValue={512}
                        step={1}
                        onChange={(v) => act('pan', { x: v, y: origin_y })}
                      />
                    </LabeledList.Item>
                    <LabeledList.Item label="Origin Y">
                      <NumberInput
                        value={origin_y}
                        minValue={1}
                        maxValue={512}
                        step={1}
                        onChange={(v) => act('pan', { x: origin_x, y: v })}
                      />
                    </LabeledList.Item>
                  </LabeledList>
                  <Button fluid mt={1} icon="sync" onClick={doRefresh}>
                    Apply origin / size &amp; Refresh
                  </Button>
                  {stats && (
                    <Box mt={1} fontSize="11px" color="label">
                      areas={String(stats.areas_count)} open=
                      {String(stats.open_tiles)} boundary=
                      {String(stats.boundary_tiles)} map={String(stats.width)}×
                      {String(stats.height)}
                    </Box>
                  )}
                </Section>
              </Stack.Item>

              <Stack.Item>
                <Section title="Selection">
                  {selection ? (
                    <LabeledList>
                      <LabeledList.Item label="Pos">
                        ({selection.x}, {selection.y}, {z})
                      </LabeledList.Item>
                      <LabeledList.Item label="Turf">
                        {selection.turf_type}
                      </LabeledList.Item>
                      <LabeledList.Item label="DM area">
                        {selection.dm_area}
                      </LabeledList.Item>
                      <LabeledList.Item label="DM type">
                        <Box fontSize="10px">{selection.dm_area_type}</Box>
                      </LabeledList.Item>
                      {selection.info && (
                        <>
                          <LabeledList.Item label="Boundary">
                            {selection.info.is_boundary ? 'YES' : 'no'}
                          </LabeledList.Item>
                          <LabeledList.Item label="area_id">
                            {selection.info.area_id}
                          </LabeledList.Item>
                          <LabeledList.Item label="Kind">
                            {KIND_LABEL[selection.info.kind] ??
                              selection.info.kind}
                          </LabeledList.Item>
                        </>
                      )}
                      {selection.bounds && (
                        <LabeledList.Item label="Bounds">
                          size={selection.bounds.size}
                        </LabeledList.Item>
                      )}
                    </LabeledList>
                  ) : (
                    <Box italic color="label">
                      Click a tile
                    </Box>
                  )}
                </Section>
              </Stack.Item>

              <Stack.Item grow style={{ overflowY: 'auto' }}>
                <Section title={`Zones (${zones.length})`} fill>
                  {zones.length === 0 ? (
                    <Box italic color="label">
                      No zones — Refresh after building walls
                    </Box>
                  ) : (
                    zones.map((ze) => (
                      <Box
                        key={ze.key}
                        mb={0.5}
                        p={0.5}
                        style={{
                          borderLeft: `4px solid ${ze.color}`,
                          background: 'rgba(255,255,255,0.04)',
                        }}
                      >
                        <Box bold fontSize="12px">
                          {ze.name}
                        </Box>
                        <Box color="label" fontSize="11px">
                          id={ze.rust_area_id} size={ze.size}
                        </Box>
                      </Box>
                    ))
                  )}
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
