-- lancelot_attribute_blessing_of_fairy — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/lancelot/lancelot_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lancelot_attribute_blessing_of_fairy = class({})

-- Логика перенесена из scripts/vscripts/lancelot_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnBlessingAcquired

OnBlessingAcquired = function(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero:AddAbility("lancelot_blessing_of_fairy") 
    -- Гард на nil: слотов способностей у юнита всего 36, и если список забит под завязку
    -- (у Ланселота так и есть), AddAbility молча не срабатывает, а голый FindAbilityByName
    -- ронял весь OnSpellStart вместе с выдачей атрибута.
    local hBlessing = hero:FindAbilityByName("lancelot_blessing_of_fairy")
    if hBlessing then
        hBlessing:SetLevel(1)
    else
        print("[Fate] WARNING: lancelot_blessing_of_fairy не выдалась — кончились слоты способностей")
    end
    hero:SwapAbilities("fate_empty1", "lancelot_blessing_of_fairy", false, true) 
    hero:RemoveAbility("fate_empty1") 
    hero.IsFairyReady = true
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function lancelot_attribute_blessing_of_fairy:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: lancelot_ability / OnBlessingAcquired
	OnBlessingAcquired({ caster = caster, ability = self, target = caster })
end
