-- gawain_attribute_blessing_of_fairy — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gawain/gawain_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gawain_attribute_blessing_of_fairy = class({})

-- Логика перенесена из scripts/vscripts/gawain_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnFairyAcquired

OnFairyAcquired = function(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsFairyAcquired = true

    hero:AddAbility("gawain_blessing_of_fairy")
    hero:FindAbilityByName("gawain_blessing_of_fairy"):SetLevel(1)
    --hero:SwapAbilities("fate_empty8", "gawain_blessing_of_fairy", false, true)

  	--hero:FindAbilityByName("gawain_blessing_of_fairy"):SetHidden(false)
    hero:SwapAbilities(hero:GetAbilityByIndex(4):GetName(), "gawain_blessing_proxy", false, true)
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function gawain_attribute_blessing_of_fairy:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: gawain_ability / OnFairyAcquired
	OnFairyAcquired({ caster = caster, ability = self, target = caster })
end
