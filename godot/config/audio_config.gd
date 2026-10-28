class_name AudioConfig
## Sonido sintetizado en el juego (provisional hasta tener grabaciones): motor, caja, ambiente.

const MIX_RATE := 22050
const GAIN_MAX := 32767.0

# --- Motor bóxer de 4 cilindros (4 tiempos: 2 explosiones por vuelta) ---
const FIRES_PER_REV := 2.0
# Bucle base: un periodo entero de muestras para que el bucle no tenga corte.
const ENGINE_PERIOD_SAMPLES := 550 # ≈ 40 Hz de explosiones a MIX_RATE
const ENGINE_LOOP_PERIODS := 24
# Cada explosión: golpe que decae, armónicos y algo de ruido de escape.
const ENGINE_PULSE_DECAY := 5.0 # más alto = golpe más seco
const ENGINE_HARMONICS: Array[float] = [1.0, 0.55, 0.3, 0.18] # 1º, 2º, 3º, 4º armónico
const ENGINE_NOISE := 0.35
# Bóxer irregular: cada cilindro empuja un poco distinto (patrón de 4 explosiones).
const ENGINE_CYLINDER_GAIN: Array[float] = [1.0, 0.82, 0.93, 0.76]
const ENGINE_GAIN := 0.8
const ENGINE_IDLE_RPM := 900.0
const ENGINE_REDLINE_RPM := 4800.0
const ENGINE_RPM_LERP := 8.0 # 1/s, lo rápido que suben o bajan las vueltas
# Durante el cambio (embrague pisado) las vueltas caen hacia esta fracción.
const ENGINE_CLUTCH_RPM_RATIO := 0.55
const ENGINE_IDLE_DB := -10.0
const ENGINE_GAS_DB := -2.0 # acelerando
const ENGINE_COAST_DB := -7.0 # rodando sin acelerar
const ENGINE_DB_LERP := 6.0

# --- Clac de la palanca. Holgura de la caja: 1 = de serie (gastada), 0 = arreglada en taller ---
const CLACK_RING_HZ: Array[float] = [1750.0, 2630.0]
const CLACK_RING_S := 0.07
const CLACK_RING_GAIN := 0.4
const CLACK_RING_DECAY := 5.0
const CLACK_GAIN := 1.0
const CLACK_TICK_S := 0.012
# Con holgura: rascado antes de entrar y golpe más grave y largo ("cuesta entrar").
const CLACK_GRIND_S := 0.16
const CLACK_GRIND_BUZZ_HZ := 70.0
const CLACK_GRIND_GAIN := 0.45
const CLACK_CLONK_HZ := 140.0
const CLACK_CLONK_S := 0.12
const CLACK_CLONK_GAIN := 0.7
const CLACK_CLONK_DECAY := 4.0
const CLACK_DB := -4.0
const CLACK_PITCH_JITTER := 0.06

# --- Ambiente: ciudad caótica -> campo en silencio con pájaros ---
const CITY_LOOP_S := 3.0
const CITY_CROSSFADE_S := 0.4
const CITY_RUMBLE_SMOOTH := 0.02 # ruido marrón: más bajo = más grave
const CITY_SWELL_PER_LOOP := 3 # coches que pasan en cada bucle (subidas de volumen)
const CITY_SWELL_DEPTH := 0.5
const CITY_GAIN := 0.9
const CITY_DB := -9.0
const HORN_HZ: Array[float] = [415.0, 523.0] # dos tonos, como un claxon de coche
const HORN_GAIN := 0.3 # por tono
const HORN_ATTACK_S := 0.01
const HORN_S := Vector2(0.18, 0.5) # mín, máx
const HORN_DELAY_S := Vector2(1.5, 5.0)
const HORN_DB := -14.0
const HORN_PITCH := Vector2(0.85, 1.15)
const HORN_VARIANTS := 3
# Avión que pasa por encima de vez en cuando (Sevilla tiene aeropuerto al lado).
const PLANE_S := 9.0
const PLANE_RUMBLE_SMOOTH := 0.01 # rugido grave (ruido marrón)
const PLANE_WHINE_HZ := Vector2(950.0, 720.0) # silbido de turbina al acercarse, al alejarse (Doppler)
const PLANE_WHINE_GAIN := 0.08
const PLANE_PEAK_AT := 0.45 # fracción del paso en la que está justo encima
const PLANE_GAIN := 0.9
const PLANE_DELAY_S := Vector2(25.0, 60.0)
const PLANE_DB := -10.0
const PLANE_PITCH := Vector2(0.9, 1.1)
const BIRD_CHIRP_HZ := Vector2(2600.0, 4600.0) # barrido de cada pío
const BIRD_GAIN := 0.7
const BIRD_TOP_MIN := 0.6 # cada pío llega al menos a esta fracción del barrido
const BIRD_CHIRP_S := 0.06
const BIRD_GAP_S := 0.05
const BIRD_CHIRPS := Vector2i(2, 5)
const BIRD_VARIANTS := 4
const BIRD_DELAY_S := Vector2(0.8, 3.5)
const BIRD_DB := -12.0
const BIRD_PITCH := Vector2(0.85, 1.2)
# Viento de montaña (pantalla de paso al campo): ruido marrón muy suave con rachas.
const WIND_LOOP_S := 4.0
const WIND_SMOOTH := 0.004 # más bajo = más grave
const WIND_GUSTS_PER_LOOP := 1
const WIND_GUST_DEPTH := 0.6
const WIND_GAIN := 0.8
# Por debajo de este volumen (lineal) una capa se considera apagada.
const LAYER_SILENT := 0.02
# Campo según la distancia a la salida de la ciudad (en el mapa de Sevilla: la A-4).
const COUNTRY_FADE_PX := 900.0
const AMBIENT_LERP := 1.5

# --- Configuración > Sonido ---
const SETTINGS_FILE := "user://ajustes.cfg"
const VOLUME_STEPS := 10
const VOLUME_DEFAULT := 8
