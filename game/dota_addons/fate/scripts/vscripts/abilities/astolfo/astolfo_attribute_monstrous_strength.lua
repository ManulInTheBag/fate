-- astolfo_attribute_monstrous_strength — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/astolfo/astolfo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

astolfo_attribute_monstrous_strength = class({})

-- Логика перенесена из scripts/vscripts/astolfo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnMStrengthAcquired

OnMStrengthAcquired = function(keys)
    local caster = keys.caster
    local hero = PlayerResource:GetSelectedHeroEntity(caster:GetPlayerOwnerID())
    hero.bIsMStrengthAcquired = true
    -- Set master 1's mana
    local master = hero.MasterUnit
    local master2 = hero.MasterUnit2
    master:SetMana(master2:GetMana())

    --hero:SetBaseStrength(hero:GetBaseStrength()+10) 
    hero:AddAbility("astolfo_monstrous_strength")
    hero:FindAbilityByName("astolfo_monstrous_strength"):SetLevel(1)
    hero:FindAbilityByName("astolfo_monstrous_strength"):SetHidden(true)
    hero:FindAbilityByName("astolfo_monstrous_strength_passive"):SetLevel(1)


end


function astolfo_attribute_monstrous_strength:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: astolfo_ability / OnMStrengthAcquired
	OnMStrengthAcquired({ caster = caster, ability = self, target = caster })
end
