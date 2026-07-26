-- lancer_trap_passive — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lancer_trap_passive = class({})

LinkLuaModifier("lancer_trap", "abilities/general/lancer_trap_passive", LUA_MODIFIER_MOTION_NONE)

function lancer_trap_passive:GetIntrinsicModifierName()
	return "lancer_trap"
end

lancer_trap = class({})

function lancer_trap:IsHidden() return true end

function lancer_trap:CheckState()
	return {
		[MODIFIER_STATE_INVISIBLE] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end
