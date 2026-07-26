-- caster_5th_close_spellbook — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_close_spellbook = class({})

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnAncientClosed

OnAncientClosed = function(keys)
	local caster = keys.caster
	local a1 = caster:GetAbilityByIndex(0)
	local a2 = caster:GetAbilityByIndex(1)
	local a3 = caster:GetAbilityByIndex(2)
	local a4 = caster:GetAbilityByIndex(3)
	local a5 = caster:GetAbilityByIndex(4)
	local a6 = caster:GetAbilityByIndex(5)

	local ultiName = "medea_hecatic_graea"
	if caster.IsHGComboEnabled then 
		print("combo is currently active")
		ultiName = "medea_hecatic_graea_combo"
	end
	caster:SwapAbilities(a1:GetName(), "medea_argos", false ,true) 
	caster:SwapAbilities(a2:GetName(), "caster_5th_ancient_magic", false, true) 
	caster:SwapAbilities(a3:GetName(), "caster_5th_rule_breaker", false, true) 
	caster:SwapAbilities(a4:GetName(), "caster_5th_territory_creation", false, true) 
	caster:SwapAbilities(a5:GetName(), "caster_5th_item_construction", false, true) 
	caster:SwapAbilities(a6:GetName(), ultiName, false, true )
	local spellbook = caster:FindAbilityByName("caster_5th_ancient_magic")
	if spellbook:GetToggleState() then
		spellbook:ToggleAbility()
	end
end


function caster_5th_close_spellbook:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / OnAncientClosed
	OnAncientClosed({ caster = caster, ability = self, target = caster })
end
