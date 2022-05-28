import { Renderable, Sprite } from "./sprite";
import { Landscape } from "./sky";
import { InteractionMonitor, KeyboardKey } from "./interaction-monitor";

export class Game {
  score: number = 0;
  renderables: Renderable[] = [];
  monitor = new InteractionMonitor();

  constructor(public width: number, public height: number) {
    this.renderables.push(new Landscape(this));
  }

  tick(delta: number): void {
    for (const renderable of this.renderables) {
      renderable.tick(delta, this);
    }
  }

  render(canvas: HTMLCanvasElement, ctx: CanvasRenderingContext2D) {
    this.width = canvas.width;
    this.height = canvas.height;
    ctx.clearRect(0, 0, this.width, this.height);

    for (const renderable of this.renderables) {
      renderable.render(this, ctx);
    }
  }
}
