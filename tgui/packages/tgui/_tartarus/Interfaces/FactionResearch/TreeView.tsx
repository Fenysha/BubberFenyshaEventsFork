import { useCallback, useMemo, useRef, useState } from 'react';
import { Box, Button, Icon, Tooltip } from 'tgui-core/components';

import {
  ERA_COLORS,
  ERA_COLORS_DIM,
  ERA_COLORS_GLOW,
  STATUS_BG,
  STATUS_BORDER,
  STATUS_COLOR,
  STATUS_ICON,
  type Status,
  TECH_ERAS,
} from './constants';
import type { NodeEntry } from './types';

type Props = {
  nodes: NodeEntry[];
  researched: Set<string>;
  current: string | null;
  queue: Set<string>;
  selectedId: string | null;
  progress?: Record<string, number>;
  onSelect: (id: string) => void;
  adminView?: boolean;
};

const NODE_W = 178;
const NODE_H = 52;
const H_GAP = 64;
const V_GAP = 56;
const HEADER_H = 42;
const COL_PAD = 12;

const MIN_ZOOM = 0.35;
const MAX_ZOOM = 2.2;
const ZOOM_STEP = 0.1;

const statusOf = (
  node: NodeEntry,
  researched: Set<string>,
  current: string | null,
  queue: Set<string>,
): Status => {
  if (researched.has(node.id)) return 'researched';
  if (node.id === current) return 'current';
  if (queue.has(node.id)) return 'queued';
  const prereqs = Array.isArray(node.prereqs) ? node.prereqs : [];
  if (prereqs.every((p) => researched.has(p))) return 'available';
  return 'locked';
};

const orthoPath = (x1: number, y1: number, x2: number, y2: number): string => {
  const midX = x1 + (x2 - x1) * 0.5;
  if (Math.abs(x2 - x1) < 4) {
    const midY = y1 + (y2 - y1) * 0.5;
    return `M ${x1} ${y1} L ${x1} ${midY} L ${x2} ${midY} L ${x2} ${y2}`;
  }
  return `M ${x1} ${y1} L ${midX} ${y1} L ${midX} ${y2} L ${x2} ${y2}`;
};

