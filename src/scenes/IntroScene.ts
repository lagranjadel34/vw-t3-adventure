import Phaser from 'phaser';
import { GAME_WIDTH, GAME_HEIGHT } from '../config/constants';
import { IS_TOUCH } from '../config/device';
import { TAP_MIN_HEIGHT, TAP_PADDING_X } from '../config/touch';
import {
  INTRO_PANELS,
  INTRO_TYPE_DELAY_MS,
  INTRO_AUTO_ADVANCE_MS,
  INTRO_FADE_MS,
  INTRO_TEXT_BOX_HEIGHT,
  INTRO_TEXT_PADDING,
  INTRO_HORN_WORDS,
  INTRO_HORN_INTERVAL_MS,
  INTRO_HORN_RISE_PX,
  INTRO_HORN_LIFE_MS,
  INTRO_HORN_SHAKE_MS,
  INTRO_HORN_SHAKE_INTENSITY,
  INTRO_HAZE_COLOR,
  INTRO_HAZE_MAX_ALPHA,
  INTRO_SMOKE_TEXTURE_SIZE,
  INTRO_SMOKE_TINTS,
  INTRO_SMOKE_FREQUENCY_MS,
  INTRO_SMOKE_LIFE_MS,
  INTRO_SMOKE_SPEED_Y,
  INTRO_SMOKE_SPEED_X,
  INTRO_SMOKE_SCALE,
  INTRO_SMOKE_ALPHA,
  IntroPanel,
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
  private hornEvent?: Phaser.Time.TimerEvent;

  constructor() {
    super('Intro');
  }

  preload(): void {
    for (const panel of INTRO_PANELS) {
      if (panel.image) this.load.image(panel.image.key, panel.image.file);
    }
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

    const skip = this.add
      .text(GAME_WIDTH - TAP_PADDING_X, TAP_MIN_HEIGHT / 2, IS_TOUCH ? 'SALTAR »' : 'SALTAR (ESC) »', {
        fontFamily: 'Fredoka, sans-serif',
        fontSize: '10px',
        color: '#ffffff',
        stroke: '#000000',
        strokeThickness: 2,
      })
      .setOrigin(1, 0.5)
      .setAlpha(0.7);
    skip.setInteractive({
      hitArea: new Phaser.Geom.Rectangle(
        -TAP_PADDING_X,
        (skip.height - TAP_MIN_HEIGHT) / 2,
        skip.width + TAP_PADDING_X * 2,
        TAP_MIN_HEIGHT,
      ),
      hitAreaCallback: Phaser.Geom.Rectangle.Contains,
      useHandCursor: true,
    });
    skip.on('pointerdown', () => this.finish());

    const keyboard = this.input.keyboard!;
    keyboard.on('keydown-SPACE', () => this.handleAdvance());
    keyboard.on('keydown-ENTER', () => this.handleAdvance());
    keyboard.on('keydown-ESC', () => this.finish());
    // Tocar en cualquier sitio (salvo el botón SALTAR) avanza.
    this.input.on('pointerdown', (_p: Phaser.Input.Pointer, over: Phaser.GameObjects.GameObject[]) => {
      if (over.length === 0) this.handleAdvance();
    });

    this.showPanel();
  }

  private showPanel(): void {
    this.transitioning = false;
    const panel = INTRO_PANELS[this.panelIndex];
    this.clearPanelFx();
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

    this.addPanelImage(panel);
    this.addPanelFx(panel);

    this.cameras.main.fadeIn(INTRO_FADE_MS);
    this.typeText(panel.text);
  }

  private clearPanelFx(): void {
    this.hornEvent?.remove();
    this.hornEvent = undefined;
    this.tweens.killAll();
  }

  private addPanelImage(panel: IntroPanel): void {
    const img = panel.image;
    if (!img) return;

    // El escenario (imagen + humo) se mueve y escala como un solo bloque.
    const stage = this.add.container(img.fromX, img.fromY).setScale(img.fromScale);
    stage.add(this.add.image(0, 0, img.key));
    this.panelLayer.add(stage);

    if (img.exhausts) {
      const src = this.textures.get(img.key).getSourceImage();
      this.ensureSmokeTexture();
      for (const [px, py] of img.exhausts) {
        stage.add(this.createExhaust(px - src.width / 2, py - src.height / 2));
      }
    }

    this.tweens.add({
      targets: stage,
      x: img.toX,
      y: img.toY,
      scale: img.toScale,
      duration: img.durationMs,
      ease: 'Sine.easeInOut',
    });
  }

  private ensureSmokeTexture(): void {
    if (this.textures.exists('smoke_puff')) return;
    const r = INTRO_SMOKE_TEXTURE_SIZE / 2;
    const g = this.add.graphics();
    g.fillStyle(0xffffff, 1);
    g.fillCircle(r, r, r);
    g.generateTexture('smoke_puff', INTRO_SMOKE_TEXTURE_SIZE, INTRO_SMOKE_TEXTURE_SIZE);
    g.destroy();
  }

  private createExhaust(x: number, y: number): Phaser.GameObjects.Particles.ParticleEmitter {
    return this.add.particles(x, y, 'smoke_puff', {
      frequency: INTRO_SMOKE_FREQUENCY_MS,
      lifespan: { min: INTRO_SMOKE_LIFE_MS[0], max: INTRO_SMOKE_LIFE_MS[1] },
      speedY: { min: INTRO_SMOKE_SPEED_Y[0], max: INTRO_SMOKE_SPEED_Y[1] },
      speedX: { min: INTRO_SMOKE_SPEED_X[0], max: INTRO_SMOKE_SPEED_X[1] },
      scale: { start: INTRO_SMOKE_SCALE[0], end: INTRO_SMOKE_SCALE[1] },
      alpha: { start: INTRO_SMOKE_ALPHA, end: 0 },
      tint: INTRO_SMOKE_TINTS,
    });
  }

  private addPanelFx(panel: IntroPanel): void {
    if (panel.haze) {
      const haze = this.add
        .rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT - INTRO_TEXT_BOX_HEIGHT, INTRO_HAZE_COLOR, 0)
        .setOrigin(0, 0);
      this.panelLayer.add(haze);
      this.tweens.add({
        targets: haze,
        fillAlpha: INTRO_HAZE_MAX_ALPHA,
        duration: panel.image?.durationMs ?? 4000,
      });
    }

    const horns = panel.horns;
    if (horns) {
      this.hornEvent = this.time.addEvent({
        delay: INTRO_HORN_INTERVAL_MS,
        loop: true,
        callback: () => this.spawnHorn(horns.x, horns.y),
      });
    }
  }

  private spawnHorn(xRange: [number, number], yRange: [number, number]): void {
    const word = Phaser.Utils.Array.GetRandom(INTRO_HORN_WORDS);
    const x = Phaser.Math.Between(xRange[0], xRange[1]);
    const y = Phaser.Math.Between(yRange[0], yRange[1]);

    const text = this.add
      .text(x, y, word, {
        fontFamily: 'Fredoka, sans-serif',
        fontStyle: 'bold',
        fontSize: '10px',
        color: '#ffd24d',
        stroke: '#000000',
        strokeThickness: 3,
      })
      .setOrigin(0.5);
    this.panelLayer.add(text);

    this.tweens.add({
      targets: text,
      y: y - INTRO_HORN_RISE_PX,
      alpha: 0,
      duration: INTRO_HORN_LIFE_MS,
      onComplete: () => text.destroy(),
    });
    this.cameras.main.shake(INTRO_HORN_SHAKE_MS, INTRO_HORN_SHAKE_INTENSITY);
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
    this.clearPanelFx();
    this.cameras.main.fadeOut(INTRO_FADE_MS);
    this.cameras.main.once(Phaser.Cameras.Scene2D.Events.FADE_OUT_COMPLETE, () => this.scene.start('Play'));
  }
}
