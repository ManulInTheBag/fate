-- master_shard_of_anti_magic — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/npc_abilities_custom.txt
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

master_shard_of_anti_magic = class({})

-- Логика перенесена из scripts/vscripts/master_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnAMAcquired

OnAMAcquired = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	if hero.HasPickedAntiMagicShardAlready then 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Already_picked_that_shard")
		return
	end
	if hero.ShardAmount == 0 or hero.ShardAmount == nil then 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Acquire_Shard")
		return
	else 
		hero.ShardAmount = hero.ShardAmount - 1
		hero.ServStat:getS2()
	end
	
	local item = hero:AddItem(CreateItem("item_shard_of_anti_magic" , nil, nil)) 
	hero.HasPickedAntiMagicShardAlready = true
	item:SetPurchaser(hero)
	item:SetShareability(ITEM_NOT_SHAREABLE )
    local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable ) -- Send the current stat info to JS

    SaveStashState(hero)
end


function master_shard_of_anti_magic:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: master_ability / OnAMAcquired
	OnAMAcquired({ caster = caster, ability = self, target = caster })
end
