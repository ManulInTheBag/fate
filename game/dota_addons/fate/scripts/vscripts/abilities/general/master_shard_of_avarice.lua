-- master_shard_of_avarice — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

master_shard_of_avarice = class({})

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnAvariceAcquired

OnAvariceAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	if hero.ShardAmount == 0 or hero.ShardAmount == nil then 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Acquire_Shard")
		return 
	else 
		hero.ShardAmount = hero.ShardAmount - 1
		hero.ServStat:getS1()
		local caster_name =  PlayerResource:GetPlayerName(hero:GetPlayerID())
		GameRules:SendCustomMessageToTeam(caster_name .. " just acquired shard of Avarice!", hero:GetTeamNumber(), 0, 0)
	end


	if hero.AvariceCount == nil then 
		hero.AvariceCount = 1
	else
		hero.AvariceCount = hero.AvariceCount + 1
	end

	-- distribute gold
	-- (do NOT overwrite "hero" here: it is the buyer, and the stat update below must go to them)
	local teamTable = {}
	for i=0, 13 do
		local player = PlayerResource:GetPlayer(i)
		if player ~= nil then
			local teamHero = player:GetAssignedHero()
			if teamHero ~= nil and teamHero:GetTeam() == caster:GetTeam() then
				table.insert(teamTable, teamHero)
			end
		end
	end

	--[[for i=1,#teamTable do
		local goldperperson = 10000/#teamTable
		--print("Distributing " .. goldperperson .. " per person")
		teamTable[i]:ModifyGold(goldperperson, true, 0)
	end]]
    local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable ) -- Send the current stat info to JS
end


function master_shard_of_avarice:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnAvariceAcquired
	OnAvariceAcquired({ caster = caster, ability = self, target = caster })
end
