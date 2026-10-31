# BlockWorld — Fase 8: rendimiento (hilos)

> **Qué pasar a ChatGPT junto con este archivo:** `BW_01_NUCLEO.md` y tu `BW_02_PROGRESS.md` actualizado.
> Pide un milestone cada vez (`HAZ Mx.xx`). Si el milestone toca código que ya existe, pega también esos archivos completos.
> Cuando un milestone cita "3.4", "3.8", etc., son secciones de `BW_01_NUCLEO.md`.

---

## FASE 8 — Rendimiento (hilos)

> Antes de empezar: anota en `BW_02_PROGRESS.md` FPS y `mesh ms` con `render_distance = 6` en la versión síncrona.

### M8.01 — Cola de resultados segura
- **Hacer:** Clase de cola con `Mutex`: los workers hacen `push(result)`, el hilo principal hace `pop_all()` en `_process`.
- **Hecho cuando:** test con 100 pushes desde `WorkerThreadPool` y 100 resultados leídos, sin pérdidas ni duplicados.

### M8.02 — Generación de datos en hilos
- **Hacer:** `WorkerThreadPool.add_task(callable)` genera `ChunkData` con `WorldGenerator`. El worker **no toca nodos ni el diccionario `chunks`**. El hilo principal inserta el resultado.
- **Hecho cuando:** cruzar 10 fronteras con R=8 no produce ningún frame > 25 ms; el terreno generado es idéntico al síncrono (comparar `blocks` de 3 chunks).
- **Ojo:** si hay cuelgues, crear un `FastNoiseLite` por tarea.

### M8.03 — Mallado en hilos
- **Hacer:** El worker ejecuta `ChunkMesher.build` y devuelve los `MeshBuilder`/arrays. Cada tarea guarda el `mesh_version` del chunk y de los vecinos usados. Al volver, si algún `mesh_version` cambió, **se descarta** y se vuelve a encolar.
- **Hecho cuando:** romper/colocar bloques rápidamente mientras se generan chunks no provoca errores ni meshes obsoletos.

### M8.04 — Presupuesto de aplicación
- **Hacer:** El hilo principal aplica como máximo 1 mesh por frame **o** hasta 3 ms de trabajo (lo que ocurra primero).
- **Hecho cuando:** sin tirones al cargar.

### M8.05 — Colisión por radio
- **Hacer:** Crear la forma trimesh solo para chunks dentro de `COLLISION_RADIUS`; destruirla al salir del radio + 1.
- **Hecho cuando:** el recuento de `CollisionShape3D` activos ≈ `π·3²`; la colisión existe al entrar en el radio antes de pisar el chunk.

### M8.06 — Prioridad y cancelación
- **Hacer:** La cola de trabajo se ordena por distancia al jugador; las tareas de chunks que ya salieron de rango se ignoran al terminar.
- **Hecho cuando:** al correr 10 s en línea recta, ningún chunk detrás del jugador (a distancia > R+2) permanece cargado.

### M8.07 — Cierre limpio
- **Hacer:** En `_exit_tree` esperar con `WorkerThreadPool.wait_for_task_completion(id)` por todas las tareas vivas.
- **Hecho cuando:** cerrar el juego no imprime errores.

### M8.08 — Objetivo de rendimiento
- **Hacer:** Con `R = 8` en tu PC: 60 FPS estables caminando; sin picos > 25 ms. Anotar hardware y resultados.
- **Hecho cuando:** se cumplen o se documentan los cuellos de botella con datos del Profiler de Godot.

### M8.09 — (Opcional) Greedy meshing
- **Hacer:** Solo si M8.08 no se cumple. Detrás de `const USE_GREEDY := false`. Mantener el mesher simple como referencia y tests que comparen **área total de caras** entre ambos.
- **Hecho cuando:** misma área visual, menos vértices.
