-- berserker_5th_attribute_berserk — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/heracles/heracles_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

berserker_5th_attribute_berserk = class({})

-- Логика перенесена из scripts/vscripts/berserker_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnBerserkAcquired

OnBerserkAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero:FindAbilityByName("berserker_5th_berserk_attribute_passive"):SetLevel(1)
	hero.IsEternalRageAcquired = true
	hero.IsRageBashOnCooldown = false
	hero.IsCDReductionCoolingdown = false
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function berserker_5th_attribute_berserk:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: berserker_ability / OnBerserkAcquired
	OnBerserkAcquired({ caster = caster, ability = self, target = caster })
end
