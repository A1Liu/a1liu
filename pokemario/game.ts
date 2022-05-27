import { Sprite } from './sprite';
import { SkyBackground } from './sky';

export class Game {
    private score : number = 0;
    private sprites: Sprite[] = [];

    width = 0;
    height = 0;

    constructor() {
        const sky = new SkyBackground();
        this.sprites.push(sky);
    }

    tick(delta: number): void {
        for (const sprite of this.sprites) {
            sprite.tick(delta, this)
        }
    }

    render(canvas: HTMLCanvasElement, ctx: CanvasRenderingContext2D) {
        this.width = canvas.width;
        this.height = canvas.height;
        ctx.clearRect(0, 0, this.width, this.height)

        for (const sprite of this.sprites) {
            sprite.render(this, ctx)
        }
    }
}
