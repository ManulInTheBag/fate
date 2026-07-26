-- caster_5th_mobilize — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_mobilize = class({})

LinkLuaModifier("modifier_mobilize", "abilities/medea/caster_5th_mobilize", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnTerritoryMobilize

OnTerritoryMobilize = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:RemoveModifierByName("modifier_territory_root")
	caster:AddNewModifier(caster, ability, "modifier_mobilize", {})
	caster.IsMobilized = true
	caster:SwapAbilities("caster_5th_mobilize", "caster_5th_immobilize", false, true) 

	caster:SwapAbilities("caster_5th_mana_drain", "fate_empty2", false, true)
	caster:SwapAbilities("caster_5th_territory_explosion", "fate_empty3", false, true)
	caster:SwapAbilities("caster_5th_recall", "fate_empty4", false, true)
	caster:SwapAbilities("fate_empty_nothidden", "caster_5th_dimensional_jump", false, true)
end


function caster_5th_mobilize:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / OnTerritoryMobilize
	OnTerritoryMobilize({ caster = caster, ability = self, target = caster })
end

modifier_mobilize = class({})


function modifier_mobilize:CheckState()
	return {
		[MODIFIER_STATE_FLYING] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end
