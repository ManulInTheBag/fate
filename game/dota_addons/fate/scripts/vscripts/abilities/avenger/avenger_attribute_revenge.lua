-- avenger_attribute_revenge — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_attribute_revenge = class({})

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnRevengeAcquired

OnRevengeAcquired = function(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsRevengeAcquired = true
	
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function avenger_attribute_revenge:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: avenger_ability / OnRevengeAcquired
	OnRevengeAcquired({ caster = caster, ability = self, target = caster })
end
