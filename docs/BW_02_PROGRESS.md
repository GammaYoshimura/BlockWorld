# PROGRESS — BlockWorld

Versión de Godot: 4.7.2.stable.official.ed1daf0bf
Fecha última actualización: 2026-10-31

## Estado de sesión
- MCP de Godot conectado; editor abierto para este proyecto.
- Proyecto inspeccionado: base creada, sin scripts ni escenas previos; `.gitignore` ya excluye `.godot/`.
- M1.01 verificado desde Godot MCP: proyecto iniciado en Forward+ (D3D12, AMD Radeon Vega 8); salida de depuración sin errores (`errors: []`) ni advertencias visibles.

## Milestones completados
- [x] M1.01 — Crear el proyecto (escena principal configurada y ejecución comprobada sin errores ni advertencias).
- [x] M1.02 — Estructura de carpetas (archivos del contrato creados; escaneo headless, F5 y escena `tests/test_runner.tscn` sin errores).
- [x] M1.03 — Clase `Const` (constantes de la sección 3.2 añadidas; Godot imprimió `16 64` sin errores).
- [x] M1.04 — Autoload `InputSetup` (las 24 acciones listadas en 3.7 imprimieron `true`; la salida de depuración también registró `move_forward` al pulsar W).
- [x] M1.05 — Escena principal construida por código (luz direccional, fondo azul y cámara creados; captura visual comprobada y salida sin errores).
- [x] M1.06 — `Coords` + primeros tests (34 comprobaciones PASS en F6; ningún FAIL ni error/aviso).
- [x] M1.07 — Cubo de prueba (cubo rojo unshaded visible en la cámara).
- [x] M1.08 — Cámara libre temporal (el usuario confirmó que funciona; pendiente retirar en Fase 5 según el plan).
- [x] M1.09 — Etiqueta de depuración mínima (usuario confirmó que F3 muestra/oculta la etiqueta de FPS y posición).
- [x] M2.01 — `Blocks` (implementados los 12 ids, `Face`, `DEFS` y funciones; los 12 casos imprimieron PASS).
- [x] M2.02 — `ChunkData` (array de 16384 bytes, índice y acceso implementados; los 8 casos imprimieron PASS).
- [x] M2.03 — Protección de límites (todos los casos imprimieron PASS; los tres `push_error` previstos aparecieron una vez cada uno con etiqueta `DEBUG-M2.03`).
- [x] M2.04 — Chunk plano de prueba (`fill_flat()` genera 5376 bloques no vacíos; recuento y celdas Y=20/Y=21 pasaron).
- [x] M2.05 — `World` básico con diccionario de chunks (los siete casos imprimieron PASS, incluidos chunks negativos, descarga y límites verticales).
- [x] M3.01 — Un solo quad (`ArrayMesh` manual con 4 vértices y 6 índices TOP; material verde unshaded con `CULL_BACK`; Godot MCP confirmó visibilidad desde arriba y desaparición desde abajo; sin errores).
- [x] M3.02 — `MeshBuilder` (arrays de vértices, normales, UV, colores e índices; seis geometrías de cara y winding comprobados; UV con `UV_EPSILON`; todos los casos acumulados imprimieron PASS).
- [x] M3.03 — Cubo completo (las seis caras se generan con `MeshBuilder`, tile 3 y brillos de la tabla; comprobado desde fuera con la cara superior más clara y desde dentro sin caras visibles).
- [x] M3.04 — Mallar un chunk plano (`ChunkMesher.build` genera 1856 caras, 7424 vértices y 11136 índices para el chunk de prueba; el builder de agua queda vacío; todos los casos M3.04 imprimieron PASS).
- [x] M3.05 — Mallado con vecinos y suelo del mundo (los casos con cuatro vecinos, tres vecinos y sin vecinos dieron 256, 592 y 1600 caras; sin cara inferior expuesta).
- [x] M3.06 — `Chunk` node y aplicar el mesh (`SolidMesh` y `WaterMesh` aplican sus `ArrayMesh`; nueve chunks planos forman en ejecución una superficie continua de 48×48 bloques sin costuras visibles).
- [x] M3.07 — Material compartido (`BlockMaterials.solid()` cachea el material configurado; prueba PASS confirma que dos chunks distintos comparten su `get_instance_id()`).
- [x] M3.08 — Atlas procedural (13 tiles en fila 0, 256×256 RGBA8; pruebas de variación y transparencia PASS; `atlas_debug.png` abierto y verificado visualmente).
- [x] M3.09 — UVs reales (atlas asignado; `ChunkMesher` usa `Blocks.tile_for_face`; pruebas de selección de tile y asignación del atlas PASS. La visualización actual sigue pendiente de confirmación: el usuario informa que ve la pantalla gris).
- [x] M3.10 — Sombreado por cara (los colores de vértice coinciden con la tabla de brillo para las seis caras; material unshaded verificado).
- [x] M3.11 — Regla de cara visible con transparentes (la tabla completa de visibilidad pasó los 13 casos del contrato).
- [x] M3.12 — Medir el mallado (tiempo promedio de construcción calculado sobre los 9 chunks y expuesto en el overlay debug; medición optimizada estable: 33.7–34.3 ms/chunk, frente a 324.13 ms iniciales).

