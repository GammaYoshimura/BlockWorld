# BlockWorld — NÚCLEO (se pega SIEMPRE al empezar un chat nuevo)

> **Versión de Godot usada en este proyecto:** 4.7.2
> **Lenguaje:** GDScript con tipado estático. **Sin C#, sin addons, sin assets externos.**
> Aquí están las reglas, el contrato de arquitectura y los errores típicos de Godot 4.
> Los milestones están en los archivos `BW_03` a `BW_10`. Cuando un milestone dice "tabla 3.8" o "3.4", se refiere a este archivo.

---

## 2. Reglas de trabajo para la IA (obligatorias)

1. **Un milestone por respuesta.** No adelantes trabajo de milestones futuros, ni "ya que estamos".
2. **Empieza cada respuesta con la lista de archivos** a crear/modificar (ruta completa desde `res://`).
3. **Entrega cada archivo COMPLETO**, desde la primera hasta la última línea. Prohibido `...`, `# resto igual`, `# código anterior`. Cada archivo en su propio bloque de código con la ruta encima.
4. **No modifiques de memoria.** Si necesitas cambiar un archivo que no te he pegado en este chat, pídemelo antes.
5. **El contrato (sección 3) es ley.** No cambies nombres de clases, funciones, constantes, acciones de input ni la estructura de carpetas. Si crees que algo debe cambiar, **para y pregúntame**; no lo cambies por tu cuenta.
6. **No inventes APIs.** Si no estás seguro de que una función/propiedad existe en Godot 4.__, dilo explícitamente y usa la alternativa documentada en este documento.
7. **Tipado estático siempre:** `var x: int = 0`, `func f(a: int) -> void:`, `Array[Vector3i]`, `PackedByteArray`.
8. **Sin números mágicos.** Todo valor de juego sale de `Const` (sección 3.2).
9. **Escenas por código.** Minimiza los `.tscn`. Solo existen los `.tscn` listados en 3.5. Si algo debe hacerse en el editor, dame pasos numerados y literales ("Menú Proyecto → Configuración del proyecto → …").
10. **Sin features no pedidas.** Si el milestone no lo menciona, no lo añadas.
11. **Cada respuesta incluye** (en este orden): `Archivos` → `Código` → `Cómo probar` (pasos exactos) → `Salida esperada` (lo que debo ver/leer en la consola) → `Qué NO debería ocurrir`. Termina con "Esperando confirmación de M x.xx".
12. **Código de depuración etiquetado:** `# DEBUG-Mx.xx` en cada print/assert temporal, para poder borrarlos luego.
13. **Si algo falla, busca la causa raíz.** Prohibido "parchear" con `if` que oculten el síntoma. Si tras 2 intentos no arreglas algo, pide logs.
14. **Nada de hilos hasta la Fase 8.** Antes de esa fase todo es síncrono en el hilo principal.
15. **Nunca toques el árbol de escena desde un hilo.** Solo datos puros en hilos (ver Fase 8).
16. **Un solo `StandardMaterial3D` compartido** para todos los chunks sólidos, y otro para agua. Nunca uno por chunk.
17. **No refactorices** código que ya pasó su milestone salvo que el milestone actual lo pida.
18. **Responde en español.** Comentarios del código en español, identificadores en inglés.

---

## 3. Contrato de arquitectura (decisiones cerradas)

### 3.1 Tecnología

| Tema | Decisión |
|---|---|
| Motor | Godot 4.x (versión indicada arriba) |
| Renderer | Forward+ (si el PC es modesto: Compatibility) |
| Lenguaje | GDScript tipado |
| Mundo | Chunks columna de 16×64×16, infinito en X/Z |
| Bloques | 1 byte por bloque (`PackedByteArray`), ids 0-255 |
| Mallado | Caras visibles con culling, 1 `ArrayMesh` por chunk (+ otro para agua) |
| Colisión del mundo | `ConcavePolygonShape3D` (trimesh) por chunk, solo chunks cercanos |
| Colisión del jugador | `CharacterBody3D` + `CapsuleShape3D` |
| Selección de bloque | Raycast voxel propio (DDA), NO el raycast de física |
| Iluminación | "Falsa": brillo por cara en vertex color + material unshaded |
| Hilos | Solo en Fase 8, con `WorkerThreadPool` |
| Texturas | Atlas procedural generado por código (sustituible por PNG con el mismo layout) |

