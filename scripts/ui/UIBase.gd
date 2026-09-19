extends Control

# UIBase provides common UI helpers for all UI scenes.
# Includes a simple click sound helper that uses AudioManager.

func _ready():
    # Ensure AudioManager is ready – no action needed for Phase 1.
    pass

func play_click() -> void:
    # Placeholder silent click – replace with actual SFX later.
    AudioManager.play_sfx(null)
