import Phaser from 'phaser';
import { IS_TOUCH } from '../config/device';
import { TouchJoystick } from '../ui/TouchJoystick';
import { Odometer } from '../ui/Odometer';
import { Pedals } from '../ui/Pedals';

/**
 * Capa del HUD encima de Play, con su propia cámara: así el zoom del mapa
 * (más visión a más velocidad) no escala el cuentakilómetros ni los mandos.
 */
export class HudScene extends Phaser.Scene {
  joystick?: TouchJoystick;
  odometer!: Odometer;
  pedals!: Pedals;

  constructor() {
    super('Hud');
  }

  create(): void {
    this.joystick = IS_TOUCH ? new TouchJoystick(this) : undefined;
    this.odometer = new Odometer(this);
    this.pedals = new Pedals(this);
  }
}
