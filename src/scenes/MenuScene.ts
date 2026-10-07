import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '../config/constants';
import { IS_TOUCH } from '../config/device';
import { TAP_MIN_HEIGHT, TAP_PADDING_X } from '../config/touch';
import { enterMobileFullscreen } from '../ui/fullscreen';

type MenuOption = 'Empezar' | 'Elegir camperizador' | 'Configuración';

const MENU_OPTIONS: MenuOption[] = ['Empezar', 'Elegir camperizador', 'Configuración'];

const MENU_X = 14;
const FIRE_X = 179;
const FIRE_Y = 156;
const OPTIONS_Y = 96;
const OPTION_SPACING = TAP_MIN_HEIGHT;

export class MenuScene extends Phaser.Scene {
  private pressStartText!: Phaser.GameObjects.Text;
  private optionTexts: Phaser.GameObjects.Text[] = [];
  private selectedIndex = 0;
  private showingOptions = false;

  constructor() {
    super('Menu');
  }

  preload(): void {
    this.load.image('menu_bg', 'assets/backgrounds/campamento_nocturno_v1.jpg');
  }

  create(): void {
    const bg = this.add.image(GAME_WIDTH / 2, GAME_HEIGHT / 2, 'menu_bg');
    const scale = Math.max(GAME_WIDTH / bg.width, GAME_HEIGHT / bg.height);
    bg.setScale(scale);

    this.createFireEffect();
    this.createShootingStarLoop();

    this.add
      .text(MENU_X, 36, 'VW T3 ADVENTURE', {
        fontFamily: 'Poppins, sans-serif',
        fontStyle: 'italic bold',
        fontSize: '20px',
        color: '#ffffff',
        stroke: '#000000',
        strokeThickness: 4,
      })
      .setOrigin(0, 0.5);

    this.pressStartText = this.add
      .text(MENU_X, GAME_HEIGHT - 30, IS_TOUCH ? 'TOCA LA PANTALLA' : 'PULSA UNA TECLA', {
        fontFamily: 'Fredoka, sans-serif',
        fontSize: '12px',
        color: '#ffffff',
        stroke: '#000000',
        strokeThickness: 3,
      })
      .setOrigin(0, 0.5);

    this.tweens.add({
      targets: this.pressStartText,
      alpha: 0,
      duration: 600,
      yoyo: true,
      repeat: -1,
    });

    const keyboard = this.input.keyboard!;
    keyboard.on('keydown-UP', () => this.moveSelection(-1));
    keyboard.on('keydown-DOWN', () => this.moveSelection(1));
    keyboard.on('keydown-ENTER', () => this.handleConfirm());
    keyboard.on('keydown', () => {
      if (!this.showingOptions) this.showOptions();
    });
    this.input.on('pointerdown', () => {
      if (IS_TOUCH) enterMobileFullscreen(this);
      if (!this.showingOptions) this.showOptions();
    });
  }

  private createFireEffect(): void {
    const graphics = this.add.graphics();
    graphics.fillStyle(0xffffff, 1);
    graphics.fillCircle(4, 4, 4);
    graphics.generateTexture('flame_particle', 8, 8);
    graphics.destroy();

    this.add.particles(FIRE_X, FIRE_Y, 'flame_particle', {
      x: { min: -4, max: 4 },
      speedY: { min: -26, max: -14 },
      speedX: { min: -4, max: 4 },
      scale: { start: 0.9, end: 0 },
      alpha: { start: 0.9, end: 0 },
      lifespan: { min: 350, max: 600 },
      frequency: 45,
      tint: [0xfff3b0, 0xffb347, 0xff6a1a, 0xff3d00],
      blendMode: 'ADD',
    });
  }

  private createShootingStarLoop(): void {
    const graphics = this.add.graphics();
    const w = 22;
    const h = 3;
    for (let x = 0; x < w; x++) {
      const t = x / (w - 1); // 0 at tail, 1 at head
      graphics.fillStyle(0xffffff, t * t);
      graphics.fillRect(x, 0, 1, h);
    }
    graphics.generateTexture('star_streak', w, h);
    graphics.destroy();

    const spawn = () => {
      const startX = Phaser.Math.Between(40, 260);
      const startY = Phaser.Math.Between(8, 30);
      const goingRight = Math.random() < 0.5;
      const dx = goingRight ? Phaser.Math.Between(50, 80) : -Phaser.Math.Between(50, 80);
      const dy = Phaser.Math.Between(20, 35);

      const star = this.add.image(startX, startY, 'star_streak');
      star.setOrigin(goingRight ? 0 : 1, 0.5);
      star.setFlipX(!goingRight);
      star.setRotation(Math.atan2(dy, dx));
      star.setAlpha(0);
      star.setBlendMode('ADD');

      this.tweens.add({
        targets: star,
        x: startX + dx,
        y: startY + dy,
        alpha: { from: 0, to: 1 },
        duration: 180,
        ease: 'Quad.easeOut',
        onComplete: () => {
          this.tweens.add({
            targets: star,
            alpha: 0,
            duration: 220,
            onComplete: () => star.destroy(),
          });
        },
      });

      this.time.delayedCall(Phaser.Math.Between(3000, 8000), spawn);
    };

    this.time.delayedCall(Phaser.Math.Between(100, 300), spawn);
  }

  private showOptions(): void {
    this.showingOptions = true;
    this.pressStartText.destroy();

    MENU_OPTIONS.forEach((label, i) => {
      const text = this.add
        .text(MENU_X, OPTIONS_Y + i * OPTION_SPACING, label, {
          fontFamily: 'Fredoka, sans-serif',
          fontStyle: 'bold',
          fontSize: '14px',
          color: '#ffffff',
          stroke: '#000000',
          strokeThickness: 3,
        })
        .setOrigin(0, 0.5);

      // Zona de toque más grande que el texto, para dedos.
      const hitArea = new Phaser.Geom.Rectangle(
        -TAP_PADDING_X,
        (text.height - TAP_MIN_HEIGHT) / 2,
        text.width + TAP_PADDING_X * 2,
        TAP_MIN_HEIGHT,
      );
      text.setInteractive({ hitArea, hitAreaCallback: Phaser.Geom.Rectangle.Contains, useHandCursor: true });

      text.on('pointerover', () => this.setSelected(i));
      text.on('pointerdown', () => this.handleConfirm());

      this.optionTexts.push(text);
    });

    this.setSelected(0);
  }

  private setSelected(index: number): void {
    this.selectedIndex = index;
    this.optionTexts.forEach((text, i) => {
      text.setColor(i === index ? '#ffd24d' : '#ffffff');
      text.setScale(i === index ? 1.1 : 1);
    });
  }

  private moveSelection(delta: number): void {
    if (!this.showingOptions) return;
    const next = (this.selectedIndex + delta + MENU_OPTIONS.length) % MENU_OPTIONS.length;
    this.setSelected(next);
  }

  private handleConfirm(): void {
    if (!this.showingOptions) return;

    const selected = MENU_OPTIONS[this.selectedIndex];
    if (selected === 'Empezar') {
      this.scene.start('Intro');
    }
    // 'Elegir VW' y 'Configuración': pendientes de implementar.
  }
}
