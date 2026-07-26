-- berserker_5th_attribute_god_hand — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/heracles/heracles_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

berserker_5th_attribute_god_hand = class({})

-- Логика перенесена из scripts/vscripts/berserker_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnGodHandAcquired

OnGodHandAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local ability = hero:FindAbilityByName("berserker_5th_god_hand")
	--ability:SetLevel(1)
	hero.IsGodHandAcquired = true
	--hero.GodHandStock = 11
	--ability:ApplyDataDrivenModifier(hero, hero, "modifier_god_hand_stock", {}) 
	--hero:SetModifierStackCount("modifier_god_hand_stock", hero, 11)
	--hero.bIsGHReady = true
	--hero:FindAbilityByName("berserker_5th_reincarnation"):SetLevel(1)
	--hero.ReincarnationDamageTaken = 0
	--UpdateGodhandProgress(hero)

	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function berserker_5th_attribute_god_hand:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: berserker_ability / OnGodHandAcquired
	OnGodHandAcquired({ caster = caster, ability = self, target = caster })
end
