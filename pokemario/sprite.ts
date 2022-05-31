import { Game } from "./game";

export const EPSILON = 0.0001;

export interface Position {
  x: number;
  y: number;
}

export interface Size {
  width: number;
  height: number;
}

export interface Vector2 {
  x: number;
  y: number;
}

export function vec2equal(left: Vector2, right: Vector2) {
  return left.x === right.x && left.y === right.y;
}

export function vec2mul(scalar: number, vec: Vector2): Vector2 {
  return {
    x: vec.x * scalar,
    y: vec.y * scalar,
  };
}

export function getAccelerationVector(
  initialVelocity: Vector2,
  terminalVelocity: Vector2,
  duration: number
): Vector2 {
  return {
    x: (terminalVelocity.x - initialVelocity.x) / duration,
    y: (terminalVelocity.y - initialVelocity.y) / duration,
  };
}

export abstract class Renderable {
  abstract tick(delta: number, game: Game): void;
  abstract render(game: Game, ctx: CanvasRenderingContext2D): void;
}

export abstract class Sprite extends Renderable {
  image: HTMLImageElement | null = null;
  velocity: Vector2 = {
    x: 0,
    y: 0,
  };

  constructor(
    public position: Position,
    public size: Size,
    public assetPath: string
  ) {
    super();
  }

  getAssetImage() {
    if (this.image?.src !== this.assetPath) {
      const image = new Image();
      image.src = this.assetPath;
      this.image = image;
    }
    return this.image!;
  }

  // if the two things are juuuuuust about to collide, this will return a zero vector instead of returning undefined.
  collisionVector(other: Sprite): Vector2 | undefined {
    const { x: otherX1, y: otherY1 } = other.position;
    const otherX2 = other.position.x + other.size.width;
    const otherY2 = other.position.y + other.size.height;

    const { x: selfX1, y: selfY1 } = other.position;
    const selfX2 = other.position.x + other.size.width;
    const selfY2 = other.position.y + other.size.height;

    // other is too far left or far right to collide
    if (otherX1 > selfX2 || selfX1 > otherX1) return undefined;
    if (otherY1 > selfY2 || selfY1 > otherY1) return undefined;

    // other is too far left or far right to collide
    if (otherX1 + EPSILON > selfX2 || selfX1 + EPSILON > otherX2)
      return undefined;
    if (otherY1 + EPSILON > selfY2 || selfY1 + EPSILON > otherY2)
      return undefined;

    // Edges touch but they dont overlap; we report a collision vector
    // of zero here.
    if (otherX1 - selfX2 <= EPSILON || selfX1 - otherX2 <= EPSILON)
      return { x: 0, y: 0 };
    if (otherY1 - selfY2 <= EPSILON || selfY1 - otherY2 <= EPSILON)
      return { x: 0, y: 0 };

    // Use bounding-box center-of-mass to calculate collision vector; this
    // is wildly inaccurate, but, uh, meh. Can add edge stuffs later

    const otherXM = (otherX1 + otherX2) / 2;
    const selfXM = (selfX1 + selfX2) / 2;
    const otherYM = (otherY1 + otherY2) / 2;
    const selfYM = (selfY1 + selfY2) / 2;

    return {
      x: otherXM - selfXM,
      y: otherYM - selfYM,
    };

    return {
      x: otherX1 - selfX1,
      y: otherY1 - selfY1,
    };
  }

  render(game: Game, ctx: CanvasRenderingContext2D) {
    const image = this.getAssetImage();
    ctx.drawImage(
      image,
      0,
      0,
      image.width,
      image.height,
      this.position.x,
      this.position.y,
      this.size.width,
      this.size.height
    );
  }
}

export class SpriteGroup extends Renderable {
  constructor(public sprites: Sprite[]) {
    super();
  }

  tick(delta: number, game: Game) {
    this.sprites.forEach((sprite) => sprite.tick(delta, game));
  }

  render(game: Game, ctx: CanvasRenderingContext2D) {
    this.sprites.forEach((sprite) => sprite.render(game, ctx));
  }
}

export class Enemy extends Sprite {
  velocity: Vector2 = { x: 0, y: 0 };
  private anchoredOn: Sprite | undefined = undefined;
  private walkSpeed: number = 1.0;

  constructor(position: Position, size: Size, assetPath: string) {
    super(position, size, assetPath);
  }

  tick(delta: number, game: Game): void {
    // Simulate walking or freefall
    if (this.anchoredOn) {
      this.position.x += delta * this.walkSpeed;
    } else {
      this.position.x += delta * this.velocity.x;
      this.position.y += delta * this.velocity.y;
    }

    // Check if we can still anchor
    anchorCheck: if (this.anchoredOn) {
      const vector = this.collisionVector(this.anchoredOn); // speed and direction!
      if (!vector) {
        this.anchoredOn = undefined;
        break anchorCheck;
      }

      this.position.x += vector.x;
      this.position.y += vector.y;
    }

    // Check for new collisions, potentially causing a new anchorage as well
    for (const sprite of game.sprites) {
      if (sprite === this) continue;
      if (sprite === this.anchoredOn) continue;

      const vector = this.collisionVector(sprite);
      if (!vector) continue;

      this.position.x += vector.x;
      this.position.y += vector.y;

      // For now, any kind of collision just straight-up stops you dead
      // in your tracks. Obviously this is not reasonable, but like, whatever
      //
      // A fun side effect of this is that enemies become sticky after falling;
      // if they hit a wall after jumping off of a thing, they immediately
      // stick to it.
      this.velocity.x = 0;
      this.velocity.y = 0;

      // Collision check ordering could cause weird nonsense; the hope is
      // that it will not come to that.
      if (!this.anchoredOn && this.isStandingOn(sprite)) {
        this.anchoredOn = sprite;
      }
    }
  }

  isStandingOn(other: Sprite): boolean {
    const { y: otherY1 } = other.position;

    const { y: selfY1 } = other.position;
    const selfY2 = other.position.y + other.size.height;

    return otherY1 - selfY2 <= EPSILON;
  }
}

export class PokeMan extends Sprite {
  constructor(position: Position, size: Size, assetPath: string) {
    super(position, size, assetPath);
  }

  tick(delta: number, game: Game): void {}
}

export class Block extends Sprite {
  constructor(position: Position, size: Size, assetPath: string) {
    super(position, size, assetPath);
  }

  tick(delta: number, game: Game): void {
    // Do nothing
  }
}
