# BlockWorld — Fases 1 y 2: proyecto base y datos de bloques

> **Qué pasar a ChatGPT junto con este archivo:** `BW_01_NUCLEO.md` y tu `BW_02_PROGRESS.md` actualizado.
> Pide un milestone cada vez (`HAZ Mx.xx`). Si el milestone toca código que ya existe, pega también esos archivos completos.
> Cuando un milestone cita "3.4", "3.8", etc., son secciones de `BW_01_NUCLEO.md`.

---

## FASE 1 — Proyecto base

### M1.01 — Crear el proyecto
- **Hacer:** Proyecto nuevo llamado `BlockWorld`, renderer Forward+ (o Compatibility). Crear `scenes/main.tscn` con un `Node3D` raíz llamado `Main` y fijarla como escena principal (Proyecto → Configuración → Aplicación → Run → Main Scene). Añadir `.gitignore` con `.godot/`.
- **Hecho cuando:** F5 abre una ventana gris sin errores ni advertencias en el Depurador.

### M1.02 — Estructura de carpetas
- **Hacer:** Crear exactamente las carpetas y archivos de 3.5. Cada `.gd` vacío contiene solo su `class_name` (o `extends Node` para autoloads) y `extends` correcto. `tests/test_runner.tscn` con nodo raíz `Node` y script `test_runner.gd`.
- **Hecho cuando:** F5 sigue sin errores; no hay scripts con errores de parseo (icono rojo en el panel de archivos).
- **Ojo:** un `class_name` no puede repetirse ni coincidir con un autoload.

### M1.03 — Clase `Const`
- **Hacer:** Crear `const.gd` con **todas** las constantes de 3.2, tal cual.
- **Hecho cuando:** En `main.gd` (`_ready`) un `print(Const.CHUNK_SIZE, " ", Const.CHUNK_HEIGHT)` imprime `16 64`.

### M1.04 — Autoload `InputSetup`
- **Hacer:** Registrar autoload `InputSetup`. En `_ready()` crear cada acción de 3.7 con `InputMap.add_action` + `InputEventKey` (con `physical_keycode`) / `InputEventMouseButton` (`button_index`). Si la acción ya existe, no duplicarla.
- **Hecho cuando:** Una línea de depuración imprime `InputMap.has_action("move_forward")` → `true` para las 25 acciones; pulsar W imprime `move_forward` al comprobar `Input.is_action_pressed`.
- **Ojo:** rueda del ratón = `MOUSE_BUTTON_WHEEL_UP` / `MOUSE_BUTTON_WHEEL_DOWN`.

### M1.05 — Escena principal construida por código
- **Hacer:** `main.gd` crea en `_ready()`: `DirectionalLight3D` (rotación −50° en X), `WorldEnvironment` con `Environment` (fondo `BG_COLOR` azul cielo `Color(0.53, 0.75, 0.95)`), y una `Camera3D` en `(0, 3, 6)` mirando al origen.
- **Hecho cuando:** F5 muestra fondo azul, sin errores.

### M1.06 — `Coords` + primeros tests
- **Hacer:** Implementar `Coords` (3.6) con `floori`/`posmod`. Crear `test_runner.gd` con función `_check(cond: bool, name: String)` que imprime `PASS`/`FAIL`.
- **Casos de test obligatorios** (`world_to_chunk` / `world_to_local`, solo eje X; el Z es idéntico):

| wx | chunk | local |
|---|---|---|
| 0 | 0 | 0 |
| 15 | 0 | 15 |
| 16 | 1 | 0 |
| 31 | 1 | 15 |
| −1 | −1 | 15 |
| −16 | −1 | 0 |
| −17 | −2 | 15 |
| −32 | −2 | 0 |

  Además: `pos_to_block(Vector3(-0.1, 5.9, 3.0)) == Vector3i(-1, 5, 3)`; `pos_to_block(Vector3(0.0, 0.0, -0.0001)) == Vector3i(0, 0, -1)`.
- **Hecho cuando:** F6 sobre `test_runner.tscn` imprime `PASS` en todos los casos (8 filas × chunk y local × ejes X y Z = 32 comprobaciones, más las 2 de `pos_to_block`) y ningún `FAIL`.

### M1.07 — Cubo de prueba
- **Hacer:** En `main.gd`, un `MeshInstance3D` con `BoxMesh` 1×1×1 en `(0.5, 0.5, 0.5)` (para que su esquina mínima sea `(0,0,0)`), material unshaded rojo.
- **Hecho cuando:** Se ve un cubo rojo desde la cámara.