### 3.2 Constantes — `res://scripts/util/const.gd` (`class_name Const`)

```gdscript
class_name Const

const CHUNK_SIZE: int = 16
const CHUNK_HEIGHT: int = 64
const SEA_LEVEL: int = 24
const BASE_HEIGHT: int = 28
const HEIGHT_AMPLITUDE: int = 14

const ATLAS_TILES: int = 16          # tiles por fila/columna
const TILE_PX: int = 16              # píxeles por tile
const UV_EPSILON: float = 0.0005     # inset para evitar sangrado entre tiles

const DEFAULT_RENDER_DISTANCE: int = 6   # en chunks
const MIN_RENDER_DISTANCE: int = 2
const MAX_RENDER_DISTANCE: int = 12
const UNLOAD_MARGIN: int = 2             # histéresis de descarga
const COLLISION_RADIUS: int = 3          # chunks con colisión alrededor del jugador

const PLAYER_WIDTH: float = 0.6
const PLAYER_HEIGHT: float = 1.8
const PLAYER_EYE_HEIGHT: float = 1.62
const PLAYER_REACH: float = 5.0
const WALK_SPEED: float = 4.3
const SPRINT_SPEED: float = 5.6
const SNEAK_SPEED: float = 1.3
const FLY_SPEED: float = 12.0
const GRAVITY: float = 32.0
const JUMP_VELOCITY: float = 9.0         # ≈ 1.25 bloques de salto
const TERMINAL_VELOCITY: float = 60.0
const MOUSE_SENSITIVITY: float = 0.002
const PITCH_LIMIT_DEG: float = 89.0

const ACTION_REPEAT_SECONDS: float = 0.25
const DAY_LENGTH_SECONDS: float = 1200.0
```

### 3.3 Coordenadas y orden de datos (la fuente nº1 de bugs)

- Ejes Godot: **X derecha, Y arriba, −Z hacia delante**.
- Un bloque en la coordenada entera `(x, y, z)` ocupa el cubo `[x, x+1) × [y, y+1) × [z, z+1)`. **El origen del bloque es su esquina mínima, NO su centro.**
- **Prohibido `int(x / 16)` y `x % 16` con negativos.** Usa siempre:
  - de posición float a bloque: `floori(p.x)`, `floori(p.y)`, `floori(p.z)`
  - de bloque a chunk: `floori(float(wx) / Const.CHUNK_SIZE)`
  - de bloque a local: `posmod(wx, Const.CHUNK_SIZE)`
- Índice dentro de un chunk: `index = x + (z << 4) + (y << 8)` (equivale a `x + z*16 + y*256`). Tamaño total del array: `16*64*16 = 16384`.
- Coordenada de chunk: `Vector2i(cx, cz)`. Posición del nodo `Chunk` = `Vector3(cx*16, 0, cz*16)`. **Los vértices del mesh son locales al chunk (0..16).**

### 3.4 Bloques y atlas

IDs fijos:

| id | Constante | Nombre | Opaco | Sólido (colisión) | Tile top | Tile bottom | Tile lado |
|---|---|---|---|---|---|---|---|
| 0 | `AIR` | air | no | no | — | — | — |
| 1 | `GRASS` | grass | sí | sí | 0 | 2 | 1 |
| 2 | `DIRT` | dirt | sí | sí | 2 | 2 | 2 |
| 3 | `STONE` | stone | sí | sí | 3 | 3 | 3 |
| 4 | `COBBLESTONE` | cobblestone | sí | sí | 4 | 4 | 4 |
| 5 | `PLANKS` | planks | sí | sí | 5 | 5 | 5 |
| 6 | `LOG` | log | sí | sí | 7 | 7 | 6 |
| 7 | `LEAVES` | leaves | **no** | sí | 8 | 8 | 8 |
| 8 | `SAND` | sand | sí | sí | 9 | 9 | 9 |
| 9 | `GLASS` | glass | **no** | sí | 10 | 10 | 10 |
| 10 | `BEDROCK` | bedrock | sí | sí | 11 | 11 | 11 |
| 11 | `WATER` | water | **no** | **no** | 12 | 12 | 12 |

