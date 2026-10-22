import Phaser from 'phaser';
import { Van } from '../entities/Van';
import { IS_TOUCH } from '../config/device';
import { TouchJoystick } from '../ui/TouchJoystick';
import { Odometer } from '../ui/Odometer';
import { ODOMETER_START_KM } from '../config/odometer';
import {
  MAP_GROUND_LAYER,
  MAP_JSON,
  MAP_KEY,
  MAP_LABEL_ALPHA,
  MAP_LABEL_COLOR,
  MAP_LABEL_FONT_SIZE,
  MAP_LABEL_RESOLUTION,
  MAP_LABEL_STROKE,
  MAP_LABEL_STROKE_WIDTH,
  MAP_LABEL_TYPE,
  MAP_OBJECTS_LAYER,
  MAP_SPAWN,
  MAP_TILESET_IMAGE,
  MAP_TILESET_KEY,
  MAP_TILESET_NAME,
} from '../config/map';

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
    this.load.tilemapTiledJSON(MAP_KEY, MAP_JSON);
    this.load.image(MAP_TILESET_KEY, MAP_TILESET_IMAGE);
  }

  create(): void {
    const map = this.make.tilemap({ key: MAP_KEY });
    const tileset = map.addTilesetImage(MAP_TILESET_NAME, MAP_TILESET_KEY) as Phaser.Tilemaps.Tileset;
    const ground = map.createLayer(MAP_GROUND_LAYER, tileset) as Phaser.Tilemaps.TilemapLayer;
    ground.setCollisionByProperty({ collides: true });

    const objects = map.getObjectLayer(MAP_OBJECTS_LAYER)?.objects ?? [];
    for (const o of objects.filter((o) => o.type === MAP_LABEL_TYPE)) {
      this.add
        .text(o.x ?? 0, o.y ?? 0, o.name, {
          fontFamily: 'monospace',
          fontSize: MAP_LABEL_FONT_SIZE,
          color: MAP_LABEL_COLOR,
          stroke: MAP_LABEL_STROKE,
          strokeThickness: MAP_LABEL_STROKE_WIDTH,
          resolution: MAP_LABEL_RESOLUTION,
        })
        .setOrigin(0.5)
        .setAlpha(MAP_LABEL_ALPHA);
    }

    const spawn = objects.find((o) => o.name === MAP_SPAWN);
    this.physics.world.setBounds(0, 0, map.widthInPixels, map.heightInPixels);
    this.van = new Van(this, spawn?.x ?? 0, spawn?.y ?? 0);
    this.physics.add.collider(this.van, ground);
    this.cameras.main.setBounds(0, 0, map.widthInPixels, map.heightInPixels);
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
