-- astolfo_attribute_sanity — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/astolfo/astolfo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

astolfo_attribute_sanity = class({})

-- Логика перенесена из scripts/vscripts/astolfo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnSanityAcquired

OnSanityAcquired = function(keys)
    local caster = keys.caster
    local hero = PlayerResource:GetSelectedHeroEntity(caster:GetPlayerOwnerID())
    hero.bIsSanityAcquired = true

    --hero:AddAbility("astolfo_evaporation_of_sanity")
    --hero:FindAbilityByName("astolfo_evaporation_of_sanity"):SetLevel(1)
    --hero:FindAbilityByName("astolfo_evaporation_of_sanity"):SetHidden(true)
    --hero:FindAbilityByName("astolfo_casa_di_logistilla"):SetHidden(false)

    -- Set master 1's mana
    local master = hero.MasterUnit
    local master2 = hero.MasterUnit2
    master:SetMana(master2:GetMana())

    --hero:AddAbility("astolfo_down_with_a_touch_passive")
    --hero:FindAbilityByName("astolfo_down_with_a_touch_passive"):SetLevel(1)
    --hero:FindAbilityByName("astolfo_down_with_a_touch_passive"):SetHidden(true)
end


function astolfo_attribute_sanity:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: astolfo_ability / OnSanityAcquired
	OnSanityAcquired({ caster = caster, ability = self, target = caster })
end
