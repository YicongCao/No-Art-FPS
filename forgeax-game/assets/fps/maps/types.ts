export interface MapVisual {
  readonly name: string;
  readonly guid: string;
  readonly pos: readonly [number, number, number];
  readonly quat: readonly [number, number, number, number];
  readonly scale: readonly [number, number, number];
}

export interface MapCollider {
  readonly name: string;
  readonly pos: readonly [number, number, number];
  readonly quat: readonly [number, number, number, number];
  readonly half: readonly [number, number, number];
}

export type MapPoint = readonly [number, number, number];
