-- false_assassin_attribute_vitrification — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/sasaki/sasaki_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

false_assassin_attribute_vitrification = class({})

-- Логика перенесена из scripts/vscripts/fa_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnVitrificationAcquired

OnVitrificationAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.IsVitrificationAcquired = true
	hero:FindAbilityByName("false_assassin_presence_concealment"):SetLevel(1) 
	hero:SwapAbilities("fate_empty1", "false_assassin_presence_concealment", false, true) 

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function false_assassin_attribute_vitrification:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: fa_ability / OnVitrificationAcquired
	OnVitrificationAcquired({ caster = caster, ability = self, target = caster })
end
