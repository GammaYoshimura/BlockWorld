class_name AtlasBuilder

static func build() -> ImageTexture:
	var atlas_size: int = Const.ATLAS_TILES * Const.TILE_PX
	var atlas_image: Image = Image.create(
		atlas_size,
		atlas_size,
		false,
		Image.FORMAT_RGBA8
	)
	atlas_image.fill(Color.TRANSPARENT)

	for tile: int in range(13):
		for y: int in range(Const.TILE_PX):
			for x: int in range(Const.TILE_PX):
				var pixel: Color = _tile_pixel(tile, x, y)
				atlas_image.set_pixel(
					tile * Const.TILE_PX + x,
					y,
					pixel
				)

	var save_error: Error = atlas_image.save_png("user://atlas_debug.png")
	if save_error != OK:
		push_error("AtlasBuilder no pudo guardar user://atlas_debug.png; error %d" % save_error)
	return ImageTexture.create_from_image(atlas_image)

static func _tile_pixel(tile: int, x: int, y: int) -> Color:
	match tile:
		0:
			return _varied_color(Color(0.34, 0.68, 0.20), x, y, tile)
		1:
			if y < 4:
				return _varied_color(Color(0.34, 0.68, 0.20), x, y, 0)
			return _varied_color(Color(0.48, 0.31, 0.17), x, y, 2)
		2:
			return _varied_color(Color(0.48, 0.31, 0.17), x, y, tile)
		3:
			return _varied_color(Color(0.48, 0.49, 0.50), x, y, tile)
		4:
			var mortar: bool = (x % 8 == 0) or (y % 8 == 0)
			var base: Color = Color(0.27, 0.28, 0.29) if mortar else Color(0.53, 0.54, 0.55)
			return _varied_color(base, x, y, tile)
		5:
			var plank_seam: bool = (y % 8 == 0) or (x == 0) or (x == Const.TILE_PX - 1)
			var plank_color: Color = Color(0.34, 0.20, 0.10) if plank_seam else Color(0.65, 0.43, 0.23)
			return _varied_color(plank_color, x, y, tile)
		6:
			var bark_line: bool = (x % 5 == 0) or ((x + y) % 11 == 0)
			var bark_color: Color = Color(0.25, 0.14, 0.07) if bark_line else Color(0.48, 0.29, 0.13)
			return _varied_color(bark_color, x, y, tile)
		7:
			return _log_top_pixel(x, y)
		8:
			if _pixel_hash(x, y, tile) % 4 == 0:
				return Color(0.12, 0.38, 0.10, 0.0)
			return _varied_color(Color(0.20, 0.48, 0.16), x, y, tile)
		9:
			return _varied_color(Color(0.83, 0.74, 0.48), x, y, tile)
		10:
			var is_border: bool = x == 0 or y == 0 or x == Const.TILE_PX - 1 or y == Const.TILE_PX - 1
			if is_border:
				return Color(0.82, 0.94, 1.0, 1.0)
			return Color(0.72, 0.90, 1.0, 0.0)
		11:
			return _varied_color(Color(0.22, 0.23, 0.24), x, y, tile)
		12:
			return _varied_color(Color(0.12, 0.39, 0.82, 0.55), x, y, tile, false)
		_:
			return Color.TRANSPARENT

static func _log_top_pixel(x: int, y: int) -> Color:
	var center: float = (float(Const.TILE_PX) - 1.0) * 0.5
	var distance: float = Vector2(float(x) - center, float(y) - center).length()
	var ring: int = floori(distance * 1.25)
	var ring_color: Color = Color(0.42, 0.24, 0.11) if ring % 2 == 0 else Color(0.70, 0.49, 0.27)
	return _varied_color(ring_color, x, y, 7)

static func _varied_color(base: Color, x: int, y: int, tile: int, vary_alpha: bool = true) -> Color:
	var variation: float = float(_pixel_hash(x, y, tile) % 21 - 10) / 255.0
	var alpha: float = base.a
	if vary_alpha:
		alpha = clampf(alpha, 0.0, 1.0)
	return Color(
		clampf(base.r + variation, 0.0, 1.0),
		clampf(base.g + variation, 0.0, 1.0),
		clampf(base.b + variation, 0.0, 1.0),
		alpha
	)

static func _pixel_hash(x: int, y: int, tile: int) -> int:
	var hash_value: int = (x * 73856093) ^ (y * 19349663) ^ (tile * 83492791)
	hash_value = hash_value ^ (hash_value >> 13)
	hash_value *= 1274126177
	hash_value = hash_value ^ (hash_value >> 16)
	return absi(hash_value)
