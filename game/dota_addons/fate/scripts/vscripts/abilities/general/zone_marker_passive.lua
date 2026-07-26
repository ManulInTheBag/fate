-- zone_marker_passive — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

zone_marker_passive = class({})

LinkLuaModifier("modifier_zone_marker", "abilities/general/zone_marker_passive", LUA_MODIFIER_MOTION_NONE)

function zone_marker_passive:GetIntrinsicModifierName()
	return "modifier_zone_marker"
end

modifier_zone_marker = class({})

function modifier_zone_marker:IsHidden() return true end

function modifier_zone_marker:CheckState()
	return {
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_FLYING] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end
