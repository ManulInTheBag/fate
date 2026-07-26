-- master_shard_of_prosperity — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

master_shard_of_prosperity = class({})

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnProsperityAcquired

OnProsperityAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	--print("Prosperity shard acquired")
	if hero.ShardAmount == 0 or hero.ShardAmount == nil then 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Acquire_Shard")
		return
	else 
		hero.ShardAmount = hero.ShardAmount - 1
		hero.ServStat:getS4()
	end

	if hero.ProsperityCount == nil then 
		hero.ProsperityCount = 1
	else
		hero.ProsperityCount = hero.ProsperityCount + 1
	end

	local master = hero.MasterUnit 
	local master2 = hero.MasterUnit2

	if master.ProsperityCount == nil then 
		master.ProsperityCount = 1
	else
		master.ProsperityCount = master.ProsperityCount + 1
	end


	-- for i=1,4 do
	-- 	local level = hero:GetLevel()
	-- 	if level ~= 24 then
	-- 		hero:AddExperience(_G.XP_PER_LEVEL_TABLE[level], false, false)
	-- 		--hero:AddExperience(XP_BOUNTY_PER_LEVEL_TABLE[killedUnit:GetLevel()]/realHeroCount, false, false)
	-- 	else
	-- 		master:SetMana(master:GetMana() + 3)
	-- 		master2:SetMana(master:GetMana())		
	-- 	end
	-- end


	--[[
	master:SetMana(master:GetMana()+20)
	master2:SetMana(master:GetMana())]]
	--master:SetMaxHealth(master:GetMaxHealth() + 6)
	--master:SetHealth(master:GetHealth() + 6)
	--master:SetMana(master:GetMana() + 3)
	--master2:SetMaxHealth(master:GetMaxHealth()) 
	--master2:SetHealth(master:GetHealth())
	--master2:SetMana(master:GetMana())
    local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable ) -- Send the current stat info to JS
end


function master_shard_of_prosperity:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnProsperityAcquired
	OnProsperityAcquired({ caster = caster, ability = self, target = caster })
end
