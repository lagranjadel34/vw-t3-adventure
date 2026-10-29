# Contexto del proyecto (resumen del chat inicial)

- Juego indie "VW T3 Adventure V1": top-down estilo GTA 1, pixel art.
- Guion: ciudad caótica -> salir en la VW T3 -> bosque -> spot -> acampar -> FIN.
- Stack: Phaser 3 + TypeScript + Vite. Meta: PWA en Vercel y APK Android (Capacitor).
- Coste/tokens mínimos: arte hecho a mano con Gemini (Nano Banana) + limpieza en Aseprite/Piskel; sin subagentes de gráficos por API. Sin búsquedas web salvo necesidad.
- Sprite T3 V1 (hecho por Ara, vista cenital, verde con ventanas azules, ~30x60 px): referencia en docs/t3_v1_referencia.jpg. Falta el PNG limpio con fondo transparente en public/assets/sprites/t3_base.png.
- Hitos en docs/HITOS.md. Hitos 1, 2 y 3 completados (base, furgoneta controlable, menú con fondo del campamento, fuego animado y estrella fugaz).
- Hito 4 en marcha: Intro — presentación de la historia antes de entrar a jugar (ciudad caótica -> sale en la VW T3 -> bosque).
- Idea de diseño futura (post-lanzamiento del juego jugable): el jugador podrá elegir entre varias camperizaciones de la VW T3 (vanagon, caravelle, etc.) como skins seleccionables. No es hito activo todavía, pero el sistema de sprites del Van debería permitir swap de textura fácilmente.
- Repo GitHub: lagranjadel34/vw-t3-adventure. Despliegue online pendiente (Vercel aún no conectado al repo, lo retomará Ara desde casa).
- Preferencias de Ara: respuestas concisas, pasos accionables, solo lo modificado, en español.
