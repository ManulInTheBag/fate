-- nero_attribute_invictus_spiritus — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/nero/nero_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

nero_attribute_invictus_spiritus = class({})

-- Логика перенесена из scripts/vscripts/nero_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnISAcquired

OnISAcquired = function(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsISAcquired = true
    hero.IsISOnCooldown = false
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function nero_attribute_invictus_spiritus:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: nero_ability / OnISAcquired
	OnISAcquired({ caster = caster, ability = self, target = caster })
end
