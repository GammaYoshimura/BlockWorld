# BlockWorld — Fase 5: jugador

> **Qué pasar a ChatGPT junto con este archivo:** `BW_01_NUCLEO.md` y tu `BW_02_PROGRESS.md` actualizado.
> Pide un milestone cada vez (`HAZ Mx.xx`). Si el milestone toca código que ya existe, pega también esos archivos completos.
> Cuando un milestone cita "3.4", "3.8", etc., son secciones de `BW_01_NUCLEO.md`.

---

## FASE 5 — Jugador

### M5.01 — Escena del jugador por código
- **Hacer:** `Player` (CharacterBody3D) construye en `_ready`: `CollisionShape3D` con `CapsuleShape3D` (`radius = 0.3`, `height = 1.8`) en `position.y = 0.9` (los pies = origen del nodo), un `Node3D` pivote `Head` en `y = Const.PLAYER_EYE_HEIGHT` y la `Camera3D` hija. `collision_layer = 2`, `collision_mask = 1`. Eliminar la cámara libre.
- **Hecho cuando:** el árbol de nodos en ejecución (Remoto) coincide con lo descrito.

### M5.02 — Mirada con ratón
- **Hacer:** En `_unhandled_input`: si `InputEventMouseMotion` y ratón capturado → `rotate_y(-event.relative.x * Const.MOUSE_SENSITIVITY)`; `head.rotation.x = clampf(head.rotation.x - event.relative.y * Const.MOUSE_SENSITIVITY, -deg_to_rad(89), deg_to_rad(89))`.
- **Hecho cuando:** mirar arriba/abajo se detiene en ±89°; no hay inclinación lateral.

### M5.03 — Movimiento horizontal
- **Hacer:** `Input.get_vector("move_left","move_right","move_forward","move_back")`; dirección = `(transform.basis * Vector3(i.x, 0, i.y)).normalized()`; velocidad objetivo `Const.WALK_SPEED`; aceleración con `move_toward` (suelo 60, aire 20); sin input, frenar.
- **Hecho cuando:** imprimiendo `Vector2(velocity.x, velocity.z).length()` caminando recto y en diagonal, ambos dan ≈ `4.3`.

### M5.04 — Gravedad
- **Hacer:** `velocity.y -= Const.GRAVITY * delta`, limitado a `-TERMINAL_VELOCITY`; `move_and_slide()` al final.
- **Hecho cuando:** el jugador cae y se queda de pie sobre el chunk plano; `is_on_floor()==true`; `velocity.y` no oscila de forma visible.

### M5.05 — Colisión con el mundo
- **Hacer:** En `Chunk`: `StaticBody3D` + `CollisionShape3D` con la forma de `solid_mesh.mesh.create_trimesh_shape()` (solo malla **sólida**, nunca agua). `set_collision_enabled(bool)`. De momento síncrono, para chunks con distancia ≤ `COLLISION_RADIUS` al jugador; al salir del radio, se quita la forma.
- **Hecho cuando:** el jugador no atraviesa suelo ni paredes; **cruzar 20 veces una frontera de chunk caminando no produce tirones ni atascos**; empujar contra una esquina no lo atraviesa.
- **Ojo:** crear la forma solo si el mesh no está vacío.

### M5.06 — Salto
- **Hacer:** Con `jump` y `is_on_floor()`: `velocity.y = Const.JUMP_VELOCITY`. Al caminar contra un desnivel, subir automáticamente como máximo 1 bloque; no auto-subir 2.
- **Hecho cuando:** imprimiendo la altura máxima alcanzada sobre el suelo da entre 1.2 y 1.3; sube automáticamente un escalón de 1 bloque, **no** sube automáticamente 2 y el salto tampoco alcanza 2 bloques.

### M5.07 — Sprint y agacharse
- **Hacer:** `sprint` → `SPRINT_SPEED` solo si va hacia delante; `sneak` → `SNEAK_SPEED`. Solo cambia la velocidad (el "no caer por bordes" es opcional, Fase 11).
- **Hecho cuando:** velocidades impresas 5.6 / 4.3 / 1.3.

### M5.08 — Aparición segura (spawn gating)
- **Hacer:** El jugador nace con `set_physics_process(false)`, en `(0.5, height_at(0,0) + 2, 0.5)`. Se activa cuando los chunks del radio 2 alrededor tienen su colisión creada. Mientras tanto, pantalla negra/"Generando mundo…".
- **Hecho cuando:** 20 inicios seguidos sin caer al vacío.

### M5.09 — Modo vuelo
- **Hacer:** `toggle_fly` conmuta. En vuelo: sin gravedad, `FLY_SPEED`, Espacio sube, Shift baja, `move_and_slide()` sigue colisionando.
- **Hecho cuando:** vuelas y chocas con paredes; al desactivar vuelas → caes.

### M5.10 — Reaparición
- **Hacer:** Si `global_position.y < -20`: teletransportar al spawn y poner `velocity = Vector3.ZERO`.
- **Hecho cuando:** (se prueba con un `Vector3` forzado en debug) reaparece sin quedar con velocidad residual.

### M5.11 — Cámara
- **Hacer:** `fov = 70`, `near = 0.05`, `far = (render_distance + 2) * 16`.
- **Hecho cuando:** pegado a una pared, el bloque no se "recorta" por dentro.
