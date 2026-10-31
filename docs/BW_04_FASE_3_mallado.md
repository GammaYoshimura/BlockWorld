# BlockWorld — Fase 3: mallado

> **Qué pasar a ChatGPT junto con este archivo:** `BW_01_NUCLEO.md` y tu `BW_02_PROGRESS.md` actualizado.
> Pide un milestone cada vez (`HAZ Mx.xx`). Si el milestone toca código que ya existe, pega también esos archivos completos.
> Cuando un milestone cita "3.4", "3.8", etc., son secciones de `BW_01_NUCLEO.md`.

---

## FASE 3 — Mallado (aquí aparece el primer mundo visible)

### M3.01 — Un solo quad
- **Hacer:** En `main.gd`, construir a mano un `ArrayMesh` con la cara TOP de un bloque en `(0,0,0)` usando la tabla 3.8 (4 vértices, 6 índices). Material unshaded verde, `cull_mode = CULL_BACK`.
- **Hecho cuando:** El quad se ve desde arriba y **desaparece al mirarlo desde abajo**. Si ocurre al revés, el winding está mal.

### M3.02 — `MeshBuilder`
- **Hacer:** Clase `MeshBuilder` con arrays `PackedVector3Array vertices/normals`, `PackedVector2Array uvs`, `PackedColorArray colors`, `PackedInt32Array indices`. `add_face(local_pos, face, tile, brightness)` usa la tabla 3.8 y el cálculo de UV de 3.4. `to_arrays()` devuelve el `Array` con `ARRAY_MAX` huecos rellenados.
- **Casos de test:** tras 1 cara: 4 vértices, 4 normales, 4 uvs, 4 colores, 6 índices; tras 2 caras: 8 vértices y los índices 6..11 son `[4,5,6,4,6,7]`; `face_count()==2`; `is_empty()` es `true` antes de añadir. **Test geométrico:** para las 6 caras, `(b−a)×(c−a) == −normal` en ambos triángulos.
- **Hecho cuando:** todos `PASS`.

### M3.03 — Cubo completo
- **Hacer:** Mostrar un cubo en `(0,0,0)` añadiendo las 6 caras con `MeshBuilder`, tile fijo 3, brillo de la tabla.
- **Hecho cuando:** Se ve un cubo con caras más claras arriba y más oscuras abajo; desde dentro (atravesando con la cámara) no se ve nada.

### M3.04 — Mallar un chunk plano (vecinos = aire)
- **Hacer:** `ChunkMesher.build(data, {})` recorre `x,y,z`; por cada bloque ≠ AIR, para cada una de las 6 caras mira el vecino con `data.get_block` (si el vecino cae fuera del chunk en X/Z, de momento = `AIR`; si `y<0` = `AIR`), aplica `_face_visible` (3.8) y añade la cara. Bloques con `Blocks.WATER` van a `"water"`, el resto a `"solid"`.
- **Casos de test (chunk de M2.04, sin vecinos):** `solid.face_count()==1856` (256 arriba + 256 abajo + `4*16*21=1344` laterales) → 7424 vértices y 11136 índices; `water.is_empty()==true`.
- **Hecho cuando:** `PASS`.

### M3.05 — Mallado con vecinos y suelo del mundo
- **Hacer:** `ChunkMesher.build` consulta el `Dictionary neighbors` (claves `Vector2i` de offset) cuando `x`/`z` salen de `0..15`. Si falta un vecino, trata esa dirección como `AIR`. Para `y<0` el vecino es **sólido** (no se genera la cara inferior del mundo).
- **Casos de test (chunk plano):** con 4 vecinos planos iguales → `face_count()==256` (solo el techo). Con 3 vecinos (falta el `(1,0)`) → `256 + 16*21 = 592`. Sin vecinos → `256 + 1344 = 1600`.
- **Hecho cuando:** los 3 casos `PASS`.

