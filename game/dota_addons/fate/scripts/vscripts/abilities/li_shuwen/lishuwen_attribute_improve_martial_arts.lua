-- lishuwen_attribute_improve_martial_arts — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/li_shuwen/li_shuwen_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lishuwen_attribute_improve_martial_arts = class({})

-- Логика перенесена из scripts/vscripts/lishuwen_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnMartialArtsImproved, AuraRefresh

OnMartialArtsImproved = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero.bIsMartialArtsImproved = true
	-- Set master 1's mana 
	local master = hero.MasterUnit
	master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	hero:FindAbilityByName("lishuwen_martial_arts"):SetLevel(2)
	hero:AddAbility("lishuwen_martial_arts_passive_dummy")
	hero:FindAbilityByName("lishuwen_martial_arts_passive_dummy"):SetLevel(1)
	AuraRefresh(keys)

	--[[if not hero:HasModifier("modifier_martial_arts_passive") then
		hero:AddNewModifier(hero, ability, "modifier_martial_arts_passive", { ManaBurnAmount = 55 })
	end]]
	-- allow NSS and FTS to apply mark of fatality
end

AuraRefresh = function(keys)
	local hero = keys.caster:GetPlayerOwner():GetAssignedHero()
	hero:RemoveModifierByName("modifier_martial_arts_aura") 
	hero:AddNewModifier(hero, hero:FindAbilityByName("lishuwen_martial_arts"), "modifier_martial_arts_aura", {}) 
end


function lishuwen_attribute_improve_martial_arts:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: lishuwen_ability / OnMartialArtsImproved
	OnMartialArtsImproved({ caster = caster, ability = self, target = caster })
end
