import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '../config/constants';
import {
  INTRO_PANELS,
  INTRO_TYPE_DELAY_MS,
  INTRO_AUTO_ADVANCE_MS,
  INTRO_FADE_MS,
  INTRO_TEXT_BOX_HEIGHT,
  INTRO_TEXT_PADDING,
} from '../config/intro';

export class IntroScene extends Phaser.Scene {
  private panelIndex = 0;
  private panelLayer!: Phaser.GameObjects.Container;
  private narration!: Phaser.GameObjects.Text;
  private typeEvent?: Phaser.Time.TimerEvent;
  private advanceEvent?: Phaser.Time.TimerEvent;
  private typing = false;
  private finished = false;
  private transitioning = false;

  constructor() {
    super('Intro');
  }

  create(): void {
    this.panelIndex = 0;
    this.finished = false;

    this.panelLayer = this.add.container(0, 0);

    const boxY = GAME_HEIGHT - INTRO_TEXT_BOX_HEIGHT;
    this.add.rectangle(0, boxY, GAME_WIDTH, INTRO_TEXT_BOX_HEIGHT, 0x000000).setOrigin(0, 0);

    this.narration = this.add.text(INTRO_TEXT_PADDING, boxY + INTRO_TEXT_PADDING, '', {
      fontFamily: 'Fredoka, sans-serif',
      fontSize: '12px',
      color: '#ffffff',
      wordWrap: { width: GAME_WIDTH - INTRO_TEXT_PADDING * 2 },
    });

    this.add
      .text(GAME_WIDTH - 4, 4, 'ESC: saltar', {
        fontFamily: 'Fredoka, sans-serif',
        fontSize: '8px',
        color: '#ffffff',
      })
      .setOrigin(1, 0)
      .setAlpha(0.6);

    const keyboard = this.input.keyboard!;
    keyboard.on('keydown-SPACE', () => this.handleAdvance());
    keyboard.on('keydown-ENTER', () => this.handleAdvance());
    keyboard.on('keydown-ESC', () => this.finish());
    this.input.on('pointerdown', () => this.handleAdvance());

    this.showPanel();
  }

  private showPanel(): void {
    this.transitioning = false;
    const panel = INTRO_PANELS[this.panelIndex];
    this.panelLayer.removeAll(true);

    const panelHeight = GAME_HEIGHT - INTRO_TEXT_BOX_HEIGHT;
    this.panelLayer.add(this.add.rectangle(0, 0, GAME_WIDTH, panelHeight, panel.bgColor).setOrigin(0, 0));

    for (const s of panel.shapes) {
      this.panelLayer.add(this.add.rectangle(s.x, s.y, s.w, s.h, s.color).setOrigin(0, 0));
      if (s.label) {
        this.panelLayer.add(
          this.add
            .text(s.x + s.w / 2, s.y + s.h / 2, s.label, {
              fontFamily: 'Fredoka, sans-serif',
              fontSize: '8px',
              color: '#ffffff',
              stroke: '#000000',
              strokeThickness: 2,
            })
            .setOrigin(0.5),
        );
      }
    }

    this.cameras.main.fadeIn(INTRO_FADE_MS);
    this.typeText(panel.text);
  }

  private typeText(full: string): void {
    this.typing = true;
    this.narration.setText('');
    this.advanceEvent?.remove();

    let i = 0;
    this.typeEvent = this.time.addEvent({
      delay: INTRO_TYPE_DELAY_MS,
      repeat: full.length - 1,
      callback: () => {
        i++;
        this.narration.setText(full.slice(0, i));
        if (i === full.length) this.onTypingDone();
      },
    });
  }

  private onTypingDone(): void {
    this.typing = false;
    this.advanceEvent = this.time.delayedCall(INTRO_AUTO_ADVANCE_MS, () => this.nextPanel());
  }

  private handleAdvance(): void {
    if (this.finished || this.transitioning) return;
    if (this.typing) {
      // Primera pulsación: completa el texto de golpe.
      this.typeEvent?.remove();
      this.narration.setText(INTRO_PANELS[this.panelIndex].text);
      this.onTypingDone();
      return;
    }
    this.nextPanel();
  }

  private nextPanel(): void {
    if (this.finished) return;
    this.advanceEvent?.remove();

    if (this.panelIndex >= INTRO_PANELS.length - 1) {
      this.finish();
      return;
    }

    this.panelIndex++;
    this.transitioning = true;
    this.cameras.main.fadeOut(INTRO_FADE_MS);
    this.cameras.main.once(Phaser.Cameras.Scene2D.Events.FADE_OUT_COMPLETE, () => this.showPanel());
  }

  private finish(): void {
    if (this.finished) return;
    this.finished = true;
    this.typeEvent?.remove();
    this.advanceEvent?.remove();
    this.cameras.main.fadeOut(INTRO_FADE_MS);
    this.cameras.main.once(Phaser.Cameras.Scene2D.Events.FADE_OUT_COMPLETE, () => this.scene.start('Play'));
  }
}
