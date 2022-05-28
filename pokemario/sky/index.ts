import { Position, Renderable, Sprite, SpriteGroup, Vector2 } from "../sprite";
import { Game } from "../game";
import skyJpg from "./sky.jpg";
import { SkyBackground } from "./sky";

export class Landscape extends SpriteGroup {
  constructor(game: Game) {
    super([
      new SkyBackground({
        x: 0,
        y: 0,
      }),
      new SkyBackground({
        x: game.width,
        y: 0,
      }),
      // new SkyBackground({
      //   x: game.width,
      //   y: 0,
      // }),
      // new SkyBackground({
      //   x: game.width,
      //   y: 0,
      // }),
    ]);
  }

  tick(delta: number, game: Game) {
    // TODO: Set velocities of child sprites

    super.tick(delta, game);
  }
}
