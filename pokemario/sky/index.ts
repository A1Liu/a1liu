import { SpriteGroup, vec2equal, vec2mul, Vector2 } from "../sprite";
import { Game } from "../game";
import { SkyBackground } from "./sky";
import { TransitionManager, Transitions } from "../transition";
import { KeyboardKey } from "../interaction-monitor";

export class Landscape extends SpriteGroup {
  transitionManager = new TransitionManager();
  direction: "left" | "right" | null = null;
  currentVelocity: Vector2 = { x: 0, y: 0 };
  walkVelocity: Vector2;
  sprintVelocity: Vector2;

  constructor(game: Game) {
    super([
      new SkyBackground(
        {
          x: 0,
          y: 0,
        },
        game
      ),
      new SkyBackground(
        {
          x: game.width,
          y: 0,
        },
        game
      ),
    ]);

    this.walkVelocity = { x: 0.01 * game.width, y: 0 };
    this.sprintVelocity = vec2mul(3, this.walkVelocity);
  }

  tick(delta: number, game: Game) {
    const currentDirection = game.monitor.isPressed(KeyboardKey.Right)
      ? "right"
      : game.monitor.isPressed(KeyboardKey.Left)
      ? "left"
      : null;
    const velocity = currentDirection
      ? game.monitor.isPressed(KeyboardKey.Shift)
        ? this.sprintVelocity
        : this.walkVelocity
      : { x: 0, y: 0 };

    const currentVelocity = this.transitionManager.applyTransition(
      {
        initial: vec2mul(
          this.direction === "left" ? 1 : this.direction === "right" ? -1 : 0,
          velocity
        ),
        target: vec2mul(
          currentDirection === "left"
            ? 1
            : currentDirection === "right"
            ? -1
            : 0,
          velocity
        ),
        state: this.sprites[0]!.velocity,
        transition: Transitions.linear(250),
        update: (velocity) => {
          this.sprites.forEach((sprite) => {
            sprite.velocity = velocity;
          });
        },
      },
      delta
    );
    this.direction = currentDirection;
    this.sprites.forEach((sprite) => {
      sprite.velocity = currentVelocity;
    });

    super.tick(delta, game);
  }
}