export const TreeView = (props: Props) => {
  const {
    nodes,
    researched,
    current,
    queue,
    selectedId,
    progress = {},
    onSelect,
    adminView = false,
  } = props;

  const [offset, setOffset] = useState({ x: 28, y: 20 });
  const [zoom, setZoom] = useState(1);
  const [dragging, setDragging] = useState(false);
  const dragStart = useRef({ x: 0, y: 0, ox: 0, oy: 0 });

  const onMouseDown = (e: React.MouseEvent) => {
    if (e.button !== 0) return;
    if ((e.target as HTMLElement).closest('button')) return;
    setDragging(true);
    dragStart.current = {
      x: e.clientX,
      y: e.clientY,
      ox: offset.x,
      oy: offset.y,
    };
  };

  const onMouseMove = useCallback(
    (e: React.MouseEvent) => {
      if (!dragging) return;
      setOffset({
        x: dragStart.current.ox + (e.clientX - dragStart.current.x),
        y: dragStart.current.oy + (e.clientY - dragStart.current.y),
      });
    },
    [dragging],
  );

  const onMouseUp = () => setDragging(false);

  const onWheel = (e: React.WheelEvent) => {
    e.preventDefault();
    const delta = e.deltaY > 0 ? -ZOOM_STEP : ZOOM_STEP;
    setZoom((z) => Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, z + delta)));
  };

  const colWidth = NODE_W + H_GAP;

  const positions = useMemo(() => {
    const map = new Map<string, { x: number; y: number }>();
    for (const node of nodes) {
      map.set(node.id, {
        x: node.ui_x ?? 0,
        y: node.ui_y ?? 0,
      });
    }
    return map;
  }, [nodes]);

  const byId = useMemo(() => new Map(nodes.map((n) => [n.id, n])), [nodes]);

  const activeEras = useMemo(() => {
    const present = new Set(nodes.map((n) => n.era));
    return TECH_ERAS.filter((e) => present.has(e.id));
  }, [nodes]);

  const maxY = useMemo(() => {
    let m = 0;
    for (const p of positions.values()) {
      m = Math.max(m, p.y);
    }
    return m;
  }, [positions]);

  const treeHeight = HEADER_H + (maxY + 1) * (NODE_H + V_GAP) + 48;
  const treeWidth = Math.max(activeEras.length, 1) * colWidth + 48;

  const links = useMemo(() => {
    const result: {
      id: string;
      path: string;
      color: string;
      opacity: number;
    }[] = [];

    for (const node of nodes) {
      const prereqs = Array.isArray(node.prereqs) ? node.prereqs : [];
      const child = positions.get(node.id);
      if (!child) continue;

      const childStatus = statusOf(node, researched, current, queue);

      for (const prereq of prereqs) {
        const parent = positions.get(prereq);
        if (!parent) continue;

        const x1 = parent.x * colWidth + NODE_W / 2;
        const y1 = HEADER_H + parent.y * (NODE_H + V_GAP) + NODE_H;
        const x2 = child.x * colWidth + NODE_W / 2;
        const y2 = HEADER_H + child.y * (NODE_H + V_GAP);

        const parentNode = byId.get(prereq);
        const baseColor =
          ERA_COLORS[parentNode?.era ?? ''] || 'rgba(160,160,160,0.7)';

        let opacity = 0.35;
        if (researched.has(prereq) && researched.has(node.id)) {
          opacity = 0.85;
        } else if (researched.has(prereq)) {
          opacity = 0.65;
        } else if (childStatus === 'current' || childStatus === 'queued') {
          opacity = 0.55;
        }

        result.push({
          id: `${prereq}->${node.id}`,
          path: orthoPath(x1, y1, x2, y2),
          color: baseColor,
          opacity,
        });
      }
    }
    return result;
  }, [nodes, positions, byId, colWidth, researched, current, queue]);

  return (
    <Box
      height="100%"
      style={{
        overflow: 'hidden',
        position: 'relative',
        background:
          'linear-gradient(160deg, rgba(12,14,20,0.92) 0%, rgba(18,22,32,0.95) 50%, rgba(10,12,18,0.9) 100%)',
        border: '1px solid rgba(255, 255, 255, 0.08)',
        borderRadius: '6px',
        cursor: dragging ? 'grabbing' : 'grab',
        userSelect: 'none',
        minHeight: '340px',
        boxShadow: 'inset 0 0 40px rgba(0,0,0,0.35)',
      }}
      onMouseDown={onMouseDown}
      onMouseMove={onMouseMove}
      onMouseUp={onMouseUp}
      onMouseLeave={onMouseUp}
      onWheel={onWheel}
    >
      {/* subtle grid */}
      <Box
        style={{
          position: 'absolute',
          inset: 0,
          backgroundImage:
            'linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px)',
          backgroundSize: '28px 28px',
          pointerEvents: 'none',
          opacity: 0.6,
        }}
      />

      {/* zoom controls */}
      <Box
        style={{
          position: 'absolute',
          right: 10,
          top: 10,
          zIndex: 5,
          display: 'flex',
          gap: 4,
          background: 'rgba(0,0,0,0.55)',
          padding: '4px 6px',
          borderRadius: '4px',
          border: '1px solid rgba(255,255,255,0.1)',
        }}
      >
        <Button
          icon="search-minus"
          compact
          onClick={() => setZoom((z) => Math.max(MIN_ZOOM, z - ZOOM_STEP))}
        />
        <Button compact onClick={() => setZoom(1)}>
          {Math.round(zoom * 100)}%
        </Button>
        <Button
          icon="search-plus"
          compact
          onClick={() => setZoom((z) => Math.min(MAX_ZOOM, z + ZOOM_STEP))}
        />
        <Button
          icon="home"
          compact
          tooltip="Reset view"
          onClick={() => {
            setOffset({ x: 28, y: 20 });
            setZoom(1);
          }}
        />
      </Box>

      {adminView && (
        <Box
          style={{
            position: 'absolute',
            left: 10,
            top: 10,
            zIndex: 5,
            background: 'rgba(155, 89, 182, 0.25)',
            border: '1px solid rgba(155, 89, 182, 0.55)',
            color: '#d2a8ff',
            padding: '3px 10px',
            borderRadius: '4px',
            fontSize: '11px',
            fontWeight: 'bold',
            letterSpacing: '0.04em',
            textTransform: 'uppercase',
          }}
        >
          <Icon name="shield-halved" mr={1} />
          Admin view
        </Box>
      )}

      <Box
        style={{
          position: 'absolute',
          transform: `translate(${offset.x}px, ${offset.y}px) scale(${zoom})`,
          transformOrigin: '0 0',
        }}
      >
        {activeEras.map((era, index) => {
          const sample = nodes.find((n) => n.era === era.id);
          const colX = (sample?.ui_x ?? index) * colWidth;
          const eraColor = ERA_COLORS[era.id] || '#ccc';

          return (
            <Box key={era.id}>
              {index > 0 && (
                <Box
                  style={{
                    position: 'absolute',
                    left: colX - H_GAP / 2,
                    top: 0,
                    width: 1,
                    height: treeHeight,
                    background:
                      'linear-gradient(to bottom, transparent, rgba(160,160,160,0.35), transparent)',
                    pointerEvents: 'none',
                  }}
                />
              )}

              {/* era column tint */}
              <Box
                style={{
                  position: 'absolute',
                  left: colX - COL_PAD,
                  top: 0,
                  width: NODE_W + COL_PAD * 2,
                  height: treeHeight,
                  background: ERA_COLORS_DIM[era.id] || 'transparent',
                  pointerEvents: 'none',
                  borderRadius: '4px',
                }}
              />

              <Box
                style={{
                  position: 'absolute',
                  left: colX,
                  top: 0,
                  width: NODE_W,
                  height: HEADER_H,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontWeight: 'bold',
                  fontSize: '12px',
                  letterSpacing: '0.08em',
                  textTransform: 'uppercase',
                  color: eraColor,
                  pointerEvents: 'none',
                  borderBottom: `2px solid ${eraColor}`,
                  textShadow: `0 0 12px ${ERA_COLORS_GLOW[era.id] || 'transparent'}`,
                  background: 'rgba(0,0,0,0.35)',
                  borderRadius: '4px 4px 0 0',
                }}
              >
                {era.label}
              </Box>
            </Box>
          );
        })}

        <svg
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: treeWidth,
            height: treeHeight,
            pointerEvents: 'none',
            overflow: 'visible',
          }}
        >
          {links.map((l) => (
            <path
              key={l.id}
              d={l.path}
              fill="none"
              stroke={l.color}
              strokeWidth={2.25}
              strokeOpacity={l.opacity}
              strokeLinejoin="round"
              strokeLinecap="round"
            />
          ))}
        </svg>

        {nodes.map((node) => {
          const status = statusOf(node, researched, current, queue);
          const isSelected = node.id === selectedId;
          const pos = positions.get(node.id) ?? { x: 0, y: 0 };
          const eraColor = ERA_COLORS[node.era] || '#888';
          const nodeProgress = progress[node.id] ?? 0;
          const progressFrac =
            status === 'current'
              ? Math.min(1, nodeProgress / Math.max(1, node.cost))
              : 0;

          return (
            <Box
              key={node.id}
              style={{
                position: 'absolute',
                left: pos.x * colWidth,
                top: HEADER_H + pos.y * (NODE_H + V_GAP),
                width: NODE_W,
                height: NODE_H,
              }}
            >
              <Tooltip content={node.desc || node.name}>
                <Button
                  fluid
                  ellipsis
                  icon={STATUS_ICON[status]}
                  iconSpin={status === 'current'}
                  color={STATUS_COLOR[status]}
                  selected={isSelected}
                  style={{
                    height: '100%',
                    textAlign: 'left',
                    borderLeft: `4px solid ${eraColor}`,
                    background: STATUS_BG[status],
                    border: isSelected
                      ? `1px solid ${eraColor}`
                      : `1px solid ${STATUS_BORDER[status]}`,
                    boxShadow: isSelected
                      ? `0 0 0 2px ${eraColor}, 0 0 14px ${ERA_COLORS_GLOW[node.era] || 'transparent'}`
                      : status === 'current'
                        ? `0 0 12px ${ERA_COLORS_GLOW[node.era] || 'transparent'}`
                        : undefined,
                    opacity: status === 'locked' && !adminView ? 0.72 : 1,
                  }}
                  onClick={(e) => {
                    e.stopPropagation();
                    onSelect(node.id);
                  }}
                >
                  {node.name}
                </Button>
              </Tooltip>
              {status === 'current' && progressFrac > 0 && (
                <Box
                  style={{
                    position: 'absolute',
                    left: 0,
                    bottom: 0,
                    height: 3,
                    width: `${progressFrac * 100}%`,
                    background: eraColor,
                    boxShadow: `0 0 6px ${eraColor}`,
                    pointerEvents: 'none',
                    borderRadius: '0 0 2px 2px',
                    zIndex: 1,
                  }}
                />
              )}
            </Box>
          );
        })}
      </Box>

      {!nodes.length && (
        <Box
          color="label"
          style={{
            position: 'absolute',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
          }}
        >
          No technologies to display.
        </Box>
      )}
    </Box>
  );
};
