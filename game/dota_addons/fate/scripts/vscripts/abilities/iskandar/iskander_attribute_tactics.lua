-- iskander_attribute_tactics — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/iskandar/iskandar_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

iskander_attribute_tactics = class({})

-- Логика перенесена из scripts/vscripts/iskander_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnTacticsAcquired

OnTacticsAcquired = function(keys)
    local caster = keys.caster
    local ply = caster:GetPlayerOwner()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    hero.IsTacticsAcquired = true
	if hero:GetAbilityByIndex(4):GetName() == "fate_empty1" then
        hero:SwapAbilities("fate_empty1", "iskander_trap", false, true)
	end
    local master = hero.MasterUnit
    master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function iskander_attribute_tactics:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: iskander_ability / OnTacticsAcquired
	OnTacticsAcquired({ caster = caster, ability = self, target = caster })
end
