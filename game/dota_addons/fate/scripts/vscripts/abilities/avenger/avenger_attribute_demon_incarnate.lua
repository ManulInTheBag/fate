-- avenger_attribute_demon_incarnate — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_attribute_demon_incarnate = class({})

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDIAcquired

OnDIAcquired = function(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsDIAcquired = true
    hero:FindAbilityByName("angra_mainyu_demon_incarnate_passive"):SetLevel(1)
	
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function avenger_attribute_demon_incarnate:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: avenger_ability / OnDIAcquired
	OnDIAcquired({ caster = caster, ability = self, target = caster })
end
