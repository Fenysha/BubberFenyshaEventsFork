import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  Box,
  Button,
  LabeledList,
  NumberInput,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { useBackend } from '../../backend';
import { Window } from '../../layouts';

type GridCell = {
  x: number;
  y: number;
  has_node: boolean;
  net_id: number;
};

type NetEntry = {
  id: number;
  supply: number;
  demand: number;
  stored: number;
  capacity: number;
  producers: number;
  stores: number;
  connectors: number;
  members: number;
};

type NodeInfo = {
  id: number;
  net_id: number;
  type: number;
  name: string;
  path: string;
  consumers: number;
};

type Selection = {
  x: number;
  y: number;
  turf: string;
  nodes: NodeInfo[];
};

type ObjectNetData = {
  z: number;
  origin_x: number;
  origin_y: number;
  grid_size: number;
  selected_x: number;
  selected_y: number;
  static_rev: number;
  net_type: number;
  nets: NetEntry[];
  selection: Selection | null;
  stats: Record<string, number> | null;
  ss_nets: number;
  ss_active: number;
  ss_pending: number;
  // static
  rows: GridCell[][];
};

const NET_TYPE_LABEL: Record<number, string> = {
  0: 'Power',
  1: 'Fluid',
  2: 'Atmos',
  3: 'Data',
};

function colorForCell(cell: GridCell): string {
  if (!cell.has_node) return '#0d0f14';
  if (!cell.net_id) return '#3a2a1a';
  const hue = (cell.net_id * 47) % 360;
  return `hsl(${hue}, 65%, 38%)`;
}

function clamp(v: number, lo: number, hi: number) {
  return Math.max(lo, Math.min(hi, v));
}

function fmt(n: number, digits = 0) {
  if (n >= 1e6) return `${(n / 1e6).toFixed(1)}M`;
  if (n >= 1e3) return `${(n / 1e3).toFixed(1)}k`;
  return n.toFixed(digits);
}

