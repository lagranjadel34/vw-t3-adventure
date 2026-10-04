import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '../config/constants';
import { Van } from '../entities/Van';

export class PlayScene extends Phaser.Scene {
  private van!: Van;

  constructor() {
    super('Play');
  }

  preload(): void {
    this.load.image('t3_base', 'assets/sprites/Vwt3vanagonverdeV1.png');
  }

  create(): void {
    this.van = new Van(this, GAME_WIDTH / 2, GAME_HEIGHT / 2);
    this.cameras.main.startFollow(this.van, true);
  }

  update(): void {
    this.van.update();
  }
}
