import { Position, Sprite, Vector2 } from "../sprite";
import { Game } from "../game";
import skyJpg from "./sky.jpg";
import { projectSize } from "../utils";

export class SkyBackground extends Sprite {
  constructor(initialPosition: Position, game: Game) {
    super(initialPosition, projectSize(skyJpg, game), skyJpg.src);
    this.image = new Image();
    this.image.src = skyJpg.src;
  }

  tick(delta: number, game: Game) {
    this.position.x += this.velocity.x;
    if (this.velocity.x < 0 && this.position.x < -this.size.width) {
      this.position.x = this.size.width;
    }
    if (this.velocity.x > 0 && this.position.x >= this.size.width) {
      this.position.x = -this.size.width;
    }
  }
}
