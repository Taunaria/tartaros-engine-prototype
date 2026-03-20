extends RefCounted
class_name CombatDebug

static var enabled: bool = false
static var enemy_logic_enabled: bool = true


static func toggle() -> bool:
	enabled = not enabled
	return enabled


static func toggle_enemy_logic() -> bool:
	enemy_logic_enabled = not enemy_logic_enabled
	return enemy_logic_enabled
