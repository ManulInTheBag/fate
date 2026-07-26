-- iskander_attribute_thundergods_wrath — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/iskandar/iskandar_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

iskander_attribute_thundergods_wrath = class({})

-- Логика перенесена из scripts/vscripts/iskander_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnThundergodAcquired

OnThundergodAcquired = function(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsThundergodAcquired = true
       -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function iskander_attribute_thundergods_wrath:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: iskander_ability / OnThundergodAcquired
	OnThundergodAcquired({ caster = caster, ability = self, target = caster })
end
