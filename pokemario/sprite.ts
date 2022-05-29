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

export abstract class Sprite {
    image: HTMLImageElement | null = null;

    constructor(
        public position: Position,
        public size: Size,
        public assetPath: string
    ) {}

    getAssetImage() {
        if (this.image?.src !== this.assetPath) {
            const image = new Image();
            image.src = this.assetPath;
            this.image = image;
        }
        return this.image!;
    }

    abstract tick(delta: number, game: Game): void;

    // if the two things are juuuuuust about to collide, this will return a zero vector instead of returning undefined.
    collisionVector(other: Sprite): Vector2 | undefined {
        const { x: otherX1, y: otherY1 } = other.position;
        const otherX2 = other.position.x + other.size.width;
        const otherY2 = other.position.y + other.size.height;

        const { x: selfX1, y: selfY1 } = other.position;
        const selfX2 = other.position.x + other.size.width;
        const selfY2 = other.position.y + other.size.height;

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
        // is wildly inaccurate, but, uh, meh

        const otherXM = (otherX1 + otherX2) / 2;
        const selfXM = (selfX1 + selfX2) / 2;
        const otherYM = (otherY1 + otherY2) / 2;
        const selfYM = (selfY1 + selfY2) / 2;

        return {
            x: otherXM - selfXM,
            y: otherYM - selfYM,
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

export class Enemy extends Sprite {
    private velocity: Vector2 = { x: 0, y: 0 };
    private anchoredOn: Sprite | undefined = undefined;
    private isWalkLeft: boolean = true;
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

            if (vector) {
            }

            this.position.x += vector.x;
            this.position.y += vector.y;
        }
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
