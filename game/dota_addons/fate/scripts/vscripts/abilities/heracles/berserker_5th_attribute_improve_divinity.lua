-- berserker_5th_attribute_improve_divinity — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/heracles/heracles_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

berserker_5th_attribute_improve_divinity = class({})

-- Логика перенесена из scripts/vscripts/berserker_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnImproveDivinityAcquired

OnImproveDivinityAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsDivinityImproved = true
	hero:FindAbilityByName("pepeg_divinity"):SetLevel(2)
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function berserker_5th_attribute_improve_divinity:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: berserker_ability / OnImproveDivinityAcquired
	OnImproveDivinityAcquired({ caster = caster, ability = self, target = caster })
end
