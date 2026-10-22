import Phaser from 'phaser';
import {
  VAN_ACCELERATION,
  VAN_ANGULAR_DRAG,
  VAN_MAX_SPEED,
  VAN_DRAG,
  VAN_TURN_RATE,
} from '../config/constants';
import { METERS_PER_KM, METERS_PER_PIXEL } from '../config/odometer';

/** Entrada analógica opcional (joystick táctil). Valores en [-1, 1]. */
export interface VanAnalogInput {
  steer: number;
  throttle: number;
}

export class Van extends Phaser.Physics.Arcade.Sprite {
  private cursors: Phaser.Types.Input.Keyboard.CursorKeys;
  private keyW: Phaser.Input.Keyboard.Key;
  private keyA: Phaser.Input.Keyboard.Key;
  private keyS: Phaser.Input.Keyboard.Key;
  private keyD: Phaser.Input.Keyboard.Key;
  private lastX: number;
  private lastY: number;
  private tripMeters = 0;

  constructor(scene: Phaser.Scene, x: number, y: number) {
    super(scene, x, y, 't3_base');
    scene.add.existing(this);
    scene.physics.add.existing(this);

    this.setDamping(true);
    this.setDrag(VAN_DRAG);
    this.setMaxVelocity(VAN_MAX_SPEED);
    this.setAngularDrag(VAN_ANGULAR_DRAG);
    this.setAngle(0);
    this.lastX = x;
    this.lastY = y;

    const keyboard = scene.input.keyboard as Phaser.Input.Keyboard.KeyboardPlugin;
    this.cursors = keyboard.createCursorKeys();
    this.keyW = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.W);
    this.keyA = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.A);
    this.keyS = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.S);
    this.keyD = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.D);
  }

  /** Distancia recorrida en esta partida (km). Fuente única para cuentakilómetros, averías, etc. */
  get tripKm(): number {
    return this.tripMeters / METERS_PER_KM;
  }

  update(analog?: VanAnalogInput): void {
    // Distancia real recorrida (no la velocidad), así choques y paradas no suman.
    this.tripMeters += Phaser.Math.Distance.Between(this.lastX, this.lastY, this.x, this.y) * METERS_PER_PIXEL;
    this.lastX = this.x;
    this.lastY = this.y;

    const left = this.cursors.left?.isDown || this.keyA.isDown;
    const right = this.cursors.right?.isDown || this.keyD.isDown;
    const forward = this.cursors.up?.isDown || this.keyW.isDown;
    const back = this.cursors.down?.isDown || this.keyS.isDown;

    // Teclado manda; si no hay teclas pulsadas, se usa el joystick.
    const steer = left ? -1 : right ? 1 : (analog?.steer ?? 0);
    const throttle = forward ? 1 : back ? -1 : (analog?.throttle ?? 0);

    this.setAngularVelocity(VAN_TURN_RATE * steer);

    const body = this.body as Phaser.Physics.Arcade.Body;
    if (throttle !== 0) {
      const thrustAngle = Phaser.Math.DegToRad(this.angle - 90);
      this.scene.physics.velocityFromRotation(thrustAngle, VAN_ACCELERATION * throttle, body.acceleration);
    } else {
      body.setAcceleration(0, 0);
    }
  }
}
