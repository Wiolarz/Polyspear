# TierPanel
extends PanelContainer


var setup_ui : BattleSetup = null

@onready var tier_name = $MainContainer/TierLabel

@onready var buttons_passives : Array[Button] = [
	$MainContainer/TierUpgrades/PowerPassiveButton,
	$MainContainer/TierUpgrades/TacticPassiveButton,
	$MainContainer/TierUpgrades/MagicPassiveButton
]
@onready var buttons_skills : Array[Button] = [
	$MainContainer/TierSkills/PowerSkillButton,
	$MainContainer/TierSkills/TacticSkillButton,
	$MainContainer/TierSkills/MagicSkillButton,
]

# STUB
func init_tier_panel(tier : int, _faction : DataRace) -> void:
	tier_name.text = "TIER - " + str(tier)
	pass
