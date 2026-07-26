-- master_intelligence — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

master_intelligence = class({})

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnIntelligenceGain

OnIntelligenceGain = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero:GetName() == "npc_dota_hero_juggernaut" then
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Acquire_Intelligence")
		caster:GiveMana(1)
		return
	end

	if hero.INTgained == nil then
		hero.INTgained = 1
	else 
		if hero.INTgained < 30 then
			hero.INTgained = hero.INTgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_30_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	hero.ServStat:addInt()
	hero:SetBaseIntellect(hero:GetBaseIntellect()+1) 
	hero:CalculateStatBonus(true)
	hero:FindModifierByName("modifier_attributes_cdr"):UpdateValues()
	
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end


function master_intelligence:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnIntelligenceGain
	OnIntelligenceGain({ caster = caster, ability = self, target = caster })
end
