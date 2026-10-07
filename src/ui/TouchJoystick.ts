import Phaser from 'phaser';
import { GAME_WIDTH } from '../config/constants';
import {
  JOYSTICK_ACTIVE_ALPHA,
  JOYSTICK_DEAD_ZONE,
  JOYSTICK_DEPTH,
  JOYSTICK_IDLE_ALPHA,
  JOYSTICK_IDLE_X,
  JOYSTICK_IDLE_Y,
  JOYSTICK_KNOB_RADIUS,
  JOYSTICK_RADIUS,
  JOYSTICK_ZONE_WIDTH_RATIO,
} from '../config/touch';

/** Joystick virtual flotante. x/y en [-1, 1] (y negativo = arriba). */
export class TouchJoystick {
  x = 0;
  y = 0;

  private base: Phaser.GameObjects.Arc;
  private knob: Phaser.GameObjects.Arc;
  private pointerId: number | null = null;
  private originX = JOYSTICK_IDLE_X;
  private originY = JOYSTICK_IDLE_Y;

  constructor(scene: Phaser.Scene) {
    this.base = scene.add
      .circle(this.originX, this.originY, JOYSTICK_RADIUS, 0xffffff, 0.15)
      .setStrokeStyle(1, 0xffffff, 0.8);
    this.knob = scene.add.circle(this.originX, this.originY, JOYSTICK_KNOB_RADIUS, 0xffffff, 0.6);
    for (const o of [this.base, this.knob]) o.setScrollFactor(0).setDepth(JOYSTICK_DEPTH);
    this.setActive(false);

    scene.input.on('pointerdown', this.onDown, this);
    scene.input.on('pointermove', this.onMove, this);
    scene.input.on('pointerup', this.onUp, this);
    scene.input.on('pointerupoutside', this.onUp, this);
    scene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      scene.input.off('pointerdown', this.onDown, this);
      scene.input.off('pointermove', this.onMove, this);
      scene.input.off('pointerup', this.onUp, this);
      scene.input.off('pointerupoutside', this.onUp, this);
    });
  }

  private onDown(pointer: Phaser.Input.Pointer): void {
    if (this.pointerId !== null) return;
    if (pointer.x > GAME_WIDTH * JOYSTICK_ZONE_WIDTH_RATIO) return;
    this.pointerId = pointer.id;
    this.originX = pointer.x;
    this.originY = pointer.y;
    this.base.setPosition(this.originX, this.originY);
    this.setActive(true);
    this.onMove(pointer);
  }

  private onMove(pointer: Phaser.Input.Pointer): void {
    if (pointer.id !== this.pointerId) return;
    const dx = pointer.x - this.originX;
    const dy = pointer.y - this.originY;
    const dist = Math.min(Math.hypot(dx, dy), JOYSTICK_RADIUS);
    const angle = Math.atan2(dy, dx);
    const kx = Math.cos(angle) * dist;
    const ky = Math.sin(angle) * dist;
    this.knob.setPosition(this.originX + kx, this.originY + ky);

    const nx = kx / JOYSTICK_RADIUS;
    const ny = ky / JOYSTICK_RADIUS;
    this.x = Math.abs(nx) < JOYSTICK_DEAD_ZONE ? 0 : nx;
    this.y = Math.abs(ny) < JOYSTICK_DEAD_ZONE ? 0 : ny;
  }

  private onUp(pointer: Phaser.Input.Pointer): void {
    if (pointer.id !== this.pointerId) return;
    this.pointerId = null;
    this.x = 0;
    this.y = 0;
    this.originX = JOYSTICK_IDLE_X;
    this.originY = JOYSTICK_IDLE_Y;
    this.base.setPosition(this.originX, this.originY);
    this.knob.setPosition(this.originX, this.originY);
    this.setActive(false);
  }

  private setActive(active: boolean): void {
    const alpha = active ? JOYSTICK_ACTIVE_ALPHA : JOYSTICK_IDLE_ALPHA;
    this.base.setAlpha(alpha);
    this.knob.setAlpha(alpha);
  }
}
