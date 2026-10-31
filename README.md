# BlockWorld

Prototipo de mundo voxel en Godot 4.7.2. Este repositorio contiene el proyecto completo y la documentación de diseño y fases.

## Abrir y ejecutar

1. Abre `project.godot` con Godot 4.7.2.
2. La escena principal configurada es `res://scenes/main.tscn`.
3. En el entorno Codex donde se desarrolló el proyecto, se puede ejecutar sin depender de las teclas F del portátil mediante el Godot MCP:

   - Proyecto: `C:\Users\Albert\Documents\BlockWorld`
   - Escena principal: omitir el parámetro de escena en `run_project`.
   - Runner acumulado: pasar `res://tests/test_runner.tscn` como escena.

La carpeta `.godot/` es caché local y está excluida de Git. Godot la recrea al abrir el proyecto.

## Estado actual

- Fases 1, 2 y 3 completadas hasta M3.12; M4.01, M4.02 y M4.03 también están completos.
- El mundo que se muestra desde `main.tscn` usa datos de una cuadrícula fija de 5×5 chunks planos y solo malla los 9 chunks interiores (48×48 bloques). No hay terreno procedural, agua visible, árboles, cuevas ni carga dinámica.
- Siguiente hito según el plan: **M4.04 — Capas del terreno** en `docs/BW_05_FASE_4_terreno.md`.
- El usuario informa que la ventana del juego se ve gris. Aunque los tests de asignación de atlas/UV pasaron antes, **la visualización con textura no está confirmada para el usuario**. No afirmar que el terreno aparece texturizado hasta resolverlo y comprobarlo de verdad.
- El runner acumulado pasó sus comprobaciones hasta M4.01 después de los cambios de rendimiento. Aparecen tres `push_error` deliberados de M2.03 al comprobar accesos inválidos; no hubo fallos de test. La escena principal también arranca sin errores en la salida del Godot MCP.

## Rendimiento del mallado

Medición de `ChunkMesher.build` en la escena de prueba 3×3 de chunks planos; es tiempo de mallado por chunk, no el tiempo total de generación del mundo:

- Referencia antes de optimizar: aproximadamente 324 ms/chunk.
- Dos ejecuciones posteriores: 33.722 y 34.276 ms/chunk (aprox. 9.5× menos que la referencia).

Las optimizaciones recorren directamente el array compacto de bloques, cachean los arrays de chunks vecinos, usan tablas de acceso por id de bloque y evalúan inline la visibilidad de caras. La cifra no incluye la generación futura de relieve, árboles o cuevas.

## Documentación del proyecto

- `docs/BW_01_NUCLEO.md`: contrato y convenciones principales.
- `docs/BW_02_PROGRESS.md`: registro del estado implementado, mediciones y problemas abiertos; actualizarlo al completar cada hito.
- `docs/BW_03_FASES_1-2_base_y_datos.md` a `docs/BW_09_FASES_9-10_guardado_y_ambiente.md`: plan detallado por fases.

Los documentos de fases describen el diseño previsto; `BW_02_PROGRESS.md` y el código describen el estado real. Si una descripción visual antigua contradice lo que informa el usuario, verificar antes de darla por buena.

## Continuación recomendada

1. Retomar por M4.01 según `docs/BW_05_FASE_4_terreno.md`.
2. Mantener `docs/BW_02_PROGRESS.md` actualizado.
3. Usar Godot MCP para ejecutar el juego o el runner en este equipo si las teclas F no están disponibles.
4. No cerrar el problema visual de la pantalla gris hasta comprobar las texturas en la ventana real.
