# BlockWorld — Fases 6 y 7: interacción con bloques e interfaz

> **Qué pasar a ChatGPT junto con este archivo:** `BW_01_NUCLEO.md` y tu `BW_02_PROGRESS.md` actualizado.
> Pide un milestone cada vez (`HAZ Mx.xx`). Si el milestone toca código que ya existe, pega también esos archivos completos.
> Cuando un milestone cita "3.4", "3.8", etc., son secciones de `BW_01_NUCLEO.md`.

---

## FASE 6 — Interacción con bloques

### M6.01 — `VoxelRaycast` (DDA, Amanatides & Woo)
- **Hacer:** Algoritmo: celda inicial `cell = Vector3i(floori(o.x), floori(o.y), floori(o.z))`; por cada eje: `step = sign(dir)`; `t_delta = abs(1/dir)` (si `dir == 0` → `INF`); `t_max` = distancia hasta la primera frontera en ese eje. Bucle: avanzar en el eje con menor `t_max`, guardar la `normal` (eje avanzado con signo contrario a `step`), mirar el bloque de esa celda; saltar `AIR` y `WATER`; parar al superar `max_dist`. Devolver `prev` = celda anterior al impacto.
- **Casos de test** (mundo vacío salvo `STONE` en `(0,0,0)`, usar un `World` falso o un `Callable`):

| origen | dirección | max | resultado |
|---|---|---|---|
| (0.5, 5.5, 0.5) | (0,−1,0) | 10 | hit, block (0,0,0), normal (0,1,0), dist 4.5 |
| (5.5, 0.5, 0.5) | (−1,0,0) | 10 | hit, normal (1,0,0), dist 4.5 |
| (−3.5, 0.5, 0.5) | (1,0,0) | 10 | hit, normal (−1,0,0), dist 3.5 |
| (0.5, 0.5, −3.5) | (0,0,1) | 10 | hit, normal (0,0,−1) |
| (0.5, 5.5, 0.5) | (0,−1,0) | 3 | no hit |
| (0.5, 5.5, 0.5) | (0,1,0) | 10 | no hit |
| (3.5, 3.4, 3.6) | (−1,−1,−1) normalizado | 10 | hit, block (0,0,0), normal (0,0,1), dist ≈ 4.50 |

- **Hecho cuando:** 7 `PASS`.
- **Ojo:** el origen puede estar con coordenadas negativas: usar `floori`.

### M6.02 — Resaltado del bloque apuntado
- **Hacer:** `BlockHighlight` (MeshInstance3D) con `ArrayMesh` de líneas (`PRIMITIVE_LINES`, 12 aristas = 24 vértices) de un cubo de `-0.002` a `1.002`, material unshaded negro. Cada frame: lanzar el raycast desde la cámara (`-camera.global_transform.basis.z`, `PLAYER_REACH`); posicionarlo en `block` (esquina mínima); ocultarlo si no hay impacto.
- **Hecho cuando:** el contorno aparece solo en bloques a ≤ 5 y no hace z-fighting.

### M6.03 — Romper bloque
- **Hacer:** `break_block` (clic izq.) con ratón capturado: `world.set_block(hit, AIR)`, excepto `BEDROCK`.
- **Hecho cuando:** el bloque desaparece; no se puede romper bedrock; `ChunkData.modified == true`.

### M6.04 — Remallado del chunk y vecinos
- **Hacer:** `World.set_block` marca como "dirty" el chunk del bloque y, si el bloque está en un borde (`local x == 0` → `(-1,0)`; `x == 15` → `(1,0)`; `z == 0` → `(0,-1)`; `z == 15` → `(0,1)`), también ese vecino. El remallado se hace en el siguiente `_process` (1 vez por chunk aunque haya varias ediciones).
- **Casos de test:** romper `wx=15` marca `(0,0)` y `(1,0)`; `wx=16` marca `(1,0)` y `(0,0)`; `wx=0` marca `(0,0)` y `(-1,0)`; `wx=-1` marca `(-1,0)` y `(0,0)`; un bloque interior (`wx=8,wz=8`) marca solo su chunk; un bloque en la esquina local `(0,*,0)` marca 3 chunks.
- **Hecho cuando:** `PASS`; romper en una frontera no deja agujeros ni caras ausentes en el chunk contiguo.

