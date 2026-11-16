extends SceneTree
const Catalog = preload("res://features/dama/content/dama_catalog.tres")
const Validation = preload("res://features/dama/data/dama_validation.gd")
const Matchups = preload("res://features/dama/rules/type_matchups.gd")
const Progression = preload("res://features/dama/rules/species_progression.gd")
const Sheets = preload("res://features/dama/presentation/sheet_frames.gd")

func _initialize() -> void:
	var errors := Validation.errors(Catalog)
	assert(errors.is_empty(), "\n".join(errors))
	assert(Catalog.species.size() == 3 and Catalog.find_move("slash") != null)
	var cindlet = Catalog.find_species("cindlet")
	assert(Progression.eligible_evolutions(cindlet, 15).is_empty())
	assert(Progression.eligible_evolutions(cindlet, 16) == PackedStringArray(["seraphlare"]))
	assert(Progression.eligible_evolutions(Catalog.find_species("seraphlare"), 36) == PackedStringArray(["seraphort"]))
	assert(Progression.learned_moves(cindlet, 1) == PackedStringArray(["tackle"]))
	assert("ember" in Progression.learned_moves(cindlet, 5))
	assert("slash" in Progression.learned_moves(cindlet, 20))
	assert("flamethrower" not in Progression.learned_moves(cindlet, 31))
	assert("flamethrower" in Progression.learned_moves(cindlet, 32))
	assert(Matchups.multiplier(Catalog, "water", PackedStringArray(["fire"])) == 2)
	assert(Matchups.multiplier(Catalog, "fire", PackedStringArray(["water"])) == 0.5)
	assert(Matchups.multiplier(Catalog, "earth", PackedStringArray(["fire", "air"])) == 0)
	assert(Matchups.multiplier(Catalog, "nature", PackedStringArray(["fire", "air"])) == 0.25)
	assert(Matchups.multiplier(Catalog, "ice", PackedStringArray(["fire", "air"])) == 1)
	assert(Matchups.multiplier(Catalog, "water", PackedStringArray(["fire", "fire"])) == 2)
	for species in Catalog.species:
		var info := Sheets.inspect(species.art)
		assert(info.errors.is_empty())
		var frames := Sheets.build(species.art)
		assert(frames.has_animation(&"idle_south"))
		assert(frames.get_animation_names().size() == 17)
		var texture: AtlasTexture = frames.get_frame_texture(&"idle_south", 0)
		assert(int(texture.region.size.x) in [76, 84, 88], "Character cells were resized or misread: %s" % texture.region)
	var flame = Catalog.find_move("flamethrower")
	assert(flame.power == 90 and flame.mana_points == 15 and flame.accuracy == 100)
	var effect := Sheets.build(flame.animation)
	assert(effect.get_frame_count(&"flamethrower-diagonal") == 10)
	assert(is_equal_approx(effect.get_frame_duration(&"flamethrower-diagonal", 0) / effect.get_animation_speed(&"flamethrower-diagonal"), 0.083))
	var slash := Sheets.build(Catalog.find_move("slash").animation)
	assert(slash.get_frame_count(&"slash") == 8)
	assert(is_equal_approx(slash.get_frame_duration(&"slash", 0) / slash.get_animation_speed(&"slash"), 0.063))
	_invalid_content()
	print("PASS: Dama references/stats, evolution thresholds, learnsets, type multiplication/immunity, source sprite cells, both VFX timings and invalid-content rejection")
	quit()

func _invalid_content() -> void:
	var broken = Catalog.duplicate(true)
	broken.find_species("seraphort").evolutions.append(Catalog.find_species("cindlet").evolutions[0].duplicate(true))
	assert(not Validation.errors(broken).is_empty(), "Evolution cycle accepted")
	broken = Catalog.duplicate(true)
	broken.find_species("cindlet").stats.health = 0
	broken.find_species("cindlet").learnset[0].move_id = "missing"
	broken.find_species("cindlet").types = PackedStringArray(["missing"])
	broken.find_move("flamethrower").mana_points = 0
	broken.find_move("flamethrower").accuracy = 101
	assert(Validation.errors(broken).size() >= 5)
	broken = Catalog.duplicate(true)
	broken.find_move("flamethrower").animation.clip = "missing"
	assert(not Validation.errors(broken).is_empty())
	broken = Catalog.duplicate(true)
	broken.find_type("fire").incoming["water"] = -1.0
	assert(not Validation.errors(broken).is_empty())
