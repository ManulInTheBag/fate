-- lishuwen_attribute_dual_class — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/li_shuwen/li_shuwen_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lishuwen_attribute_dual_class = class({})

-- Логика перенесена из scripts/vscripts/lishuwen_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDualClassAcquired

OnDualClassAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.bIsDualClassAcquired = true
	hero:FindAbilityByName("lishuwen_berserk"):SetLevel(1)
	hero:SwapAbilities("lishuwen_berserk", "fate_empty1", true, false) 
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function lishuwen_attribute_dual_class:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: lishuwen_ability / OnDualClassAcquired
	OnDualClassAcquired({ caster = caster, ability = self, target = caster })
end