Atlas: 16×16 tiles de 16 px → imagen de 256×256 px. Tile `t`: `col = t % 16`, `row = t / 16` (división entera). UV de esquina superior-izquierda del tile: `u0 = col/16.0 + UV_EPSILON`, `v0 = row/16.0 + UV_EPSILON`; esquina inferior-derecha: `u1 = (col+1)/16.0 - UV_EPSILON`, `v1 = (row+1)/16.0 - UV_EPSILON`.

Tiles: `0 grass_top, 1 grass_side, 2 dirt, 3 stone, 4 cobblestone, 5 planks, 6 log_side, 7 log_top, 8 leaves (con huecos alpha), 9 sand, 10 glass (borde opaco, centro alpha 0), 11 bedrock, 12 water`.

Hotbar por defecto (slots 1-9): `GRASS, DIRT, STONE, COBBLESTONE, PLANKS, LOG, LEAVES, SAND, GLASS` (ids 1..9).

### 3.5 Estructura de carpetas y archivos

```
res://
  project.godot
  scenes/
    main.tscn                 # Node3D raíz, script main.gd
    main_menu.tscn            # (Fase 7) Control raíz, script main_menu.gd
  scripts/
    autoload/
      game_settings.gd        # autoload "GameSettings" (sin class_name)
      input_setup.gd          # autoload "InputSetup"   (sin class_name)
    util/
      const.gd                # class_name Const
      coords.gd               # class_name Coords (static)
      blocks.gd               # class_name Blocks (consts + static)
      atlas_builder.gd        # class_name AtlasBuilder
      block_materials.gd      # class_name BlockMaterials
    world/
      chunk_data.gd           # class_name ChunkData (RefCounted)
      mesh_builder.gd         # class_name MeshBuilder (RefCounted)
      chunk_mesher.gd         # class_name ChunkMesher (static)
      world_generator.gd      # class_name WorldGenerator (RefCounted)
      chunk.gd                # class_name Chunk (Node3D)
      world.gd                # class_name World (Node3D)
      voxel_raycast.gd        # class_name VoxelRaycast (static)
      save_manager.gd         # class_name SaveManager (Fase 9)
    player/
      player.gd               # class_name Player (CharacterBody3D)
      block_interaction.gd    # class_name BlockInteraction (Node)
      block_highlight.gd      # class_name BlockHighlight (MeshInstance3D)
    ui/
      hud.gd, hotbar.gd, debug_overlay.gd, pause_menu.gd, main_menu.gd
  tests/
    test_runner.tscn          # Node con test_runner.gd; se ejecuta con F6
    test_runner.gd
```

**Autoloads:** solo `GameSettings` e `InputSetup`. (Un `class_name` no puede llamarse igual que un autoload.) Todo lo demás son `class_name` con `const`/`static func`, accesibles desde cualquier sitio y desde hilos.

### 3.6 Contrato de APIs

