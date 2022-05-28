import { Sprite, Vector2 } from "../sprite";
import { Game } from "../game";
import skyJpg from "./sky.jpg";

export class SkyBackground extends Sprite {
  velocity: Vector2 = {
    x: -5,
    y: 0,
  };

  constructor() {
    super(
      {
        x: 0,
        y: 0,
      },
      {
        width: 0,
        height: 0,
      },
      skyJpg.src
    );
    this.image = new Image();
    this.image.src = skyJpg.src;
  }

  tick(delta: number, game: Game) {
    this.position.x += this.velocity.x;
    this.position.y += this.velocity.y;
  }

  render(game: Game, ctx: CanvasRenderingContext2D) {
    this.size = {
      width: game.width,
      height: game.height,
    };
    super.render(game, ctx);
  }
}
