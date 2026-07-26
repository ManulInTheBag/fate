-- lishuwen_attribute_furious_chain — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/li_shuwen/li_shuwen_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lishuwen_attribute_furious_chain = class({})

-- Логика перенесена из scripts/vscripts/lishuwen_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnFuriousChainAcquired

OnFuriousChainAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.bIsFuriousChainAcquired = true
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	-- AGI scaling and mana refund on abilities
	-- aspd and ms buff
end


function lishuwen_attribute_furious_chain:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: lishuwen_ability / OnFuriousChainAcquired
	OnFuriousChainAcquired({ caster = caster, ability = self, target = caster })
end