```
Coords (static):
  world_to_chunk(wx: int, wz: int) -> Vector2i
  world_to_local(wx: int, wz: int) -> Vector2i          # (x local, z local)
  pos_to_block(p: Vector3) -> Vector3i                  # floori en cada eje
  chunk_origin(c: Vector2i) -> Vector3

Blocks (static + const):
  AIR, GRASS, DIRT, STONE, COBBLESTONE, PLANKS, LOG, LEAVES, SAND, GLASS, BEDROCK, WATER
  is_opaque(id: int) -> bool
  is_solid(id: int) -> bool
  name_of(id: int) -> String
  tile_for_face(id: int, face: int) -> int              # face: Face enum

enum Face { TOP, BOTTOM, EAST, WEST, SOUTH, NORTH }     # 0..5, definido en Blocks

ChunkData (RefCounted):
  var coord: Vector2i
  var blocks: PackedByteArray        # tamaño 16384
  var generated: bool
  var modified: bool                 # para guardado
  var mesh_version: int              # +1 cada vez que cambia algún bloque
  static index(x: int, y: int, z: int) -> int
  get_block(x: int, y: int, z: int) -> int       # local; y fuera de rango -> AIR
  set_block(x: int, y: int, z: int, id: int) -> void   # local; sube mesh_version y pone modified=true

MeshBuilder (RefCounted):
  add_face(local_pos: Vector3i, face: int, tile: int, brightness: float) -> void
  is_empty() -> bool
  face_count() -> int
  to_arrays() -> Array               # formato ArrayMesh (ARRAY_MAX posiciones)

ChunkMesher (static):
  build(data: ChunkData, neighbors: Dictionary) -> Dictionary
     # neighbors: Vector2i(-1,0),(1,0),(0,-1),(0,1) -> ChunkData
     # return: {"solid": MeshBuilder, "water": MeshBuilder}

WorldGenerator (RefCounted):
  _init(world_seed: int)
  height_at(wx: int, wz: int) -> int
  generate(cx: int, cz: int) -> ChunkData

World (Node3D):
  get_block(wx: int, wy: int, wz: int) -> int
  set_block(wx: int, wy: int, wz: int, id: int) -> void
  get_chunk_data(c: Vector2i) -> ChunkData      # null si no existe
  is_chunk_loaded(c: Vector2i) -> bool

Chunk (Node3D):
  var coord: Vector2i
  var data: ChunkData
  apply_mesh(result: Dictionary) -> void
  set_collision_enabled(enabled: bool) -> void

VoxelRaycast (static):
  cast(world: World, origin: Vector3, dir: Vector3, max_dist: float) -> Dictionary
     # {"hit": bool, "block": Vector3i, "normal": Vector3i, "prev": Vector3i, "distance": float}
```

**Reglas del `World.get_block`:** `y < 0` → `BEDROCK`; `y >= 64` → `AIR`; chunk no cargado con `y` válido → `AIR` (el mesher solo corre cuando los 4 vecinos existen, así que esto no genera caras falsas).

### 3.7 Acciones de input (se registran por código en `InputSetup`)

`move_forward` (W), `move_back` (S), `move_left` (A), `move_right` (D), `jump` (Espacio), `sprint` (Ctrl izq.), `sneak` (Shift izq.), `toggle_fly` (F), `break_block` (clic izq.), `place_block` (clic der.), `pick_block` (clic central), `hotbar_next` (rueda abajo), `hotbar_prev` (rueda arriba), `hotbar_1` … `hotbar_9` (teclas 1-9), `toggle_debug` (F3), `pause` (Esc).

Capas de colisión: **capa 1 = mundo**, **capa 2 = jugador**. El jugador tiene `collision_layer = 2`, `collision_mask = 1`. Los chunks tienen `collision_layer = 1`, `collision_mask = 0`.

### 3.8 Geometría de caras (copiar tal cual, NO recalcular)

Godot considera cara frontal la que se ve en sentido **horario**. Esta tabla ya está verificada. Los vértices se suman a la posición local `(x,y,z)` del bloque. Triángulos: `(v0,v1,v2)` y `(v0,v2,v3)` → índices `[i, i+1, i+2, i, i+2, i+3]` donde `i` = número de vértices ya añadidos.

| Face | Normal | Vecino a comprobar | v0 | v1 | v2 | v3 | Brillo |
|---|---|---|---|---|---|---|---|
| TOP | (0,1,0) | (0,1,0) | (0,1,0) | (1,1,0) | (1,1,1) | (0,1,1) | 1.0 |
| BOTTOM | (0,−1,0) | (0,−1,0) | (0,0,1) | (1,0,1) | (1,0,0) | (0,0,0) | 0.5 |
| EAST (+X) | (1,0,0) | (1,0,0) | (1,1,1) | (1,1,0) | (1,0,0) | (1,0,1) | 0.6 |
| WEST (−X) | (−1,0,0) | (−1,0,0) | (0,1,0) | (0,1,1) | (0,0,1) | (0,0,0) | 0.6 |
| SOUTH (+Z) | (0,0,1) | (0,0,1) | (0,1,1) | (1,1,1) | (1,0,1) | (0,0,1) | 0.8 |
| NORTH (−Z) | (0,0,−1) | (0,0,−1) | (1,1,0) | (0,1,0) | (0,0,0) | (1,0,0) | 0.8 |