export const ObjectNetMonitor = () => {
  const { act, data } = useBackend<ObjectNetData>();
  const {
    z,
    origin_x,
    origin_y,
    grid_size,
    selected_x,
    selected_y,
    static_rev,
    net_type,
    nets = [],
    selection,
    stats,
    ss_nets,
    ss_active,
    ss_pending,
    rows = [],
  } = data;

  const [scale, setScale] = useState(1);
  const [panX, setPanX] = useState(0);
  const [panY, setPanY] = useState(0);
  const [dragging, setDragging] = useState(false);
  const dragRef = useRef({ x: 0, y: 0, px: 0, py: 0, moved: false });
  const containerRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [viewSize, setViewSize] = useState({ w: 480, h: 480 });

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
    if (grid_size <= 0) return 10;
    return Math.max(3, Math.floor(Math.min(viewSize.w, viewSize.h) / grid_size));
  }, [grid_size, viewSize]);
  const cellPx = baseCell * scale;

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
        const ly = origin_y + grid_size - 1 - cell.y;
        const px = lx * cellPx;
        const py = ly * cellPx;
        ctx.fillStyle = colorForCell(cell);
        ctx.globalAlpha = cell.has_node ? 1 : 0.35;
        ctx.fillRect(px, py, cellPx + 0.5, cellPx + 0.5);
        if (cell.x === selected_x && cell.y === selected_y) {
          ctx.globalAlpha = 1;
          ctx.strokeStyle = '#ffffff';
          ctx.lineWidth = Math.max(1, 2 * scale);
          ctx.strokeRect(px + 0.5, py + 0.5, cellPx - 1, cellPx - 1);
        }
      }
    }
    ctx.globalAlpha = 0.4;
    ctx.strokeStyle = 'rgba(100,160,255,0.5)';
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
      return { x: origin_x + lx, y: origin_y + grid_size - 1 - ly };
    },
    [panX, panY, cellPx, grid_size, origin_x, origin_y],
  );

  const onMouseDown = (e: React.MouseEvent) => {
    if (e.button !== 0) return;
    setDragging(true);
    dragRef.current = { x: e.clientX, y: e.clientY, px: panX, py: panY, moved: false };
  };
  const onMouseMove = (e: React.MouseEvent) => {
    if (!dragging) return;
    const dx = e.clientX - dragRef.current.x;
    const dy = e.clientY - dragRef.current.y;
    if (Math.abs(dx) > 3 || Math.abs(dy) > 3) dragRef.current.moved = true;
    setPanX(dragRef.current.px + dx);
    setPanY(dragRef.current.py + dy);
  };
  const onMouseUp = (e: React.MouseEvent) => {
    if (!dragging) return;
    setDragging(false);
    if (!dragRef.current.moved) {
      const world = screenToWorld(e.clientX, e.clientY);
      if (world) act('select', { x: world.x, y: world.y });
    }
  };
  const onDoubleClick = (e: React.MouseEvent) => {
    const world = screenToWorld(e.clientX, e.clientY);
    if (world) act('jump', { x: world.x, y: world.y });
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
    const ratio = next / scale;
    setPanX(mx - (mx - panX) * ratio);
    setPanY(my - (my - panY) * ratio);
    setScale(next);
  };

  const doRefresh = () => {
    act('refresh', { x: origin_x, y: origin_y, size: grid_size });
  };

  return (
    <Window title="ObjectNet Monitor" width={1100} height={760}>
      <Window.Content>
        <Stack fill>
          {/* Left: grid */}
          <Stack.Item grow>
            <Section
              fill
              title={`Z=${z}  ${NET_TYPE_LABEL[net_type] ?? net_type}  origin=(${origin_x},${origin_y})  ${grid_size}×${grid_size}`}
              buttons={
                <>
                  <Button icon="sync" color="good" onClick={doRefresh}>
                    Refresh grid
                  </Button>
                  <Button icon="crosshairs" onClick={() => act('center_on_me')}>
                    Center on me
                  </Button>
                  <Button icon="bolt" onClick={() => act('set_net_type', { type: 0 })}>
                    Power
                  </Button>
                  <Button icon="tint" onClick={() => act('set_net_type', { type: 1 })}>
                    Fluid
                  </Button>
                  <Button
                    icon="trash"
                    color="bad"
                    onClick={() => act('reset_rust')}
                  >
                    Reset Rust
                  </Button>
                </>
              }
            >
              <div
                ref={containerRef}
                style={{
                  width: '100%',
                  height: 'calc(100% - 8px)',
                  minHeight: 460,
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
                Drag pan · Wheel zoom · Click select · Double-click jump · Colour
                = net id
              </Box>
            </Section>
          </Stack.Item>

          {/* Right panel */}
          <Stack.Item style={{ width: 340 }}>
            <Stack vertical fill>
              {/* Camera + SS stats */}
              <Stack.Item>
                <Section title="Camera / Subsystem">
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
                    Apply &amp; Refresh
                  </Button>
                  <Box mt={1} fontSize="11px" color="label">
                    SS nets={ss_nets} active={ss_active} pending={ss_pending}
                    {stats && (
                      <>
                        {' '}
                        · Rust nodes={String(stats.nodes ?? '?')} nets=
                        {String(stats.nets ?? '?')}
                      </>
                    )}
                  </Box>
                </Section>
              </Stack.Item>

              {/* Selection */}
              <Stack.Item>
                <Section title="Selection">
                  {selection ? (
                    <LabeledList>
                      <LabeledList.Item label="Pos">
                        ({selection.x}, {selection.y}, {z})
                      </LabeledList.Item>
                      <LabeledList.Item label="Turf">
                        {selection.turf}
                      </LabeledList.Item>
                      {selection.nodes.length === 0 ? (
                        <LabeledList.Item label="Nodes">none</LabeledList.Item>
                      ) : (
                        selection.nodes.map((n) => (
                          <Box key={n.id} mt={0.5} p={0.5} style={{ background: 'rgba(255,255,255,0.04)' }}>
                            <Box bold fontSize="12px">
                              #{n.id} {n.name}
                            </Box>
                            <Box color="label" fontSize="11px">
                              net={n.net_id} type={n.type} consumers={n.consumers}
                            </Box>
                            <Box color="label" fontSize="10px">
                              {n.path}
                            </Box>
                          </Box>
                        ))
                      )}
                    </LabeledList>
                  ) : (
                    <Box italic color="label">
                      Click a tile
                    </Box>
                  )}
                </Section>
              </Stack.Item>

              {/* Live nets table */}
              <Stack.Item grow style={{ overflowY: 'auto' }}>
                <Section title={`Nets (${nets.length})`} fill>
                  {nets.length === 0 ? (
                    <Box italic color="label">
                      No nets — place cables / producers
                    </Box>
                  ) : (
                    <Table>
                      <Table.Row header>
                        <Table.Cell>ID</Table.Cell>
                        <Table.Cell>Supply</Table.Cell>
                        <Table.Cell>Demand</Table.Cell>
                        <Table.Cell>Stored</Table.Cell>
                        <Table.Cell>N</Table.Cell>
                      </Table.Row>
                      {nets.map((n) => (
                        <Table.Row key={n.id}>
                          <Table.Cell>{n.id}</Table.Cell>
                          <Table.Cell>{fmt(n.supply)}</Table.Cell>
                          <Table.Cell>{fmt(n.demand)}</Table.Cell>
                          <Table.Cell>
                            {fmt(n.stored)}/{fmt(n.capacity)}
                          </Table.Cell>
                          <Table.Cell>
                            {n.members}
                            <Box as="span" color="label" fontSize="10px">
                              {' '}
                              (P{n.producers} S{n.stores} C{n.connectors})
                            </Box>
                          </Table.Cell>
                        </Table.Row>
                      ))}
                    </Table>
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
