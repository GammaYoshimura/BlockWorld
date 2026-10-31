# BlockWorld — Fases 9 y 10: guardado y ambiente

> **Qué pasar a ChatGPT junto con este archivo:** `BW_01_NUCLEO.md` y tu `BW_02_PROGRESS.md` actualizado.
> Pide un milestone cada vez (`HAZ Mx.xx`). Si el milestone toca código que ya existe, pega también esos archivos completos.
> Cuando un milestone cita "3.4", "3.8", etc., son secciones de `BW_01_NUCLEO.md`.

---

## FASE 9 — Guardado

### M9.01 — Estructura y `world.json`
- **Hacer:** `user://saves/<nombre>/world.json`: `{ "version": 1, "name", "seed", "time_of_day", "player": {"pos":[x,y,z], "yaw", "pitch", "fly"}, "hotbar": [...], "selected" }` con `JSON.stringify`.
- **Hecho cuando:** el archivo existe tras salir y su contenido es correcto.

### M9.02 — Formato de chunk
- **Hacer:** `chunks/<cx>_<cz>.bin`: magia `"BWCH"` (4 bytes) + versión (1 byte) + tamaño original (int32) + `blocks.compress(FileAccess.COMPRESSION_ZSTD)`. Solo se guardan chunks con `modified == true`.
- **Hecho cuando:** un chunk plano modificado ocupa < 2 KB.

### M9.03 — Carga
- **Hacer:** Al generar `(cx,cz)`: si existe archivo, se carga (`decompress(16384, COMPRESSION_ZSTD)`) en lugar de generar.
- **Hecho cuando:** rompes y colocas bloques, sales, reabres: las ediciones persisten; el resto del mundo es idéntico.

### M9.04 — Autoguardado atómico
- **Hacer:** Autoguardado cada 60 s y al salir. Escribir a `*.tmp` y renombrar con `DirAccess.rename_absolute`.
- **Hecho cuando:** matar el proceso a mitad no deja archivos corruptos.

### M9.05 — Tolerancia a corrupción
- **Hacer:** Cabecera/versión inválida o tamaño erróneo → `push_warning`, ignorar archivo, regenerar.
- **Hecho cuando:** corromper a mano un `.bin` no crashea el juego.

### M9.06 — Lista de mundos
- **Hacer:** El menú principal lista las carpetas de `user://saves/`, permite cargar y borrar (con confirmación).
- **Hecho cuando:** crear 2 mundos distintos, cargarlos y borrar uno.


---

## FASE 10 — Ambiente

### M10.01 — Cielo
- **Hacer:** `Environment` con `background_mode = BG_SKY`, `Sky` con `ProceduralSkyMaterial`.
- **Hecho cuando:** se ve cielo con horizonte, sin errores.

### M10.02 — Niebla
- **Hacer:** `fog_enabled = true`, color = color del horizonte. Ajustar densidad/profundidad para que los chunks no "aparezcan" bruscamente en el borde.
- **Hecho cuando:** al mirar hacia el borde del mundo cargado, no se aprecia el corte.

### M10.03 — Ciclo día/noche
- **Hacer:** `time_of_day` (0..1) avanza `delta / DAY_LENGTH_SECONDS`. Rotar `DirectionalLight3D`/sol del cielo; interpolar colores de cielo; multiplicar `albedo_color` del material sólido por un brillo entre 0.25 y 1.0. `time_of_day` se guarda en `world.json`.
- **Hecho cuando:** un ciclo completo recorre amanecer, día, atardecer y noche sin saltos; de noche el mundo es visible.

### M10.04 — Agua jugable
- **Hacer:** Si el bloque a la altura de los pies es `WATER`: gravedad ×0.3, caída máxima 3 b/s, `jump` nada hacia arriba a 4 b/s, velocidad horizontal ×0.6. Si la cámara está en agua: filtro azul semitransparente en pantalla.
- **Hecho cuando:** puedes nadar, salir del agua subiendo al borde saltando, y se aprecia el filtro bajo el agua.

### M10.05 — Hojas y cristal
- **Hacer:** Comprobar los bordes con `alpha_scissor`. Sin parpadeo, sin halo.
- **Hecho cuando:** se ven los huecos de las hojas y el centro transparente del cristal desde varios ángulos y distancias.

### M10.06 — (Recomendado) Oclusión ambiental por vértice
- **Hacer:** Para cada vértice de cada cara, mirar los 3 bloques adyacentes en el plano de la cara: `side1`, `side2`, `corner`. `ao = (side1 && side2) ? 0 : 3 - (side1 + side2 + corner)`. Brillo del vértice = `brillo_cara * [0.4, 0.6, 0.8, 1.0][ao]`. Voltear la diagonal del quad cuando `ao0 + ao2 > ao1 + ao3` para evitar artefactos. Solo cuentan bloques **opacos**.
- **Casos de test:** bloque aislado sobre suelo plano: los 4 vértices del techo tienen `ao=3`; junto a una pared: los vértices pegados tienen menos; esquina interior: `ao=0` en el vértice entre dos lados.
- **Hecho cuando:** `PASS`; sin degradados diagonales raros en terreno plano.
