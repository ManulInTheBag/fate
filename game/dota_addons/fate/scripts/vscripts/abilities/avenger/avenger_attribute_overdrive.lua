-- avenger_attribute_overdrive — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_attribute_overdrive = class({})

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnOverdriveAcquired

OnOverdriveAcquired = function(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.PuddleArmy = true
    -- hero:FindAbilityByName("avenger_overdrive"):SetLevel(1)
    -- hero:AddNewModifier(caster, keys.ability, "modifier_overdrive_attribute", {})


    -- enable overdrive passive
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function avenger_attribute_overdrive:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: avenger_ability / OnOverdriveAcquired
	OnOverdriveAcquired({ caster = caster, ability = self, target = caster })
end
