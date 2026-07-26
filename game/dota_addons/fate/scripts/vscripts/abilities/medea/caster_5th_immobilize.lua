-- caster_5th_immobilize — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_immobilize = class({})

LinkLuaModifier("modifier_territory_root", "abilities/medea/caster_5th_immobilize", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnTerritoryImmobilize

OnTerritoryImmobilize = function(keys)
	local caster = keys.caster

	if caster.IsMobilized then 
		caster.IsMobilized = false
	else 
		return
	end
	caster:RemoveModifierByName("modifier_mobilize")
	caster:AddNewModifier(caster, keys.ability, "modifier_territory_root", {}) 
	caster:SwapAbilities("caster_5th_mobilize", "caster_5th_immobilize", true, false) 

	caster:SwapAbilities("caster_5th_mana_drain", "fate_empty2", true, false)
	caster:SwapAbilities("caster_5th_territory_explosion", "fate_empty3", true, false)
	caster:SwapAbilities("caster_5th_recall", "fate_empty4", true, false)
	caster:SwapAbilities("fate_empty_nothidden", "caster_5th_dimensional_jump", true, false)
end


function caster_5th_immobilize:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / OnTerritoryImmobilize
	OnTerritoryImmobilize({ caster = caster, ability = self, target = caster })
end

modifier_territory_root = class({})


function modifier_territory_root:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
	}
end

function modifier_territory_root:GetModifierTurnRate_Percentage()
	return -10000
end

function modifier_territory_root:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end
