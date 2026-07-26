-- lishuwen_attribute_circulatory_shock — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/li_shuwen/li_shuwen_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lishuwen_attribute_circulatory_shock = class({})

-- Логика перенесена из scripts/vscripts/lishuwen_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnCirculatoryShockAcquired

OnCirculatoryShockAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.bIsCirculatoryShockAcquired = true
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
end


function lishuwen_attribute_circulatory_shock:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: lishuwen_ability / OnCirculatoryShockAcquired
	OnCirculatoryShockAcquired({ caster = caster, ability = self, target = caster })
end
