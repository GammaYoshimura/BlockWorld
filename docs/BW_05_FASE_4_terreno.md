# BlockWorld — Fase 4: mundo y terreno

> **Qué pasar a ChatGPT junto con este archivo:** `BW_01_NUCLEO.md` y tu `BW_02_PROGRESS.md` actualizado.
> Pide un milestone cada vez (`HAZ Mx.xx`). Si el milestone toca código que ya existe, pega también esos archivos completos.
> Cuando un milestone cita "3.4", "3.8", etc., son secciones de `BW_01_NUCLEO.md`.

---

## FASE 4 — Mundo y terreno

### M4.01 — Gestor de chunks estático
- **Hacer:** `World.ensure_chunk(cx,cz)`: crea `ChunkData` (de momento `fill_flat`), lo guarda en `chunks`, crea el nodo `Chunk`. `World.remesh(c)`: solo mallar un chunk cuando existen datos de **sus 4 vecinos**.
- **Hecho cuando:** pidiendo datos de un cuadrado 5×5 se mallan los 3×3 interiores; el borde exterior de 5×5 no tiene mesh. Se ve un plano 48×48.

### M4.02 — `WorldGenerator` determinista
- **Hacer:** `WorldGenerator(world_seed)` con `generate(cx,cz)` **puro** (sin tocar nada fuera de sí mismo). De momento devuelve el chunk plano.
- **Casos de test:** `generate(3,-2).blocks == generate(3,-2).blocks` (misma semilla); con dos semillas distintas, el resultado será distinto cuando existe ruido (re-comprobar en M4.03).
- **Hecho cuando:** `PASS`.

### M4.03 — Mapa de alturas con ruido
- **Hacer:** En `WorldGenerator`, `FastNoiseLite` con `noise_type = TYPE_SIMPLEX_SMOOTH`, `frequency = 0.01`, `fractal_type = FRACTAL_FBM`, `fractal_octaves = 4`, `seed = world_seed`. `height_at(wx,wz) = clampi(Const.BASE_HEIGHT + roundi(noise.get_noise_2d(wx, wz) * Const.HEIGHT_AMPLITUDE), 4, 60)`. **El ruido se evalúa con coordenadas de mundo, nunca locales.**
- **Casos de test:** semilla 12345: `height_at` siempre entre 14 y 42 en un barrido de 256×256; `abs(height_at(15,0) - height_at(16,0)) <= 3`; `abs(height_at(-1,0) - height_at(0,0)) <= 3`; `height_at(7,9)` devuelve lo mismo en dos llamadas.
- **Hecho cuando:** `PASS`; se ve un terreno ondulado sin escalones en los bordes de chunk.

### M4.04 — Capas del terreno
- **Hacer:** Por columna con altura `h`: `y=0` bedrock; `1..h-4` stone; `h-3..h-1` dirt; `y=h` grass. Si `h <= SEA_LEVEL + 2`: el bloque superior y los 2 de debajo son `SAND`.
- **Casos de test:** en un barrido de 3×3 chunks, para cada columna: `get_block(x,0,z)==BEDROCK`; el bloque en `y=h` es `GRASS` o `SAND`; todos los bloques en `0..h` son ≠ AIR; todos en `h+1..63` son AIR (todavía sin agua ni árboles).
- **Hecho cuando:** `PASS`; se ven playas en las zonas bajas.

### M4.05 — Agua
- **Hacer:** Rellenar con `WATER` desde `h+1` hasta `SEA_LEVEL` cuando `h < SEA_LEVEL`.
- **Hecho cuando:** test: en una columna con `h = SEA_LEVEL-3`, bloques `h+1..SEA_LEVEL` son `WATER` y `SEA_LEVEL+1` es AIR. Visual: lagos/mar al nivel 24.