## Fase 4 — Mundo y terreno
- [x] M4.01 — Gestor de chunks estático (`World.ensure_chunk` crea/reutiliza datos y nodo; `World.remesh` espera los cuatro vecinos; el caso 5×5 malló solo los 9 chunks interiores y dejó el borde sin malla).
- [x] M4.02 — `WorldGenerator` determinista (`generate(cx,cz)` retorna un `ChunkData` independiente con coordenadas y marca `generated`; misma semilla/coordenada produce los mismos bloques; se extendió con terreno en M4.03–M4.04).
- [x] M4.03 — Mapa de alturas con FastNoiseLite Simplex Smooth + FBM (semilla 12345; barrido 256×256 dentro de Y=14..42; cruces X=15/16 y -1/0 continuos en ≤3 bloques; llamadas repetidas deterministas).
- [x] M4.04 — Capas de terreno integradas en el generador y `World`: bedrock, stone, dirt, hierba y tres capas superiores de arena en playas. El barrido 3×3 comprobó todas las capas, superficie y aire sobre el terreno; encontró playa y césped; chunks generados quedan `modified=false`.
- [x] M4.05 — Agua generada desde `h+1` hasta `SEA_LEVEL` cuando `h < SEA_LEVEL`; se encontró y verificó una columna con `h = SEA_LEVEL-3` y el bloque sobre el mar permanece en aire.
- [x] M4.06 — Material de agua azul, semitransparente, unshaded y compartido en `WaterMesh`; pruebas PASS para 6 caras aisladas, 10 en dos bloques contiguos, 5 con piedra debajo y configuración del material.
- [x] M4.07 — Árboles deterministas con hash entero propio por semilla/coordenadas, troncos de 4–6 bloques y copa de cuatro capas. Pruebas PASS: orden de generación, presencia de troncos y cada hoja del 3×3 a Chebyshev ≤3 de un tronco (el barrido usa una corona de chunks para verificar árboles que cruzan bordes).
- [x] M4.08 — Ruido FastNoiseLite 3D a frecuencia 0.05 y semilla `world_seed + 1` talla aire en `5 <= y < h-4`; el barrido 3×3 encontró cuevas y verificó que bedrock/superficie permanecen intactos.
- [x] M4.09 — Carga dinámica síncrona centrada en la cámara: radio `render_distance+1` para datos y `render_distance` para meshes, colas ordenadas por distancia y máximo 1 chunk de datos + 1 mesh por frame. Pruebas con distancia 2: 29 datos, 13 mallas, centro primero, sin duplicados.
- [x] M4.10 — Descarga más allá de `render_distance+UNLOAD_MARGIN`; los datos modificados pasan a `modified_chunks` y se restauran al volver. Pruebas recorrieron ~300 bloques: datos/nodos acotados y sincronizados.
- [x] M4.11 — `GameSettings.world_seed` se resuelve una vez: 0 genera un valor aleatorio persistente en sesión; `World` lo entrega a `WorldGenerator`. Pruebas PASS en tres coordenadas (misma semilla = mismos bloques; otra semilla = mundo distinto).

## Fase 5 — Jugador
- [x] M5.01 — `Player` construye cápsula de colisión (`radius=0.3`, `height=1.8`), pivote `Head` a altura de ojos y `Camera3D`; la escena principal usa al jugador como objetivo del streaming y ya no crea la cámara libre. Usuario confirma que ve el mundo desde esta cámara.
- [x] M5.02 — Mirada con ratón; ratón capturado al iniciar, giro horizontal en `Player`, vertical en `Head` limitado a ±89°; Esc libera y clic recaptura. Usuario confirmó que funciona.
- [x] M5.03 — Movimiento horizontal con `Input.get_vector`, velocidad objetivo `WALK_SPEED` (4.3) normalizada también en diagonal, aceleración suelo/aire 60/20 y frenado al soltar.
- [x] M5.04 — Gravedad `32 m/s²` limitada a `-60`, velocidad vertical descendente anulada al tocar suelo.
- [x] M5.05 — Cada chunk crea `StaticBody3D` con trimesh de la malla sólida (agua excluida), colisión por ambos lados y colisión activa dentro de `COLLISION_RADIUS`; el usuario confirmó que ya no cae.
- [ ] M5.06 — Salto confirmado (altura teórica 1.27 bloques); añadido auto-paso de hasta `Const.AUTO_STEP_HEIGHT=1.0`, que comprueba espacio libre y suelo antes de mover al jugador. Pendiente comprobar en juego el escalón de 1 bloque y el límite de 2.
- [ ] M5.07 — Sprint y agacharse.
- [x] M5.08 — Aparece sobre `height_at(0,0)` y mantiene la física desactivada hasta tener colisiones en radio 2; muestra «Generando mundo…» durante la carga. Implementado junto con M5.05 para evitar caídas durante el inicio.
- [ ] M5.09 — Modo vuelo.
- [ ] M5.10 — Reaparición.
- [ ] M5.11 — Cámara.

