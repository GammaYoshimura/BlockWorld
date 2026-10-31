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

- Fases 1–4 completas; Fase 5 implementada salvo la comprobación del respawn tras una caída. El usuario confirmó salto, auto-salto, sprint, agacharse y vuelo. El spawn inicial y el respawn buscan una columna despejada y esperan colisiones cercanas antes de activar física. Más adelante, el vuelo quedará limitado a modo creativo u objetos especiales.
- El mundo de `main.tscn` carga terreno procedural alrededor de la cámara del jugador. Genera como máximo un chunk de datos y una malla por frame; descarga chunks a distancia y conserva los modificados en memoria. Incluye agua, árboles, cuevas y semilla de sesión.
- Fase 6: M6.01–M6.06 confirmados y M6.09 implementado. Pick block y repetición al mantener clic añadidos; falta comprobarlos. Fase 7 implementada: mira, hotbar visual, overlay F3, pausa, menú inicial con semilla y slider de distancia de renderizado; pendientes de confirmación de uso.
- Fase 8: cola de resultados con `Mutex` y generación de chunks en `WorkerThreadPool` implementadas; falta validar equivalencia y estabilidad bajo carga.
- Las hojas usan transparencia recortada con un patrón pseudoaleatorio mezclado para evitar artefactos diagonales repetitivos.
- La escena principal arranca sin errores en la salida del Godot MCP. El jugador no activa la física hasta que las colisiones cercanas están listas. La colocación de bloques permite contacto exacto bajo los pies para apilar; falta confirmar en juego el caso de saltar, colocar y aterrizar sobre ese bloque.

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

1. Confirmar M6.07–M6.08 y continuar con la Fase 7 según `docs/BW_07_FASES_6-7_interaccion_e_interfaz.md`.
2. Mantener `docs/BW_02_PROGRESS.md` actualizado.
3. Usar Godot MCP para ejecutar el juego o el runner en este equipo si las teclas F no están disponibles.
4. No cerrar el problema visual de la pantalla gris hasta comprobar las texturas en la ventana real.