### M6.05 — Colocar bloque
- **Hacer:** `place_block` (clic der.): celda = `prev` del raycast. Rechazar si: `y` fuera de `0..63`; el AABB del jugador (`x±0.3`, `y..y+1.8`, `z±0.3`) intersecta con el AABB del bloque `[pos, pos+1]`; la celda actual no es `AIR` ni `WATER`. Colocar el bloque del slot seleccionado.
- **Hecho cuando:** no puedes colocar un bloque dentro de ti; saltando y mirando abajo puedes subir en torre ("pillar jump") sin que el bloque se coloque dentro del cuerpo.

### M6.06 — Lógica de hotbar
- **Hacer:** `selected: int (0-8)`, `slots: Array[int]` con el contenido por defecto 3.4. `hotbar_next/prev` (con wrap), `hotbar_1..9`.
- **Hecho cuando:** imprimir el id seleccionado al cambiar; colocar usa el id seleccionado.

### M6.07 — Pick block
- **Hacer:** `pick_block` sobre un bloque: si está en la hotbar, selecciona ese slot; si no, sustituye el slot seleccionado por ese id.
- **Hecho cuando:** funciona con bloques dentro y fuera de la hotbar.

### M6.08 — Repetición al mantener
- **Hacer:** Al mantener el botón, primera acción inmediata y luego cada `ACTION_REPEAT_SECONDS`. Solo si hay impacto y el ratón está capturado.
- **Hecho cuando:** mantener el clic rompe un bloque cada 0.25 s.

### M6.09 — Ediciones sobreviven a la descarga
- **Hacer:** Cuando un chunk modificado se descarga (fuera de rango), su `ChunkData` va a `modified_chunks`; si se vuelve a necesitar, se usa ese en lugar de regenerar.
- **Hecho cuando:** rompes un bloque, te alejas hasta que se descarga, vuelves: el hueco sigue.


---

## FASE 7 — Interfaz

### M7.01 — Mira
- **Hacer:** `CanvasLayer` + `Control` a pantalla completa con dos rectángulos finos (blanco con contorno negro) centrados.
- **Hecho cuando:** centrada al redimensionar la ventana a 3 tamaños distintos.

### M7.02 — Hotbar visual
- **Hacer:** 9 slots de 48 px abajo-centro; slot seleccionado con borde marcado. Icono de cada bloque = `TextureRect` con `AtlasTexture` (región del tile **lateral**, para `GRASS` el tile top), `texture_filter` nearest, escalado entero.
- **Hecho cuando:** los iconos corresponden al bloque; rueda/teclas mueven la selección.

### M7.03 — Overlay F3 completo
- **Hacer:** FPS, ms por frame, XYZ del jugador, bloque XYZ, chunk XZ, dirección (N/S/E/W), nombre del bloque apuntado, chunks cargados, tareas pendientes, último tiempo de mallado, semilla.
- **Hecho cuando:** todos los valores se actualizan y coinciden con la realidad (p. ej. `chunk` cambia exactamente al cruzar `x=16`).

### M7.04 — Menú de pausa
- **Hacer:** Esc → `get_tree().paused = true`, ratón visible, panel con "Continuar" y "Salir". El panel tiene `process_mode = PROCESS_MODE_ALWAYS`. Continuar/Esc → reanuda y recaptura el ratón.
- **Hecho cuando:** el mundo se congela y se reanuda sin que el jugador salga disparado.

### M7.05 — Menú principal
- **Hacer:** `main_menu.tscn`: "Nuevo mundo" (campo de semilla, vacío = aleatoria), "Salir". Guarda en `GameSettings` y hace `change_scene_to_file("res://scenes/main.tscn")`.
- **Hecho cuando:** semilla `12345` produce el mismo mundo en 2 arranques.

### M7.06 — Distancia de renderizado
- **Hacer:** Slider 2-12 en pausa; aplica en vivo `GameSettings.render_distance` (afecta a carga/descarga y `far` de la cámara).
- **Hecho cuando:** al cambiar, el nº de chunks cargados converge al nuevo valor en pocos segundos.
