import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '../config/constants';

type MenuOption = 'Empezar' | 'Elegir VW' | 'Configuración';

const MENU_OPTIONS: MenuOption[] = ['Empezar', 'Elegir VW', 'Configuración'];

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

    this.add
      .text(GAME_WIDTH / 2, 36, 'VW T3 ADVENTURE', {
        fontFamily: 'Poppins, sans-serif',
        fontStyle: 'italic bold',
        fontSize: '20px',
        color: '#ffffff',
        stroke: '#000000',
        strokeThickness: 4,
      })
      .setOrigin(0.5);

    this.pressStartText = this.add
      .text(GAME_WIDTH / 2, GAME_HEIGHT - 30, 'PULSA UNA TECLA', {
        fontFamily: 'Fredoka, sans-serif',
        fontSize: '12px',
        color: '#ffffff',
        stroke: '#000000',
        strokeThickness: 3,
      })
      .setOrigin(0.5);

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
  }

  private showOptions(): void {
    this.showingOptions = true;
    this.pressStartText.destroy();

    MENU_OPTIONS.forEach((label, i) => {
      const text = this.add
        .text(GAME_WIDTH / 2, 100 + i * 20, label, {
          fontFamily: 'Fredoka, sans-serif',
          fontStyle: 'bold',
          fontSize: '14px',
          color: '#ffffff',
          stroke: '#000000',
          strokeThickness: 3,
        })
        .setOrigin(0.5)
        .setInteractive({ useHandCursor: true });

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
      this.scene.start('Play');
    }
    // 'Elegir VW' y 'Configuración': pendientes de implementar.
  }
}
