import { useCallback, useMemo, useRef, useState } from 'react';
import { Box, Button } from 'tgui-core/components';

import {
  ERA_COLORS,
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
  onSelect: (id: string) => void;
};

const NODE_W = 170;
const NODE_H = 48;
const H_GAP = 56;
const V_GAP = 52;
const HEADER_H = 36;
const COL_PAD = 12;

const MIN_ZOOM = 0.4;
const MAX_ZOOM = 2.0;
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
  const { nodes, researched, current, queue, selectedId, onSelect } = props;

  const [offset, setOffset] = useState({ x: 24, y: 16 });
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

  const treeHeight = HEADER_H + (maxY + 1) * (NODE_H + V_GAP) + 40;
  const treeWidth = Math.max(activeEras.length, 1) * colWidth + 40;

  const links = useMemo(() => {
    const result: { id: string; path: string; color: string }[] = [];

    for (const node of nodes) {
      const prereqs = Array.isArray(node.prereqs) ? node.prereqs : [];
      const child = positions.get(node.id);
      if (!child) continue;

      for (const prereq of prereqs) {
        const parent = positions.get(prereq);
        if (!parent) continue;

        const x1 = parent.x * colWidth + NODE_W / 2;
        const y1 = HEADER_H + parent.y * (NODE_H + V_GAP) + NODE_H;
        const x2 = child.x * colWidth + NODE_W / 2;
        const y2 = HEADER_H + child.y * (NODE_H + V_GAP);

        const parentNode = byId.get(prereq);
        const color =
          ERA_COLORS[parentNode?.era ?? ''] || 'rgba(160,160,160,0.7)';

        result.push({
          id: `${prereq}->${node.id}`,
          path: orthoPath(x1, y1, x2, y2),
          color,
        });
      }
    }
    return result;
  }, [nodes, positions, byId, colWidth]);

  return (
    <Box
      height="100%"
      style={{
        overflow: 'hidden',
        position: 'relative',
        background: 'rgba(0, 0, 0, 0.35)',
        border: '1px solid rgba(255, 255, 255, 0.1)',
        borderRadius: '4px',
        cursor: dragging ? 'grabbing' : 'grab',
        userSelect: 'none',
        minHeight: '320px',
      }}
      onMouseDown={onMouseDown}
      onMouseMove={onMouseMove}
      onMouseUp={onMouseUp}
      onMouseLeave={onMouseUp}
      onWheel={onWheel}
    >
      <Box
        style={{
          position: 'absolute',
          right: 8,
          top: 8,
          zIndex: 5,
          display: 'flex',
          gap: 4,
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
      </Box>

      <Box
        style={{
          position: 'absolute',
          transform: `translate(${offset.x}px, ${offset.y}px) scale(${zoom})`,
          transformOrigin: '0 0',
        }}
      >
        {activeEras.map((era, index) => {
          const x = index;
          const sample = nodes.find((n) => n.era === era.id);
          const colX = (sample?.ui_x ?? index) * colWidth;

          return (
            <Box key={era.id}>
              {index > 0 && (
                <Box
                  style={{
                    position: 'absolute',
                    left: colX - H_GAP / 2,
                    top: 0,
                    width: 2,
                    height: treeHeight,
                    background: 'rgba(160, 160, 160, 0.55)',
                    pointerEvents: 'none',
                  }}
                />
              )}

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
                  fontSize: '13px',
                  letterSpacing: '0.04em',
                  textTransform: 'uppercase',
                  color: ERA_COLORS[era.id] || '#ccc',
                  pointerEvents: 'none',
                  borderBottom: `2px solid ${ERA_COLORS[era.id] || '#666'}`,
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
              strokeWidth={2}
              strokeOpacity={0.75}
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
                  boxShadow:
                    status === 'current' ? `0 0 8px ${eraColor}` : undefined,
                }}
                onClick={(e) => {
                  e.stopPropagation();
                  onSelect(node.id);
                }}
              >
                {node.name}
              </Button>
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