**UV para v0..v3 (siempre el mismo orden):** `(u0,v0)`, `(u1,v0)`, `(u1,v1)`, `(u0,v1)`.
**Color del vértice:** `Color(b, b, b, 1.0)` con `b` = brillo de la tabla.

**Autocomprobación de winding** (la IA debe hacerla): para cada triángulo `(a,b,c)`, el producto vectorial `(b−a) × (c−a)` debe ser igual a **−normal**. Si al jugar solo ves las caras "desde dentro" del terreno, el winding está invertido.

**Regla de cara visible** — `_face_visible(id, neighbor_id)`:

```
si neighbor_id == AIR            -> true
si id == neighbor_id             -> false
si Blocks.is_opaque(neighbor_id) -> false
en otro caso                     -> true     # vecino transparente distinto (p. ej. piedra junto a cristal)
```

---

## 4. Errores típicos de Godot 4 que la IA debe evitar

| ❌ No uses (Godot 3 / inventado) | ✅ Usa |
|---|---|
| `onready var`, `export var` | `@onready var`, `@export var` |
| `yield(...)` | `await ...` |
| `connect("sig", obj, "method")` | `sig.connect(callable)` |
| `Spatial`, `MeshInstance`, `Area`, `KinematicBody` | `Node3D`, `MeshInstance3D`, `Area3D`, `CharacterBody3D` |
| `move_and_slide(velocity)` | asignar `velocity` y llamar `move_and_slide()` |
| `OpenSimplexNoise` | `FastNoiseLite` |
| `rand_range`, `deg2rad` | `randf_range`/`randi_range`, `deg_to_rad` |
| `floor(x)` para índices | `floori(x)` (devuelve int) |
| `int(x) / 16`, `x % 16` con negativos | `floori(float(x)/16.0)`, `posmod(x,16)` |
| `Thread` suelto sin `wait_to_finish()` | `WorkerThreadPool.add_task(callable)` |
| Tocar nodos desde un hilo | Devolver datos y aplicarlos en el hilo principal (`_process`) |
| `add_surface_from_arrays` con arrays vacíos | Comprobar `is_empty()` antes; si está vacío, no añadir superficie |
| Olvidar `Mesh.ARRAY_MAX` | `var arrays: Array = []; arrays.resize(Mesh.ARRAY_MAX)` |
| Mezclar `ARRAY_COLOR` con `PackedVector3Array` | `PackedColorArray` para colores, `PackedVector2Array` para UV, `PackedInt32Array` para índices |
| Material por chunk | Un material compartido (`BlockMaterials`) |
| Textura borrosa | `texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST` |
| Chunks que desaparecen al girar la cámara | Asignar `mesh.custom_aabb = AABB(Vector3.ZERO, Vector3(16, 64, 16))` |
| `Image.create(...)` en Godot ≥ 4.3 | `Image.create_empty(...)` (en 4.0-4.2 sigue siendo `Image.create`) |
| Dividir enteros sin aviso | `floori(a / float(b))` o `@warning_ignore("integer_division")` |
| Rotar la cámara con `rotation.z` acumulado | Yaw en el cuerpo (`rotate_y`), pitch en un nodo pivote (`rotation.x` con clamp) |
| `get_node("ruta/larga")` frágil | Guardar referencias al crear los nodos por código |
| `Input.is_action_just_pressed` dentro de `_unhandled_input` sin necesidad | Usar `event.is_action_pressed("accion")` en `_unhandled_input` |

---

## 5. Protocolo de verificación de cada milestone

1. La IA entrega código + "Cómo probar" + "Salida esperada".
2. El humano ejecuta (**F5** = proyecto, **F6** = escena actual, útil para `tests/test_runner.tscn`).
3. Si la salida real ≠ "Hecho cuando" → no se avanza. Se rellena la plantilla de bug.
4. Si pasa → la IA añade el milestone a `BW_02_PROGRESS.md` y se pide el siguiente.
5. **Tests automáticos:** `tests/test_runner.gd` (`extends Node`) ejecuta en `_ready()` todos los tests acumulados e imprime `PASS Mx.xx descripción` / `FAIL Mx.xx descripción`. Cada milestone con casos numéricos **añade sus casos al runner**, nunca crea un runner nuevo. Los tests usan `assert`-style propio (`_check(cond, nombre)`) para no abortar el resto.
