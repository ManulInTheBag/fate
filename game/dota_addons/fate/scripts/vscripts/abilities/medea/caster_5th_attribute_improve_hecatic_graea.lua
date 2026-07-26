-- caster_5th_attribute_improve_hecatic_graea — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/medea/medea_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

caster_5th_attribute_improve_hecatic_graea = class({})

-- Логика перенесена из scripts/vscripts/caster_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnImproveHGAcquired

OnImproveHGAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsHGImproved = true

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	ATTRIBUTE_HG_INT_MULTIPLIER = 1.5
end


function caster_5th_attribute_improve_hecatic_graea:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: caster_ability / OnImproveHGAcquired
	OnImproveHGAcquired({ caster = caster, ability = self, target = caster })
end
