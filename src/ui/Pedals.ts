import Phaser from 'phaser';
import {
  PEDAL_BRAKE,
  PEDAL_COLORS,
  PEDAL_DEPTH,
  PEDAL_ARM_LENGTH,
  PEDAL_ARM_WIDTH,
  PEDAL_CORNER,
  PEDAL_GAS,
  PEDAL_HIT_PADDING,
  PEDAL_IDLE_ALPHA,
  PEDAL_PRESS_OFFSET,
  PEDAL_PRESSED_ALPHA,
  PEDAL_RIB_INSET,
  PEDAL_RIB_SPACING,
  PedalRect,
} from '../config/pedals';

/** Pedal de goma con estrías; se pisa con cualquier dedo (o ratón) que esté encima. */
class Pedal {
  pressed = false;
  private g: Phaser.GameObjects.Graphics;
  private hit: Phaser.Geom.Rectangle;

  constructor(
    scene: Phaser.Scene,
    private rect: PedalRect,
  ) {
    const p = PEDAL_HIT_PADDING;
    this.hit = new Phaser.Geom.Rectangle(rect.x - p, rect.y - p, rect.w + p * 2, rect.h + p * 2);
    this.g = scene.add.graphics().setScrollFactor(0).setDepth(PEDAL_DEPTH);
    this.draw();
  }

  update(pointers: Phaser.Input.Pointer[], keyDown: boolean): void {
    const pressed = keyDown || pointers.some((ptr) => ptr.isDown && this.hit.contains(ptr.x, ptr.y));
    if (pressed === this.pressed) return;
    this.pressed = pressed;
    this.draw();
  }

  private draw(): void {
    const { x, w, h } = this.rect;
    const y = this.rect.y + (this.pressed ? PEDAL_PRESS_OFFSET : 0);
    const c = PEDAL_CORNER;
    const g = this.g.clear().setAlpha(this.pressed ? PEDAL_PRESSED_ALPHA : PEDAL_IDLE_ALPHA);

    // Brazo metálico del que cuelga el pedal (sale por arriba, centrado).
    const ax = x + Math.floor((w - PEDAL_ARM_WIDTH) / 2);
    g.fillStyle(PEDAL_COLORS.armShadow).fillRect(ax, y - PEDAL_ARM_LENGTH, PEDAL_ARM_WIDTH + 1, PEDAL_ARM_LENGTH);
    g.fillStyle(PEDAL_COLORS.arm).fillRect(ax, y - PEDAL_ARM_LENGTH, PEDAL_ARM_WIDTH, PEDAL_ARM_LENGTH);

    // Goma con esquinas romas: contorno y relleno como rectángulos en cruz.
    const rounded = (inset: number, color: number): void => {
      const cc = Math.max(c - inset, 0);
      g.fillStyle(color);
      g.fillRect(x + inset + cc, y + inset, w - (inset + cc) * 2, h - inset * 2);
      g.fillRect(x + inset, y + inset + cc, w - inset * 2, h - (inset + cc) * 2);
      if (cc > 1) g.fillRect(x + inset + 1, y + inset + 1, w - (inset + 1) * 2, h - (inset + 1) * 2);
    };
    rounded(0, PEDAL_COLORS.outline);
    rounded(1, this.pressed ? PEDAL_COLORS.rubberPressed : PEDAL_COLORS.rubber);
    // Brillo arriba de la goma.
    g.fillStyle(PEDAL_COLORS.highlight).fillRect(x + c + 1, y + 1, w - (c + 1) * 2, 1);

    // Estrías horizontales en relieve (surco oscuro + filo claro).
    for (let ry = y + PEDAL_RIB_SPACING; ry < y + h - PEDAL_RIB_SPACING; ry += PEDAL_RIB_SPACING) {
      g.fillStyle(PEDAL_COLORS.rib).fillRect(x + PEDAL_RIB_INSET, ry, w - PEDAL_RIB_INSET * 2, 1);
      g.fillStyle(PEDAL_COLORS.ribLight).fillRect(x + PEDAL_RIB_INSET, ry + 1, w - PEDAL_RIB_INSET * 2, 1);
    }
  }
}

/** Acelerador y freno en el HUD. Sin acelerador pisado no hay potencia. */
export class Pedals {
  private gas: Pedal;
  private brake: Pedal;

  constructor(private scene: Phaser.Scene) {
    this.gas = new Pedal(scene, PEDAL_GAS);
    this.brake = new Pedal(scene, PEDAL_BRAKE);
  }

  get gasDown(): boolean {
    return this.gas.pressed;
  }

  get brakeDown(): boolean {
    return this.brake.pressed;
  }

  /** El teclado también "pisa" los pedales para que se vea en pantalla. */
  update(gasKey: boolean, brakeKey: boolean): void {
    const pointers = this.scene.input.manager.pointers;
    this.gas.update(pointers, gasKey);
    this.brake.update(pointers, brakeKey);
  }
}
