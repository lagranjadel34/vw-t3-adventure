import Phaser from 'phaser';
import { Van } from '../entities/Van';
import { HudScene } from './HudScene';
import { CAMERA_ZOOM_LERP, CAMERA_ZOOM_MIN, CAMERA_ZOOM_STOPPED, VAN_MAX_SPEED } from '../config/constants';
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
  private hud!: HudScene;
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
    this.scene.launch('Hud');
    this.hud = this.scene.get('Hud') as HudScene;
    this.hud.events.once(Phaser.Scenes.Events.CREATE, () => this.hud.odometer.setKm(ODOMETER_START_KM));
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => this.scene.stop('Hud'));
  }

  update(): void {
    const { joystick, odometer, pedals } = this.hud;
    if (!pedals) return; // el HUD arranca un frame después

    // Joystick = volante; la potencia sale solo de los pedales (pantalla o W/S).
    pedals.update(this.van.gasKey, this.van.brakeKey);
    this.van.update({ steer: joystick?.x ?? 0, gas: pedals.gasDown, brake: pedals.brakeDown });
    odometer.setKm(ODOMETER_START_KM + this.van.tripKm);

    // Más velocidad, más visión: la cámara se aleja suavemente.
    const cam = this.cameras.main;
    const t = Math.min(Math.abs(this.van.speed) / VAN_MAX_SPEED, 1);
    const target = Phaser.Math.Linear(CAMERA_ZOOM_STOPPED, CAMERA_ZOOM_MIN, t);
    cam.setZoom(Phaser.Math.Linear(cam.zoom, target, CAMERA_ZOOM_LERP));
  }
}
