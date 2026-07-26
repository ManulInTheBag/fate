-- astolfo_attribute_independent_action — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/astolfo/astolfo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

astolfo_attribute_independent_action = class({})

-- Логика перенесена из scripts/vscripts/astolfo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnIActionAcquired

OnIActionAcquired = function(keys)
    local caster = keys.caster
    local hero = PlayerResource:GetSelectedHeroEntity(caster:GetPlayerOwnerID())
    hero.bIsIAAcquired = true
    -- Set master 1's mana
    local master = hero.MasterUnit
    local master2 = hero.MasterUnit2
    master:SetMana(master2:GetMana())

    hero:AddAbility("astolfo_independent_action")
    hero:FindAbilityByName("astolfo_independent_action"):SetLevel(1)
    hero:FindAbilityByName("astolfo_independent_action"):SetHidden(true)
end


function astolfo_attribute_independent_action:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: astolfo_ability / OnIActionAcquired
	OnIActionAcquired({ caster = caster, ability = self, target = caster })
end
