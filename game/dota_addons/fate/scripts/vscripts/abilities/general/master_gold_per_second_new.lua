-- master_gold_per_second_new — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

master_gold_per_second_new = class({})

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnGpsGain

OnGpsGain = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero.AvariceCount == 1 or hero.AvariceCount == 2 then
		if hero.GpsGained == nil then
			hero.GpsGained = 1
		else 
			if hero.GpsGained < 10 then
				hero.GpsGained = hero.GpsGained + 1
			else
				SendErrorMessage(caster:GetPlayerOwnerID(), "Cannot acquire gps over 10")
				caster:GiveMana(1)
				return
			end
		end
	else
		SendErrorMessage(caster:GetPlayerOwnerID(), "Cannot aquire without Avarice")
		caster:GiveMana(1)
		return
	end
	hero.ServStat:addGps()
	
	hero:CalculateStatBonus(true)
	hero:FindModifierByName("modifier_attributes_gps"):UpdateValues()
	
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end


function master_gold_per_second_new:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnGpsGain
	OnGpsGain({ caster = caster, ability = self, target = caster })
end