### M3.06 — `Chunk` node y aplicar el mesh
- **Hacer:** `Chunk` (Node3D) con hijos `SolidMesh` y `WaterMesh` (`MeshInstance3D`). `apply_mesh(result)` crea `ArrayMesh` con `add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)` solo si el builder no está vacío; asigna `custom_aabb = AABB(Vector3.ZERO, Vector3(16, 64, 16))`. `position = Coords.chunk_origin(coord)`.
- **Hecho cuando:** 3×3 chunks planos (usar `fill_flat`) forman un plano continuo de 48×48 bloques sin huecos ni costuras visibles; al girar la cámara ningún chunk parpadea ni desaparece.

### M3.07 — Material compartido
- **Hacer:** `BlockMaterials.solid()` devuelve (cacheado, `static var`) un `StandardMaterial3D`: `shading_mode = SHADING_MODE_UNSHADED`, `vertex_color_use_as_albedo = true`, `texture_filter = TEXTURE_FILTER_NEAREST`, `transparency = TRANSPARENCY_ALPHA_SCISSOR`, `alpha_scissor_threshold = 0.5`, `cull_mode = CULL_BACK`. De momento sin textura (blanco).
- **Hecho cuando:** test: dos chunks distintos devuelven el **mismo** `get_instance_id()` de material.

### M3.08 — Atlas procedural
- **Hacer:** `AtlasBuilder.build() -> ImageTexture`: imagen 256×256 RGBA8; para cada tile de la lista 3.4, rellenar 16×16 px con un color base y variación de brillo pseudoaleatoria **determinista** (hash simple de `x,y,tile`). Reglas: `grass_side` = `dirt` con las 4 filas superiores verdes; `log_top` con anillos concéntricos; `leaves` con ~25 % de píxeles `alpha=0`; `glass` con borde de 1 px opaco claro y centro `alpha=0`; `water` azul semitransparente. Guardar `user://atlas_debug.png` con `save_png`.
- **Hecho cuando:** abres `atlas_debug.png` y ves los 13 tiles en las posiciones esperadas (fila 0, columnas 0-12), el resto transparente.

### M3.09 — UVs reales
- **Hacer:** Asignar la textura del atlas al material (`albedo_texture`). Usar `Blocks.tile_for_face` en el mesher.
- **Hecho cuando:** En el terreno plano ves césped arriba; el cubo de pruebas con hierba muestra tira verde en los laterales; mirando el suelo a lo lejos no hay líneas oscuras entre bloques.
- **Ojo:** si ves líneas entre bloques, `UV_EPSILON` no se aplicó.

### M3.10 — Sombreado por cara (vertex color)
- **Hacer:** Pasar el brillo de la tabla 3.8 como color de vértice. Confirmar que el material es unshaded (la luz direccional ya no influye).
- **Hecho cuando:** Cada bloque se distingue visualmente por cara: techo claro, norte/sur medios, este/oeste más oscuros, abajo el más oscuro.

### M3.11 — Regla de cara visible con transparentes
- **Hacer:** Implementar `_face_visible` exactamente como 3.8.
- **Casos de test:** `(STONE,AIR)=true`; `(STONE,STONE)=false`; `(STONE,GLASS)=true`; `(GLASS,STONE)=false`; `(GLASS,GLASS)=false`; `(GLASS,AIR)=true`; `(LEAVES,LEAVES)=false`; `(LEAVES,STONE)=false`; `(WATER,AIR)=true`; `(WATER,WATER)=false`; `(WATER,STONE)=false`; `(STONE,WATER)=true`; `(WATER,GLASS)=true`.
- **Hecho cuando:** 13 `PASS`.

### M3.12 — Medir el mallado
- **Hacer:** Medir con `Time.get_ticks_usec()` cuánto tarda `ChunkMesher.build` y mostrarlo en el overlay debug (`mesh ms`). Solo informativo.
- **Hecho cuando:** el chunk plano tarda < 15 ms. (Anotarlo en `BW_02_PROGRESS.md`.)
