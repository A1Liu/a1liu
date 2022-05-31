export enum KeyboardKey {
  Up = 1 << 1,
  Down = 1 << 2,
  Left = 1 << 3,
  Right = 1 << 4,
  Space = 1 << 5,
  Shift = 1 << 6,
}

export class InteractionMonitor {
  private state = 0;

  constructor() {
    window.addEventListener("keydown", this.onKeyToggle);
    window.addEventListener("keyup", this.onKeyToggle);
  }

  destroy() {
    window.removeEventListener("keydown", this.onKeyToggle);
    window.removeEventListener("keyup", this.onKeyToggle);
  }

  onKeyToggle = (evt: KeyboardEvent) => {
    evt.preventDefault();
    switch (evt.key) {
      case "Shift":
        this.state ^= KeyboardKey.Shift;
        break;
      case "Space":
        this.state ^= KeyboardKey.Space;
        break;
      case "ArrowUp":
      case "w":
        this.state ^= KeyboardKey.Up;
        break;
      case "ArrowLeft":
      case "a":
        this.state ^= KeyboardKey.Left;
        break;
      case "ArrowDown":
      case "s":
        this.state ^= KeyboardKey.Down;
        break;
      case "ArrowRight":
      case "d":
        this.state ^= KeyboardKey.Right;
        break;
    }
  };

  isPressed(key: KeyboardKey) {
    return (this.state & key) !== 0;
  }
}