## Desviaciones del contrato (si las hay, aprobadas por el humano)
- M1.04: el criterio menciona 25 acciones, pero la lista de la sección 3.7 enumera 24; se implementaron las 24 enumeradas, sin inventar una acción.

## Archivos existentes (ruta · propósito · último milestone que lo tocó)
- `res://project.godot` · configuración, escena principal y autoloads `GameSettings`/`InputSetup` · M4.11
- `res://scenes/main.tscn` · escena raíz `Main` (Node3D) con script `main.gd` · M1.02
- `res://scripts/main.gd` · crea entorno, jugador con spawn gating y overlay de estado · M5.08
- `res://scripts/util/fly_camera.gd` · cámara libre temporal sobre `Camera3D` · M1.08
- `res://scripts/autoload/game_settings.gd` · semilla de mundo persistente para la sesión · M4.11
- `res://scripts/autoload/input_setup.gd` · registro de acciones de entrada y comprobación temporal · M1.04
- `res://scripts/util/const.gd` · constantes del contrato · M1.03
- `res://scripts/util/blocks.gd` · ids, propiedades y consultas de bloques con tablas de acceso rápido por id · M3.12
- `res://scripts/util/coords.gd` · conversiones entre bloques, chunks y coordenadas locales · M1.06
- `res://scripts/util/atlas_builder.gd` · clase `AtlasBuilder` con atlas procedural y export PNG · M3.08
- `res://scripts/util/block_materials.gd` · materiales sólidos y de agua compartidos · M4.06
- `res://scripts/world/chunk_data.gd` · array de bloques, índices, acceso, protección y relleno plano temporal · M2.04
- `res://scripts/world/mesh_builder.gd` · clase `MeshBuilder` con geometría, UV, colores e índices para caras; buffers predefinidos para evitar arrays temporales por cara · M3.12
- `res://scripts/world/chunk_mesher.gd` · clase `ChunkMesher` optimizada para acceso directo a bytes y caras expuestas · M3.12
- `res://scripts/world/world_generator.gd` · `WorldGenerator(world_seed)`, mapa de alturas, capas, agua, árboles y cuevas deterministas · M4.11
- `res://scripts/world/chunk.gd` · nodo `Chunk` con mallas y colisión trimesh opcional · M5.05
- `res://scripts/world/world.gd` · streaming, colisiones cercanas, espera de colisiones para spawn y semilla de `GameSettings` · M5.08
- `res://scripts/world/voxel_raycast.gd` · clase `VoxelRaycast` · M1.02
- `res://scripts/world/save_manager.gd` · clase `SaveManager` · M1.02
- `res://scripts/player/player.gd` · jugador con cámara, movimiento horizontal y gravedad · M5.04
- `res://scripts/player/block_interaction.gd` · clase `BlockInteraction` · M1.02
- `res://scripts/player/block_highlight.gd` · clase `BlockHighlight` · M1.02
- `res://scripts/ui/hud.gd` · clase `Hud` · M1.02
- `res://scripts/ui/hotbar.gd` · clase `Hotbar` · M1.02
- `res://scripts/ui/debug_overlay.gd` · clase `DebugOverlay` · M1.02
- `res://scripts/ui/pause_menu.gd` · clase `PauseMenu` · M1.02
- `res://scripts/ui/main_menu.gd` · clase `MainMenu` · M1.02
- `res://tests/test_runner.tscn` · escena `Node` del runner · M1.02
- `res://tests/test_runner.gd` · runner con casos de M1.06, M2.01 a M2.05, M3.02, M3.04, M3.05, M3.07 a M3.11 y M4.01 a M4.11 · M4.11
- `res://.gitignore` · exclusión de `.godot/` · proyecto base
- `res://icon.svg` · icono del proyecto · proyecto base

## Métricas
- render_distance = 6 · FPS: N/D · mesh ms (chunk plano de prueba, media 3×3): 34.00 (34.276 y 33.722 ms en dos ejecuciones consecutivas; referencia inicial: 324.127 ms, reducción aproximada de 9.5×).

## Optimización de mallado posterior a M3
- Se recorren directamente los bytes compactos del chunk y se cachean los arrays de bloques vecinos, evitando llamadas repetidas a `ChunkData.get_block` y consultas al diccionario por voxel.
- Las tablas de opacidad, solidez y tiles de `Blocks` usan arrays indexados por id en vez de búsquedas en diccionarios durante el mallado.
- La visibilidad de las seis caras se evalúa inline en el bucle caliente. Dos ejecuciones midieron 33.722 y 34.276 ms por chunk para la misma escena de nueve chunks planos.

## Problemas abiertos
- La escena principal todavía se ve gris para el usuario, aunque atlas, UV y materiales están asignados y sus pruebas pasan; falta identificar por qué el render en su pantalla no muestra las texturas.