### M1.08 — Cámara libre temporal
- **Hacer:** Script `fly_camera.gd` (temporal, en `scripts/util/`, se borrará en Fase 5) sobre la `Camera3D`: ratón capturado al empezar (`Input.mouse_mode = Input.MOUSE_MODE_CAPTURED`), rotación con `event.relative * Const.MOUSE_SENSITIVITY` (yaw sobre el propio nodo, pitch con clamp ±89°), WASD horizontal, Espacio sube, Shift baja, velocidad 10 b/s. Esc libera el ratón.
- **Hecho cuando:** Puedes rodear el cubo sin que la cámara se incline lateralmente (sin roll) y no puedes dar la vuelta al mirar arriba/abajo.

### M1.09 — Etiqueta de depuración mínima
- **Hacer:** `CanvasLayer` + `Label` arriba a la izquierda con FPS y posición de la cámara (2 decimales). `toggle_debug` (F3) la oculta/muestra.
- **Hecho cuando:** F3 alterna; la posición cambia al moverte.


---

## FASE 2 — Datos de bloques y chunks

### M2.01 — `Blocks`
- **Hacer:** `blocks.gd` con las 12 constantes de id, `enum Face`, un `const DEFS: Dictionary` con las propiedades de la tabla 3.4 y las funciones `is_opaque`, `is_solid`, `name_of`, `tile_for_face`.
- **Casos de test (añadir al runner):** `is_opaque(STONE)==true`; `is_opaque(LEAVES)==false`; `is_opaque(GLASS)==false`; `is_opaque(AIR)==false`; `is_solid(WATER)==false`; `is_solid(LEAVES)==true`; `name_of(5)=="planks"`; `tile_for_face(GRASS, Face.TOP)==0`, `(GRASS, Face.BOTTOM)==2`, `(GRASS, Face.NORTH)==1`; `tile_for_face(LOG, Face.TOP)==7`, `(LOG, Face.EAST)==6`.
- **Hecho cuando:** todos `PASS`.

### M2.02 — `ChunkData`
- **Hacer:** `blocks` = `PackedByteArray` de 16384 elementos a 0. `static index(x,y,z)`, `get_block`, `set_block` según 3.6.
- **Casos de test:** `index(0,0,0)==0`; `index(15,0,0)==15`; `index(0,0,15)==240`; `index(0,1,0)==256`; `index(15,63,15)==16383`; `blocks.size()==16384`; tras `set_block(3,10,5,STONE)`, `get_block(3,10,5)==STONE` y `get_block(3,10,6)==AIR`.
- **Hecho cuando:** todos `PASS`.

### M2.03 — Protección de límites
- **Hacer:** `get_block` con `y<0` o `y>=64` devuelve `AIR`; con `x` o `z` fuera de `0..15` hace `push_error` y devuelve `AIR`. `set_block` fuera de rango hace `push_error` y no escribe. `set_block` solo marca `modified`/`mesh_version` si el valor realmente cambia.
- **Casos de test:** `get_block(0,64,0)==AIR`; `get_block(0,-1,0)==AIR`; `set_block(0,100,0,STONE)` no cambia el array (comparar `blocks` antes/después); set del mismo valor no incrementa `mesh_version`.
- **Hecho cuando:** todos `PASS` (los `push_error` esperados aparecen una vez cada uno y están etiquetados `# DEBUG-M2.03`).

### M2.04 — Chunk plano de prueba
- **Hacer:** Función `ChunkData.fill_flat()` (temporal): `y=0` bedrock, `y=1..17` stone, `y=18..19` dirt, `y=20` grass, resto aire.
- **Hecho cuando:** test: nº de bloques ≠ AIR = `16*16*21 = 5376`; `get_block(8,20,8)==GRASS`; `get_block(8,21,8)==AIR`.

### M2.05 — `World` básico con diccionario de chunks
- **Hacer:** `World` con `var chunks: Dictionary` (`Vector2i -> ChunkData`), `get_block`, `set_block`, `get_chunk_data`, `is_chunk_loaded` (semántica en 3.6). `set_block` convierte con `Coords` y marca el `ChunkData` correspondiente.
- **Casos de test:** con chunks `(0,0)` y `(-1,0)` cargados: `set_block(-1,5,0,STONE)` → `chunks[(-1,0)].get_block(15,5,0)==STONE` y `get_block(-1,5,0)==STONE`; `get_block(-1,5,0)` con el chunk `(-1,0)` descargado devuelve `AIR`; `get_block(0,-5,0)==BEDROCK`; `get_block(0,64,0)==AIR`.
- **Hecho cuando:** todos `PASS`.
