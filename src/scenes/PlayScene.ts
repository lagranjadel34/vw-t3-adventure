import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '../config/constants';
import { Van } from '../entities/Van';
import { IS_TOUCH } from '../config/device';
import { TouchJoystick } from '../ui/TouchJoystick';
import { Odometer } from '../ui/Odometer';
import { ODOMETER_START_KM } from '../config/odometer';

export class PlayScene extends Phaser.Scene {
  private van!: Van;
  private joystick?: TouchJoystick;
  private odometer!: Odometer;
  // La cámara sigue al eje delantero, así en pantalla se ve el giro sobre el morro.
  private cameraTarget = new Phaser.Math.Vector2();

  constructor() {
    super('Play');
  }

  preload(): void {
    this.load.image('t3_base', 'assets/sprites/Vwt3vanagonverdeV1.png');
  }

  create(): void {
    this.van = new Van(this, GAME_WIDTH / 2, GAME_HEIGHT / 2);
    this.events.on(Phaser.Scenes.Events.POST_UPDATE, () => this.cameraTarget.copy(this.van.front));
    this.cameras.main.startFollow(this.cameraTarget, true);
    this.joystick = IS_TOUCH ? new TouchJoystick(this) : undefined;
    this.odometer = new Odometer(this);
    this.odometer.setKm(ODOMETER_START_KM);
  }

  update(): void {
    // Joystick: horizontal = girar, vertical (arriba) = acelerar.
    this.van.update(this.joystick && { steer: this.joystick.x, throttle: -this.joystick.y });
    this.odometer.setKm(ODOMETER_START_KM + this.van.tripKm);
  }
}
