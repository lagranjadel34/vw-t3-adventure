import Phaser from 'phaser';
import {
  VAN_ACCELERATION,
  VAN_BRAKE_DECELERATION,
  VAN_MAX_REVERSE_SPEED,
  VAN_REVERSE_ACCELERATION,
  VAN_STOP_SPEED,
  VAN_BODY_RADIUS,
  VAN_DRAG,
  VAN_FRONT_AXLE_RATIO,
  VAN_MAX_SPEED,
  VAN_MAX_STEER_DEG,
  VAN_REAR_AXLE_RATIO,
} from '../config/constants';
import { METERS_PER_KM, METERS_PER_PIXEL } from '../config/odometer';

/** Mandos de la furgo: volante en [-1, 1] (joystick) y pedales. */
export interface VanControls {
  steer: number;
  gas: boolean;
  brake: boolean;
}

export class Van extends Phaser.Physics.Arcade.Sprite {
  private cursors: Phaser.Types.Input.Keyboard.CursorKeys;
  private keyW: Phaser.Input.Keyboard.Key;
  private keyA: Phaser.Input.Keyboard.Key;
  private keyS: Phaser.Input.Keyboard.Key;
  private keyD: Phaser.Input.Keyboard.Key;
  private lastX: number;
  private lastY: number;
  private lastRotation = 0;
  private tripMeters = 0;
  // Marcha atrás: solo si se pisa el freno con la furgo parada; dura mientras siga pisado.
  private reversing = false;
  private brakeWasDown = false;

  constructor(scene: Phaser.Scene, x: number, y: number) {
    super(scene, x, y, 't3_base');
    scene.add.existing(this);
    scene.physics.add.existing(this);

    this.setCircle(VAN_BODY_RADIUS, this.width / 2 - VAN_BODY_RADIUS, this.height / 2 - VAN_BODY_RADIUS);
    this.setCollideWorldBounds(true);
    this.setDamping(true);
    this.setDrag(VAN_DRAG);
    this.setMaxVelocity(VAN_MAX_SPEED);
    this.setAngle(0);
    this.lastX = x;
    this.lastY = y;

    const keyboard = scene.input.keyboard as Phaser.Input.Keyboard.KeyboardPlugin;
    this.cursors = keyboard.createCursorKeys();
    this.keyW = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.W);
    this.keyA = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.A);
    this.keyS = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.S);
    this.keyD = keyboard.addKey(Phaser.Input.Keyboard.KeyCodes.D);

    // Tras el paso de física (y antes de pintar): odómetro y giro sobre el morro.
    scene.events.on(Phaser.Scenes.Events.POST_UPDATE, this.afterPhysics, this);
    this.once(Phaser.GameObjects.Events.DESTROY, () =>
      scene.events.off(Phaser.Scenes.Events.POST_UPDATE, this.afterPhysics, this),
    );
  }

  /** Distancia recorrida en esta partida (km). Fuente única para cuentakilómetros, averías, etc. */
  get tripKm(): number {
    return this.tripMeters / METERS_PER_KM;
  }

  /** Velocidad con signo en el sentido del morro (px/s; negativa = marcha atrás). */
  get speed(): number {
    const body = this.body as Phaser.Physics.Arcade.Body;
    const heading = this.rotation - Math.PI / 2;
    return body.velocity.x * Math.cos(heading) + body.velocity.y * Math.sin(heading);
  }

  /** Acelerador por teclado (W/↑). */
  get gasKey(): boolean {
    return !!(this.cursors.up?.isDown || this.keyW.isDown);
  }

  /** Freno por teclado (S/↓). */
  get brakeKey(): boolean {
    return !!(this.cursors.down?.isDown || this.keyS.isDown);
  }

  update(controls: VanControls): void {
    const left = this.cursors.left?.isDown || this.keyA.isDown;
    const right = this.cursors.right?.isDown || this.keyD.isDown;

    // Teclado manda; si no hay teclas pulsadas, se usa el joystick.
    const steer = left ? -1 : right ? 1 : controls.steer;

    const body = this.body as Phaser.Physics.Arcade.Body;
    // Sin derrape: la velocidad sigue siempre el morro (la parte que va de lado se pierde).
    const heading = this.rotation - Math.PI / 2;
    let speed = Math.max(this.speed, -VAN_MAX_REVERSE_SPEED);

    // Modelo bicicleta: parada no gira; marcha atrás invierte el giro.
    const wheelbase = this.displayHeight * (VAN_FRONT_AXLE_RATIO + VAN_REAR_AXLE_RATIO);
    const yawRate = (speed / wheelbase) * Math.tan(Phaser.Math.DegToRad(VAN_MAX_STEER_DEG) * steer);
    this.setAngularVelocity(Phaser.Math.RadToDeg(yawRate));

    // Pedales: sin acelerador no hay potencia (solo rueda por inercia).
    // Freno: con la furgo parada, pisarlo mete marcha atrás (mientras siga pisado);
    // en marcha (adelante o atrás) frena hasta parar.
    const stopped = Math.abs(speed) <= VAN_STOP_SPEED;
    const brakePressed = controls.brake && !this.brakeWasDown;
    this.brakeWasDown = controls.brake;
    if (!controls.brake) this.reversing = false;
    else if (brakePressed && stopped) this.reversing = true;

    let force = 0;
    if (this.reversing) {
      force = -VAN_REVERSE_ACCELERATION;
    } else if (controls.brake) {
      // Frena contra el sentido de la marcha sin pasarse de cero.
      const dv = VAN_BRAKE_DECELERATION * (this.scene.game.loop.delta / 1000);
      speed = Math.abs(speed) <= dv ? 0 : speed - Math.sign(speed) * dv;
    } else if (controls.gas) {
      force = VAN_ACCELERATION;
    }
    body.velocity.setToPolar(heading, speed);
    body.acceleration.setToPolar(heading, force);
  }

  /** Eje delantero en coordenadas de mundo (la cámara mira hacia donde va el morro). */
  get front(): Phaser.Math.Vector2 {
    const r = this.displayHeight * VAN_FRONT_AXLE_RATIO;
    return new Phaser.Math.Vector2(this.x + r * Math.sin(this.rotation), this.y - r * Math.cos(this.rotation));
  }

  private afterPhysics(): void {
    // Distancia real recorrida (no la velocidad), así choques y paradas no suman.
    this.tripMeters += Phaser.Math.Distance.Between(this.lastX, this.lastY, this.x, this.y) * METERS_PER_PIXEL;
    this.pivotOnRearAxle();
    this.lastX = this.x;
    this.lastY = this.y;
  }

  /**
   * La física gira el sprite sobre su centro; aquí se desplaza para que el eje
   * trasero no se mueva de lado: el morro marca la curva y la trasera la sigue.
   */
  private pivotOnRearAxle(): void {
    const prev = this.lastRotation;
    this.lastRotation = this.rotation;
    if (this.rotation === prev) return;

    const r = this.displayHeight * VAN_REAR_AXLE_RATIO;
    // La trasera queda "abajo" del sprite: offset local (0, +r).
    const rearX = this.x - r * Math.sin(prev);
    const rearY = this.y + r * Math.cos(prev);
    this.setPosition(rearX + r * Math.sin(this.rotation), rearY - r * Math.cos(this.rotation));
  }
}
