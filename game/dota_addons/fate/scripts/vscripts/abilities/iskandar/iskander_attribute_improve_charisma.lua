-- iskander_attribute_improve_charisma — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/iskandar/iskandar_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

iskander_attribute_improve_charisma = class({})

-- Логика перенесена из scripts/vscripts/iskander_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnIskanderCharismaImproved

OnIskanderCharismaImproved = function(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsCharismaImproved = true
    modName = "modifier_charisma_improved"

    hero:FindAbilityByName("iskandar_charisma"):SetLevel(2)

    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function iskander_attribute_improve_charisma:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: iskander_ability / OnIskanderCharismaImproved
	OnIskanderCharismaImproved({ caster = caster, ability = self, target = caster })
end
