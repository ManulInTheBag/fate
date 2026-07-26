-- master_agility — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

master_agility = class({})

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnAgilityGain

OnAgilityGain = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero.AGIgained == nil then
		hero.AGIgained = 1
	else 
		if hero.AGIgained < 30 then
			hero.AGIgained = hero.AGIgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_30_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	if hero.ARMORgained == nil then
		hero.ARMORgained = 1
	else 
		if hero.ARMORgained < 30 then
			hero.ARMORgained = hero.ARMORgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_30_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	hero.ServStat:addAgi()
	hero:SetBaseAgility(hero:GetBaseAgility()+1)
	hero.ServStat:addArmor()
	hero:CalculateStatBonus(true)
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end


function master_agility:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnAgilityGain
	OnAgilityGain({ caster = caster, ability = self, target = caster })
end