### M4.06 — Mallado del agua
- **Hacer:** El mesher ya separa `"water"`. `BlockMaterials.water()`: unshaded, `transparency = TRANSPARENCY_ALPHA`, `albedo_color = Color(0.2, 0.4, 0.9, 0.6)`, `cull_mode = CULL_BACK`, `texture_filter` nearest. **Sin colisión.** No bajar la altura de la superficie.
- **Casos de test (chunk vacío con vecinos vacíos, bloques colocados a mano):** un bloque de agua aislado rodeado de aire → `water.face_count()==6`; dos bloques de agua contiguos en X rodeados de aire → `10`; un bloque de agua con `STONE` justo debajo y aire alrededor → `5`.
- **Hecho cuando:** los 3 casos `PASS`; ves el fondo a través del agua y no hay caras entre bloques de agua contiguos.

### M4.07 — Árboles deterministas
- **Hacer:** Árbol en la columna `(wx,wz)` si: terreno `GRASS`, `h > SEA_LEVEL + 2`, y `rng.randf() < 0.012` donde `rng` es un `RandomNumberGenerator` local con `rng.seed = hash_combo(world_seed, wx, wz)` (función de mezcla entera propia, no `hash()` de Variant). Tronco de 4 a 6 `LOG`; copa de `LEAVES`: dos capas de 5×5 (menos esquinas) + dos de 3×3, el tronco atraviesa la copa. **Al generar un chunk, recorrer las columnas del chunk ampliado en 2 bloques por cada lado**, decidir qué árboles nacen allí y escribir solo los bloques que caen dentro del chunk. No sobrescribir bloques que no sean AIR (excepto `LEAVES`).
- **Casos de test:** generar los chunks `(0,0)`,`(1,0)` en ese orden y luego `(1,0)`,`(0,0)` en orden inverso → bloques idénticos; con misma semilla, 2 generaciones → mismos árboles; toda hoja tiene un tronco a distancia de Chebyshev ≤ 3 (comprobación con un barrido de 3×3 chunks).
- **Hecho cuando:** `PASS`; visualmente los árboles que cruzan una frontera de chunk están completos.

### M4.08 — Cuevas
- **Hacer:** Segundo `FastNoiseLite` (3D): `frequency = 0.05`, seed `world_seed + 1`. Tallar (poner AIR) donde `noise.get_noise_3d(wx,y,wz) > 0.55` y `5 <= y < h - 4`.
- **Casos de test:** para todas las columnas de 3×3 chunks, el bloque `y=h` sigue siendo el original (la superficie no se agujerea); `y=0` sigue siendo BEDROCK.
- **Hecho cuando:** `PASS`; se ven cuevas al cavar/volar bajo tierra.

### M4.09 — Carga dinámica alrededor del jugador (síncrona)
- **Hacer:** Cada frame calcular el chunk del jugador (o de la cámara libre); si cambió, calcular el conjunto necesario `{(dx,dz) : dx²+dz² <= R²}` con `R = render_distance + 1` para generar **datos** y `R = render_distance` para **mallar** (así siempre existen los vecinos), y encolar los que faltan **ordenados por distancia**. Procesar **como máximo 1 chunk de datos y 1 mesh por frame**.
- **Hecho cuando:** volando en línea recta se cargan chunks por delante sin parones largos; `get_child_count()` de los nodos `Chunk` = nº de entradas de meshes cargados (sin duplicados).

### M4.10 — Descarga con histéresis
- **Hacer:** Descargar chunks cuya distancia > `render_distance + UNLOAD_MARGIN` (`queue_free()` y `erase` del diccionario). Los chunks con `modified == true` **no se descartan**: se conservan en una lista `modified_chunks` en memoria (se guardarán en Fase 9).
- **Hecho cuando:** tras volar 300 bloques, `Performance.get_monitor(Performance.OBJECT_NODE_COUNT)` se estabiliza (no crece indefinidamente).

### M4.11 — Semilla
- **Hacer:** `GameSettings.world_seed` (int). `WorldGenerator` la recibe. Valor 0 o vacío = aleatoria (`randi()`).
- **Hecho cuando:** misma semilla → mismo mundo (comparar 3 coordenadas); semilla distinta → mundo distinto.
