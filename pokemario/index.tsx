import { useRef, useEffect } from "react";
import { Game } from "./game";

export default function Page() {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  useEffect(() => {
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext("2d");
    if (!canvas || !ctx) {
      return;
    }

    const game = new Game();
    const render = () => {
      canvas.width = canvas.getBoundingClientRect().width;
      canvas.height = canvas.getBoundingClientRect().height;

      game.tick(16);
      game.render(canvas, ctx);
      requestAnimationFrame(render);
    };
    render();
  }, []);

  return (
    <canvas
      style={{
        height: "100%",
        width: "100%",
        position: "absolute",
        top: "0",
        left: "0",
      }}
      ref={canvasRef}
    />
  );
}
