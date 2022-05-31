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
    if (evt.metaKey || evt.repeat) {
      return;
    }

    let mask : number = 0;
    switch (evt.key) {
      case "Shift":
        mask = KeyboardKey.Shift;
        break;

      case "Space":
        mask = KeyboardKey.Space;
        break;

      case "ArrowUp":
      case "w":
        mask = KeyboardKey.Up;
        break;

      case "ArrowLeft":
      case "a":
        mask = KeyboardKey.Left;
        break;

      case "ArrowDown":
      case "s":
        mask = KeyboardKey.Down;
        break;

      case "ArrowRight":
      case "d":
        mask = KeyboardKey.Right;
        break;

      default:
        return;
    }

    evt.preventDefault();

    if (evt.type == 'keydown') {
      this.state |= mask;
    } else {
      this.state &= ~mask;
    }
  };

  isPressed(key: KeyboardKey) {
    return (this.state & key) !== 0;
  }
}
