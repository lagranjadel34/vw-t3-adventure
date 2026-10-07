import Phaser from 'phaser';

/** Pantalla completa + apaisado en móvil. Debe llamarse desde un gesto del usuario. */
export function enterMobileFullscreen(scene: Phaser.Scene): void {
  if (!scene.scale.isFullscreen && scene.sys.game.device.fullscreen.available) {
    scene.scale.startFullscreen();
  }
  const orientation = screen.orientation as ScreenOrientation & { lock?: (o: string) => Promise<void> };
  orientation.lock?.('landscape').catch(() => undefined);
}
