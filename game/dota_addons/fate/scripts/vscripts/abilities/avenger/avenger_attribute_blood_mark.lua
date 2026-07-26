-- avenger_attribute_blood_mark — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_attribute_blood_mark = class({})

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnBloodMarkAcquired

OnBloodMarkAcquired = function(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsBloodMarkAcquired = true
    -- swap vengeance mark with blood mark
    --caster:SwapAbilities("fate_empty1", "avenger_blood_mark", false, true) 
    -- Set master 1's mana 
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
    if hero:HasModifier("modifier_true_form") then
    	hero:SwapAbilities("fate_empty1", "avenger_blood_mark", false, true) 
    end
end


function avenger_attribute_blood_mark:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: avenger_ability / OnBloodMarkAcquired
	OnBloodMarkAcquired({ caster = caster, ability = self, target = caster })
end
