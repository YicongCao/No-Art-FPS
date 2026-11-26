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

/** Godot WorldEnvironment values that drive the sky clear colour and ambient light. */
export interface MapEnvironment {
  readonly background: readonly [number, number, number];
  readonly ambient: readonly [number, number, number];
  readonly ambientEnergy: number;
}
