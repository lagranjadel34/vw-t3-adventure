import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '../config/constants';
import { Van } from '../entities/Van';
import { IS_TOUCH } from '../config/device';
import { TouchJoystick } from '../ui/TouchJoystick';

export class PlayScene extends Phaser.Scene {
  private van!: Van;
  private joystick?: TouchJoystick;

  constructor() {
    super('Play');
  }

  preload(): void {
    this.load.image('t3_base', 'assets/sprites/Vwt3vanagonverdeV1.png');
  }

  create(): void {
    this.van = new Van(this, GAME_WIDTH / 2, GAME_HEIGHT / 2);
    this.cameras.main.startFollow(this.van, true);
    this.joystick = IS_TOUCH ? new TouchJoystick(this) : undefined;
  }

  update(): void {
    // Joystick: horizontal = girar, vertical (arriba) = acelerar.
    this.van.update(this.joystick && { steer: this.joystick.x, throttle: -this.joystick.y });
  }
}
