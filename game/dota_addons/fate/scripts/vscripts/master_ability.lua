LinkLuaModifier("modifier_charges", "modifiers/modifier_charges", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_tiger_strike_tracker", "abilities/lishuwen/modifiers/modifier_tiger_strike_tracker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vortigern_ferocity", "abilities/arturia_alter/modifiers/modifier_vortigern_ferocity", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_a_scroll_sated", "items/modifiers/modifier_a_scroll_sated.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

ChargeBasedBuffs = {
	"modifier_tiger_strike_tracker",
	"modifier_vortigern_ferocity",
	--"modifier_a_scroll_sated",
	"modifier_doublespear_buidhe",
	"modifier_doublespear_dearg",
	--"modifier_quickdraw_cooldown"
}

function OnSeal1Start(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if caster:GetHealth() <= 2 then
		caster:SetMana(caster:GetMana()+3) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Master_Not_Enough_Health")
		return 
	end

	if not hero:IsAlive() or  ( IsRevoked(hero) and not hero:HasModifier("modifier_master_intervention")) then
		caster:SetMana(caster:GetMana()+3) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Revoked_Error")
		return
	end

	if hero:GetName() == "npc_dota_hero_doom_bringer" and RandomInt(1, 100) <= 35 then
		EmitGlobalSound("Shiro_Onegai")
	end

	hero.ServStat:useQSeal()

	-- Set master 2's mana 
	local master2 = hero.MasterUnit2
	master2:SetMana(master2:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	-- Set master's health
	caster:SetHealth(caster:GetHealth() - 2) 

	-- Particle
	hero:EmitSound("Misc.CmdSeal")
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_elder_titan/elder_titan_ancestral_spirit_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 2, hero:GetAbsOrigin())


	keys.ability:ApplyDataDrivenModifier(keys.caster, hero, "modifier_command_seal_1",{})
	keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_command_seal_1",{})
	caster.IsFirstSeal = true

	caster:FindAbilityByName("cmd_seal_1"):StartCooldown(60)
	Timers:CreateTimer({
		endTime = 20.0,
		callback = function()
		caster.IsFirstSeal = false
	end
	})
end

function ResetAbilities(hero)
	-- Reset all resetable abilities
	RemoveChargeModifiers(hero)
	for i=0, 23 do 
		local ability = hero:GetAbilityByIndex(i)
		if ability ~= nil then
			if ability.IsResetable ~= false then
				ability:EndCooldown()
			end
		else 
			break
		end
	end
end

function ResetItems(hero)
	-- Reset all items
	for i=0, 14 do
		local item = hero:GetItemInSlot(i) 
		if item ~= nil then
			item:EndCooldown()
		end
	end
end

function ResetMasterAbilities(hero)
	local masterUnit = hero.MasterUnit
	
	masterUnit:FindAbilityByName("cmd_seal_1"):EndCooldown()
	masterUnit:FindAbilityByName("cmd_seal_2"):EndCooldown()
	masterUnit:FindAbilityByName("cmd_seal_3"):EndCooldown()
	masterUnit:FindAbilityByName("cmd_seal_4"):EndCooldown()
	masterUnit:FindAbilityByName("master_presence_resonator"):EndCooldown()
	masterUnit:FindAbilityByName("master_intervention"):EndCooldown()

	--[[for i=0, 14 do
		local item = hero:GetItemInSlot(i) 
		if item ~= nil then
			item:EndCooldown()
		end
	end]]
end

function IncrementCharges(hero)
	if hero:HasModifier("modifier_charges") then
		local modifier = hero:FindModifierByName("modifier_charges")
		modifier:OnIntervalThink()
	end
end

function RemoveChargeModifiers(hero)
	for i=1, #ChargeBasedBuffs do
		--print(ChargeBasedBuffs[i])
        hero:RemoveModifierByName(ChargeBasedBuffs[i])        
    end
end

function OnSeal2Start(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	local currentMana = caster:GetMana()

	if caster:GetHealth() == 1 then
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Master_Not_Enough_Health")
		return 
	end

-- if hero:GetName() == "npc_dota_hero_night_stalker" then
-- 	keys.ability:EndCooldown() 
-- 				SendErrorMessage(caster:GetPlayerOwnerID(), "#NANAYA_INCIDENT")
-- 				return
-- 	end

	if caster:GetMana() <= 1 then
		if caster.IsFirstSeal and caster:GetMana() == 1 then
		else
			keys.ability:EndCooldown() 
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Not_Enough_Master_Mana")
			return 
		end
	end

	if not hero:IsAlive() or  ( IsRevoked(hero) and not hero:HasModifier("modifier_master_intervention")) then
		keys.ability:EndCooldown() 		
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Revoked_Error")
		return
	end
	hero.ServStat:useWSeal()
	-- pay mana cost
	caster:SetMana(caster:GetMana()-2)
	local master2 = hero.MasterUnit2
	master2:SetMana(caster:GetMana())
	-- pay health cost
	caster:SetHealth(caster:GetHealth()-1) 

	if hero:GetName() ~= "npc_dota_hero_night_stalker" then
		ResetAbilities(hero)
	end
	
	ResetItems(hero)
	IncrementCharges(hero)
 
 

	--[[if(hero:GetName() == "npc_dota_hero_windrunner" and hero.bIsFTAcquired) then
		local clone = hero.TempestDouble

		if(clone and clone:IsAlive()) then
			ResetAbilities(clone)
			ResetItems(clone)
		end
	end]]

	-- Particle
	hero:EmitSound("DOTA_Item.Refresher.Activate")
	local particle = ParticleManager:CreateParticle("particles/items2_fx/refresher.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())


	-- Set cooldown
	if caster.IsFirstSeal == true then
		keys.ability:EndCooldown()
		if currentMana ~= 1 then
			caster:SetMana(caster:GetMana()+1)  --refund 1 mana
			master2:SetMana(caster:GetMana())
		end
	else
		caster:FindAbilityByName("cmd_seal_1"):StartCooldown(30)
		caster:FindAbilityByName("cmd_seal_2"):StartCooldown(30)
		caster:FindAbilityByName("cmd_seal_3"):StartCooldown(30)
		caster:FindAbilityByName("cmd_seal_4"):StartCooldown(30)
		keys.ability:ApplyDataDrivenModifier(keys.caster, hero, "modifier_command_seal_2",{})
	end
end

function OnSeal3Start(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if caster:GetHealth() == 1 then
		caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Master_Not_Enough_Health")
		return 
	end

	if not hero:IsAlive() or  ( IsRevoked(hero) and not hero:HasModifier("modifier_master_intervention")) then
		caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Revoked_Error")
		return
	elseif hero:GetHealth() == hero:GetMaxHealth() then
		caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#At_Max_Health")
		return
	end

	if hero:GetName() == "npc_dota_hero_doom_bringer" and RandomInt(1, 100) <= 35 then
		EmitGlobalSound("Shiro_Onegai")
	end

	hero:EmitSound("DOTA_Item.UrnOfShadows.Activate")
	hero.ServStat:useESeal()
	-- Set master 2's mana 
	local master2 = hero.MasterUnit2
	master2:SetMana(master2:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	-- Set master's health
	caster:SetHealth(caster:GetHealth()-1) 

	local particle = ParticleManager:CreateParticle("particles/items2_fx/urn_of_shadows_heal_c.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
	hero:ApplyHeal(hero:GetMaxHealth(), hero)

	if caster.IsFirstSeal == true then
		keys.ability:EndCooldown()
	else
		caster:FindAbilityByName("cmd_seal_1"):StartCooldown(20)
		caster:FindAbilityByName("cmd_seal_2"):StartCooldown(20)
		caster:FindAbilityByName("cmd_seal_3"):StartCooldown(20)
		caster:FindAbilityByName("cmd_seal_4"):StartCooldown(20)
		keys.ability:ApplyDataDrivenModifier(keys.caster, hero, "modifier_command_seal_3",{})
	end
end

function OnSeal4Start(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero:GetName() == "npc_dota_hero_juggernaut" or hero:GetName() == "npc_dota_hero_shadow_shaman" then
		caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Recover_Mana")
		return 
	elseif caster:GetHealth() == 1 then
		caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Master_Not_Enough_Health")
		return 
	elseif not hero:IsAlive() or  ( IsRevoked(hero) and not hero:HasModifier("modifier_master_intervention"))  then
		caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Revoked_Error")
		return
	elseif hero:GetMana() == hero:GetMaxMana() then
		caster:SetMana(caster:GetMana()+1) 
		keys.ability:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#At_Max_Mana")
		return
	end
	hero.ServStat:useRSeal()
	-- Set master 2's mana 
	local master2 = hero.MasterUnit2
	master2:SetMana(master2:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	-- Set master's health
	caster:SetHealth(caster:GetHealth()-1) 

	if hero:GetName() == "npc_dota_hero_doom_bringer" and RandomInt(1, 100) <= 35 then
		EmitGlobalSound("Shiro_Onegai")
	end

	-- Particle
	hero:EmitSound("Hero_KeeperOfTheLight.ChakraMagic.Target")
	local particle = ParticleManager:CreateParticle("particles/items_fx/arcane_boots.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())


	hero:SetMana(hero:GetMaxMana()) 


	if caster.IsFirstSeal == true then
		keys.ability:EndCooldown()
	else
		caster:FindAbilityByName("cmd_seal_1"):StartCooldown(10)
		caster:FindAbilityByName("cmd_seal_2"):StartCooldown(10)
		caster:FindAbilityByName("cmd_seal_3"):StartCooldown(10)
		caster:FindAbilityByName("cmd_seal_4"):StartCooldown(10)
		keys.ability:ApplyDataDrivenModifier(keys.caster, hero, "modifier_command_seal_4",{})
	end
end

function OnPRStart(keys)
    local caster = keys.caster
    local ability = keys.ability
    local hero = PlayerResource:GetSelectedHeroEntity(caster:GetPlayerOwnerID())
    local heroTable = {}
    local target = nil

    local enemiesAlive = 0
    
    if not hero:IsAlive() then
    	return
    end

    LoopOverPlayers(function(player, playerID, playerHero)
    	if playerHero:IsAlive() and playerHero:GetTeamNumber() ~= hero:GetTeamNumber() then
    		enemiesAlive = enemiesAlive + 1
    	end
    end)

    LoopOverPlayers(function(player, playerID, playerHero)
		if playerHero:GetTeamNumber() ~= hero:GetTeamNumber() then
			if (playerHero:IsAlive() and CanBeDetected(playerHero))
			or (playerHero:IsAlive() and enemiesAlive == 1) then
				table.insert(heroTable, playerHero)
			end
		end
	end)

    if #heroTable > 0 then
    	if #heroTable == 1 then 
    		target = heroTable[1]
	    	MinimapEvent( hero:GetTeamNumber(), hero, target:GetAbsOrigin().x, target:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING, 2)
    	else
    		local nearestHero = heroTable[1]
    		local nearestDistance = (heroTable[1]:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D()

    		for i = 2, #heroTable do
	    		local distance = (heroTable[i]:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D()	    		

	    		if distance < nearestDistance then
	    			nearestHero = heroTable[i]
	    			nearestDistance = distance
	    		end
	    	end

	    	target = nearestHero
	    	

	    	--SpawnAttachedVisionDummy(hero, target, 100, 4, true)
	    	--SpawnAttachedVisionDummy(target, hero, 100, 4, true)    	

	    	MinimapEvent( hero:GetTeamNumber(), hero, target:GetAbsOrigin().x, target:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING, 2)
    	end    	
    	local target_master_ability = target.MasterUnit:FindAbilityByName(ability:GetName())

    	target:AddNewModifier(hero, nil, "modifier_vision_provider", { Duration = 2 })
	    hero:AddNewModifier(target, nil, "modifier_vision_provider", { Duration = 2 })
    end

    GameRules:SendCustomMessage("<font color='#58ACFA'>" .. FindName(hero:GetName()) .."</font>" ..  "<font color='#ff9900'>'s Master just used Presence Resonator!", 0, 0)

    if hero:GetName() == "npc_dota_hero_mirana" and hero.bIsIDAcquired then
    	ability:EndCooldown()
    	ability:StartCooldown(ability:GetCooldown(1)/2)
    end

    EmitGlobalSound("Resonator.Activate")
end

function AddMasterAbility(master, name)
    --local ply = master:GetPlayerOwner()
    local attributeTable = FindAttribute(name)
    if attributeTable == nil then return end
    LoopThroughAttr(master, attributeTable)
	master:AddAbility("master_strength")
	master:AddAbility("master_agility")
	master:AddAbility("master_intelligence")
	master:AddAbility("master_damage")
	master:AddAbility("master_armor")
	master:AddAbility("master_health_regen")
	master:AddAbility("master_mana_regen")
	master:AddAbility("master_movement_speed")
	master:AddAbility("master_2_passive")
end

function LoopThroughAttr(hero, attrTable)
	hero:RemoveAbility("twin_gate_portal_warp")
    for i=1, #attrTable do
        --print("Added " .. attrTable[i])
        hero:AddAbility(attrTable[i])
        print(hero:GetAbilityByIndex(i-1):GetName())
    end
    if #attrTable == 5 then
    	hero:AddAbility("fate_empty1")
    	hero:SwapAbilities(attrTable[#attrTable], "fate_empty1", true, true)
   	end
    hero.ComboName = attrTable[#attrTable]
    --print(attrTable[#attrTable])
    --hero:SwapAbilities(attrTable[#attrTable], hero:GetAbilityByIndex(4):GetName(), true, true)
    --hero:SwapAbilities("master_close_list", "fate_empty1", true, true)
    hero:FindAbilityByName(attrTable[#attrTable]):StartCooldown(9999) 
    if #attrTable == 6 then
    	hero:SwapAbilities(hero.ComboName, hero:GetAbilityByIndex(5):GetAbilityName(), true, true)
    end
end

function FindAttribute(name)
	local pepega = PlayerTables:GetAllTableValuesForReadOnly("hero_selection_heroes_data")
	local pepe_attributes = pepega[name].attributesandcombo
	local attributes = {
		pepe_attributes[1],
		pepe_attributes[2],
		pepe_attributes[3],
		pepe_attributes[4],
		pepe_attributes[5],
		pepe_attributes[6]
	}
    return attributes
end 

function OnAttributeListOpen(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	local attributeTable = FindAttribute(hero:GetName())


	caster:SwapAbilities(caster:GetAbilityByIndex(0):GetName(), attributeTable[1], true, true)
	caster:SwapAbilities(caster:GetAbilityByIndex(1):GetName(), attributeTable[2], true, true)
	caster:SwapAbilities(caster:GetAbilityByIndex(2):GetName(), attributeTable[3], true, true)
	caster:SwapAbilities(caster:GetAbilityByIndex(3):GetName(), "master_close_list", true, true)
	caster:SwapAbilities(caster:GetAbilityByIndex(4):GetName(), attributeTable[4], true, true)
	

	--if attributeTable[5] ~= nil then 

	if attributeTable.attrCount == 5 then 
		caster:SwapAbilities(caster:GetAbilityByIndex(5):GetName(), attributeTable[5], true, true)
	else 
		caster:SwapAbilities(caster:GetAbilityByIndex(5):GetName(), fate_empty1, true, true)
	end
end

function OnListClose(keys)
	local caster = keys.caster

	caster:SwapAbilities(caster:GetAbilityByIndex(0):GetName(), "master_attribute_list", true, true)
	caster:SwapAbilities(caster:GetAbilityByIndex(1):GetName(), "master_stat_list1", true, true)
	caster:SwapAbilities(caster:GetAbilityByIndex(2):GetName(), "master_stat_list2", true, true)
	caster:SwapAbilities(caster:GetAbilityByIndex(3):GetName(), "master_shard_of_holy_grail", true, true)
	caster:SwapAbilities(caster:GetAbilityByIndex(4):GetName(), caster.ComboName, true, true)
	caster:SwapAbilities(caster:GetAbilityByIndex(5):GetName(), "fate_empty2", true, true)
end

function OnStatList1Open(keys)
	local caster = keys.caster

	RemoveAllAbility(caster)
	caster:AddAbility("master_strength")
	caster:AddAbility("master_agility")
	caster:AddAbility("master_intelligence")
	caster:AddAbility("master_close_stat_list")
	caster:AddAbility("master_damage")
	caster:AddAbility("master_armor")
	caster:AddAbility(caster.ComboName)
	caster:GetAbilityByIndex(0):SetLevel(1) 
	caster:GetAbilityByIndex(1):SetLevel(1)
	caster:GetAbilityByIndex(2):SetLevel(1)
	caster:GetAbilityByIndex(3):SetLevel(1)
	caster:GetAbilityByIndex(4):SetLevel(1)
	caster:GetAbilityByIndex(5):SetLevel(1)
end

function OnStatList2Open(keys)
	local caster = keys.caster

	RemoveAllAbility(caster)
	caster:AddAbility("master_health_regen")
	caster:AddAbility("master_mana_regen")
	caster:AddAbility("master_movement_speed")
	caster:AddAbility("master_close_stat_list")
	caster:AddAbility("fate_empty1")
	caster:AddAbility("fate_empty2")
	caster:AddAbility(caster.ComboName)
	caster:GetAbilityByIndex(0):SetLevel(1) 
	caster:GetAbilityByIndex(1):SetLevel(1)
	caster:GetAbilityByIndex(2):SetLevel(1)
	caster:GetAbilityByIndex(3):SetLevel(1)
end

function OnShardOpen(keys)
	local caster = keys.caster

	RemoveAllAbility(caster)
	caster:AddAbility("master_shard_of_avarice")
	caster:AddAbility("master_shard_of_anti_magic")
	caster:AddAbility("master_shard_of_replenishment")
	caster:AddAbility("master_close_stat_list")
	caster:AddAbility("master_shard_of_prosperity")
	caster:AddAbility("fate_empty2")
	caster:AddAbility(caster.ComboName)
	caster:GetAbilityByIndex(0):SetLevel(1) 
	caster:GetAbilityByIndex(1):SetLevel(1)
	caster:GetAbilityByIndex(2):SetLevel(1)
	caster:GetAbilityByIndex(3):SetLevel(1)
	caster:GetAbilityByIndex(4):SetLevel(1)
end

function OnStatListClose(keys)
	local caster = keys.caster
	for i=0,5 do
		caster:RemoveAbility(caster:GetAbilityByIndex(i):GetName())
	end
	caster:RemoveAbility(caster.ComboName)
	for i=1, 20 do
		if caster.SavedList[i] == nil then break
		else
			caster:AddAbility(caster.SavedList[i])
		end
		LevelAllAbility(caster)
	end
end

-- Remove all abilities and save it to caster handle
function RemoveAllAbility(caster)
	local abilityList = {}
	for i=0,20 do
		if caster:GetAbilityByIndex(i) ~= nil then 
			local abil = caster:GetAbilityByIndex(i):GetName()
			abilityList[i+1] = abil
			caster:RemoveAbility(caster:GetAbilityByIndex(i):GetName())
		else 
			break
		end
	end
	caster.SavedList = abilityList
end

function OnStrengthGain(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero.STRgained == nil then
		hero.STRgained = 1
	else 
		if hero.STRgained < 50 then
			hero.STRgained = hero.STRgained + 1
		else
			caster:GiveMana(1)
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_50_Stats")
			return
		end
	end 
	hero.ServStat:addStr()
	hero:SetBaseStrength(hero:GetBaseStrength()+1) 
	hero:CalculateStatBonus(true)
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end

function OnAgilityGain(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero.AGIgained == nil then
		hero.AGIgained = 1
	else 
		if hero.AGIgained < 50 then
			hero.AGIgained = hero.AGIgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_50_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	hero.ServStat:addAgi()
	hero:SetBaseAgility(hero:GetBaseAgility()+1) 
	hero:CalculateStatBonus(true)
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end

function OnIntelligenceGain(keys)
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
		if hero.INTgained < 50 then
			hero.INTgained = hero.INTgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_50_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	hero.ServStat:addInt()
	hero:SetBaseIntellect(hero:GetBaseIntellect()+1) 
	hero:CalculateStatBonus(true)
	
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end

function OnDamageGain(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero.DMGgained == nil then
		hero.DMGgained = 1
	else 
		if hero.DMGgained < 50 then
			hero.DMGgained = hero.DMGgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_50_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	hero.ServStat:addAtk()
	local primaryStat = 0
	local attr = hero:GetPrimaryAttribute() -- 0 strength / 1 agility / 2 intelligence
	if attr == 0 then
		primaryStat = hero:GetStrength()
	elseif attr == 1 then
		primaryStat = hero:GetAgility()
	elseif attr == 2 then
		primaryStat = hero:GetIntellect()
	elseif attr == 3 then
		primaryStat = (hero:GetStrength() + hero:GetAgility() + hero:GetIntellect())*0.7
	end

	hero:SetBaseDamageMax(hero:GetBaseDamageMax() - math.floor(primaryStat) + 3)
	hero:SetBaseDamageMin(hero:GetBaseDamageMin() - math.floor(primaryStat) + 3)
	hero:CalculateStatBonus(true)

	--[[local minDmg = hero:GetBaseDamageMin() - primaryStat
	local maxDmg = hero:GetBaseDamageMax() - primaryStat

	print("Current base damage : " .. minDmg  .. " to " .. maxDmg)]]
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end

function OnArmorGain(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero.ARMORgained == nil then
		hero.ARMORgained = 1
	else 
		if hero.ARMORgained < 50 then
			hero.ARMORgained = hero.ARMORgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_50_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	hero.ServStat:addArmor()
 	--hero:SetPhysicalArmorBaseValue( 100) --actually this line is useless, appears to be dependent on scripts/npc/attributes.txt but I am too lazy to understand why
	hero:CalculateStatBonus(true)
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end

function OnHPRegenGain(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero.HPREGgained == nil then
		hero.HPREGgained = 1
	elseif hero.BaseHPRegen == nil then
		hero.BaseHPRegen = hero:GetBaseHealthRegen()
	else 
		if hero.HPREGgained < 50 then
			hero.HPREGgained = hero.HPREGgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_50_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	hero.ServStat:addHPregen()
	-- Bandaid balance for health regen.
	hero:SetBaseHealthRegen(hero.BaseHPRegen + (3.0 * hero.HPREGgained)) --down here attributes.txt is useless, and this line is working.
	hero:CalculateStatBonus(true)

	--print(hero:GetHealthRegenMultiplier())
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end

function OnManaRegenGain(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero:GetName() == "npc_dota_hero_juggernaut" then
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Acquire_Mana_Regeneration")
		caster:GiveMana(1)
		return
	end

	if hero.MPREGgained == nil then
		hero.MPREGgained = 1
	elseif hero.BaseMPRegen == nil then
		hero.BaseMPRegen = hero:GetBaseManaRegen()
	else 
		if hero.MPREGgained < 50 then
			hero.MPREGgained = hero.MPREGgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_50_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	hero.ServStat:addMPregen()	
	hero:SetBaseManaRegen(hero.BaseMPRegen + (1.75 * hero.MPREGgained)) --down here attributes.txt is useless, and this line is working.
	hero:CalculateStatBonus(true)

	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end

function OnMovementSpeedGain(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if hero:GetName() == "npc_dota_hero_drow_ranger" then
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Acquire_Speed")
		caster:GiveMana(1)
		return
	end

	if hero.MSgained == nil then
		hero.MSgained = 1
	else 
		if hero.MSgained < 50 then
			hero.MSgained = hero.MSgained + 1
		else
			SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Get_Over_50_Stats")
			caster:GiveMana(1)
			return
		end
	end 
	hero.ServStat:addMS()
	hero:SetBaseMoveSpeed(hero:GetBaseMoveSpeed() + 5) 
	hero:CalculateStatBonus(true)
	-- Set master 1's mana 
	local master1 = hero.MasterUnit
	master1:SetMana(master1:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable )
end

function OnAvariceAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	if hero.ShardAmount == 0 or hero.ShardAmount == nil then 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Acquire_Shard")
		return 
	else 
		hero.ShardAmount = hero.ShardAmount - 1
		hero.ServStat:getS1()
	end


	if hero.AvariceCount == nil then 
		hero.AvariceCount = 1
	else
		hero.AvariceCount = hero.AvariceCount + 1
	end

	-- distribute gold
	local teamTable = {}
	for i=0, 13 do
		local player = PlayerResource:GetPlayer(i)
		if player ~= nil then 
			hero = PlayerResource:GetPlayer(i):GetAssignedHero()
			if hero:GetTeam() == caster:GetTeam() then
				table.insert(teamTable, hero)
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

function OnAMAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	if hero.ShardAmount == 0 or hero.ShardAmount == nil then 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Acquire_Shard")
		return
	else 
		hero.ShardAmount = hero.ShardAmount - 1
		hero.ServStat:getS2()
	end

	hero:AddItem(CreateItem("item_shard_of_anti_magic" , nil, nil)) 
    local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable ) -- Send the current stat info to JS

    SaveStashState(hero)
end

function OnReplenishmentAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	if hero.ShardAmount == 0 or hero.ShardAmount == nil then 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Acquire_Shard")
		return
	else 
		hero.ShardAmount = hero.ShardAmount - 1
		hero.ServStat:getS3()
	end
	hero:AddItem(CreateItem("item_shard_of_replenishment" , nil, nil)) 
    local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable ) -- Send the current stat info to JS

    SaveStashState(hero)
end

function OnProsperityAcquired(keys)
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


	--[[for i=1,4 do
		local level = hero:GetLevel()
		if level ~= 24 then
			hero:AddExperience(_G.XP_PER_LEVEL_TABLE[level], false, false)
			--hero:AddExperience(XP_BOUNTY_PER_LEVEL_TABLE[killedUnit:GetLevel()]/realHeroCount, false, false)
		else
			master:SetMana(master:GetMana() + 3)
			master2:SetMana(master:GetMana())		
		end
	end]]


	--[[
	master:SetMana(master:GetMana()+20)
	master2:SetMana(master:GetMana())]]
	master:SetMaxHealth(master:GetMaxHealth() + 3) 
	master:SetHealth(master:GetHealth() + 3)
	master2:SetMaxHealth(master:GetMaxHealth()) 
	master2:SetHealth(master:GetHealth())
    local statTable = CreateTemporaryStatTable(hero)
    CustomGameEventManager:Send_ServerToPlayer( hero:GetPlayerOwner(), "servant_stats_updated", statTable ) -- Send the current stat info to JS
end

LinkLuaModifier("modifier_sasaki_vision", "abilities/sasaki/modifiers/modifier_sasaki_vision", LUA_MODIFIER_MOTION_NONE)

function OnPresenceDetectionThink(keys)
	local caster = keys.caster
	local hasSpecialPresenceDetection = false
	if caster:GetName() == "npc_dota_hero_juggernaut" and caster.IsEyeOfSerenityAcquired and caster.IsEyeOfSerenityActive then 
		hasSpecialPresenceDetection = true
	elseif caster:GetName() == "npc_dota_hero_shadow_shaman" and caster.IsEyeForArtAcquired then
		hasSpecialPresenceDetection = true
	elseif caster:GetName() == "npc_dota_hero_beastmaster" and caster.DiscernPoorAttribute then
		hasSpecialPresenceDetection = true
	end

	if GameRules:GetGameTime() < RoundStartTime + 60 then
		if hasSpecialPresenceDetection == false then return end 
	end

	local oldEnemyTable = caster.PresenceTable
	local newEnemyTable = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 2500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)

	-- Flag everyone in range as true before comparing two tables
	for i=1, #newEnemyTable do
		newEnemyTable[i].IsPresenceDetected = true
	end

	-- If enemy has not moved out of range since last presence detection, flag them as false
	for i=1,#oldEnemyTable do
		for j=1, #newEnemyTable do
			if oldEnemyTable[i] == newEnemyTable[j] then 
				--print(" " .. newEnemyTable[j]:GetName() .. " has not been out of range since last presence detection")
				newEnemyTable[j].IsPresenceDetected = false
				break
			end
		end
	end

	-- Do the ping for everyone with IsPresenceDetected marked as true
	-- Filter TA from ping if he has improved presence concealment attribute
	--and not (enemy:GetName() == "npc_dota_hero_bounty_hunter" and enemy.IsPCImproved and (enemy:HasModifier("modifier_ta_invis") or enemy:HasModifier("modifier_ambush")))
	-- Filter EA from ping
	--and not (enemy:GetName() == "npc_dota_hero_bloodseeker" and enemy:HasModifier("modifier_lishuwen_concealment"))
	for i=1, #newEnemyTable do
		local enemy = newEnemyTable[i]
		if enemy:IsRealHero() and not enemy:IsIllusion() and CanBeDetected(enemy) then
			if enemy.IsPresenceDetected == true or enemy.IsPresenceDetected == nil then
				--print("Pinged " .. enemy:GetPlayerOwnerID() .. " by player " .. caster:GetPlayerOwnerID())
				MinimapEvent( caster:GetTeamNumber(), caster, enemy:GetAbsOrigin().x, enemy:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 2 )
				SendErrorMessage(caster:GetPlayerOwnerID(), "#Presence_Detected")
				local dangerping = ParticleManager:CreateParticleForPlayer("particles/ui_mouseactions/ping_world.vpcf", PATTACH_ABSORIGIN, caster, PlayerResource:GetPlayer(caster:GetPlayerID()))

				ParticleManager:SetParticleControl(dangerping, 0, enemy:GetAbsOrigin())
				ParticleManager:SetParticleControl(dangerping, 1, enemy:GetAbsOrigin())
				
				--GameRules:AddMinimapDebugPoint(caster:GetPlayerID(), enemy:GetAbsOrigin(), 255, 0, 0, 500, 3.0)
				if not caster.bIsAlertSoundDisabled then
					CustomGameEventManager:Send_ServerToPlayer(caster:GetPlayerOwner(), "emit_presence_sound", {sound="Misc.BorrowedTime"})
				end
				-- Process Eye of Serenity attribute
				if caster:GetName() == "npc_dota_hero_juggernaut" and caster.IsEyeOfSerenityAcquired == true and caster.IsEyeOfSerenityActive == true then
					FAEyeAttribute(caster, enemy)
				end
				-- Process Eye for Art attribute
				local hPlayer = caster:GetPlayerOwner()
				if IsValidEntity(hPlayer) and not hPlayer:IsNull() then
					if caster:GetName() == "npc_dota_hero_shadow_shaman" and caster.IsEyeForArtAcquired == true then
						local choice = math.random(1,3)
						if choice == 1 then
							Say(hPlayer, FindName(enemy:GetName()) .. ", dare to enter the demon's lair on your own?", true)
						elseif choice == 2 then
							Say(hPlayer, "This presence...none other than " .. FindName(enemy:GetName()) .. "!", true)
						elseif choice == 3 then
							Say(hPlayer, "Come forth, " .. FindName(enemy:GetName()) .. "...The fresh terror awaits you!", true)
						end
					end
				end
			end
		end
	end
	caster.PresenceTable = newEnemyTable
end


-- Scrapped it(can have only 1 instance of AddMinimapDebugPoint at time)
function CustomPing(playerid, location)
	print("Custom Ping Issued")
	GameRules:AddMinimapDebugPoint(playerid, location, 255, 0, 0, 300, 3.0)
end 

function FAEyeAttribute(caster, enemy)
	enemy:AddNewModifier(caster, nil, "modifier_sasaki_vision", { Duration = 10 })

	--local eye = ParticleManager:CreateParticleForPlayer("particles/items_fx/dust_of_appearance_true_sight.vpcf", PATTACH_ABSORIGIN, enemy, PlayerResource:GetPlayer(caster:GetPlayerID()))
	--[[local eye = ParticleManager:CreateParticle("particles/items_fx/dust_of_appearance_true_sight.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)

	ParticleManager:SetParticleControl(eye, 0, enemy:GetAbsOrigin())

	local eyedummy = CreateUnitByName("visible_dummy_unit", enemy:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	eyedummy:SetDayTimeVisionRange(500)
	eyedummy:SetNightTimeVisionRange(500)
	eyedummy:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 100}) 
	

	local eyedummypassive = eyedummy:FindAbilityByName("dummy_visible_unit_passive")
	eyedummypassive:SetLevel(1)

	local eyeCounter = 0

	Timers:CreateTimer(function() 
		if eyeCounter > 3.0 then DummyEnd(eyedummy) return end
		eyedummy:SetAbsOrigin(enemy:GetAbsOrigin()) 
		eyeCounter = eyeCounter + 0.2
		return 0.2
	end)]]
end

function OnHeroRespawn(keys)
	local caster = keys.caster
	local ability = keys.ability
	if _G.GameMap == "fate_trio_rumble_3v3v3v3" or _G.GameMap == "fate_ffa" then
		caster:ModifyGold(2000, true, 0) 
		giveUnitDataDrivenModifier(keys.caster, keys.caster, "spawn_invulnerable", 3.0)
	end
	FindClearSpaceForUnit( caster, caster:GetAbsOrigin(), true )
end

function OnComboCheck(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if caster:HasModifier("combo_cooldown") then
		caster:RemoveModifierByName("combo_cooldown")
	end
	if caster:HasModifier("combo_unavailable") then
		caster:RemoveModifierByName("combo_unavailable")
	end

	local comboAvailability = GetComboAvailability(hero)
	if comboAvailability == -1 then
		ability:ApplyDataDrivenModifier(caster, caster, "combo_unavailable", {duration=1})
	elseif comboAvailability > 0 then
		ability:ApplyDataDrivenModifier(caster, caster, "combo_cooldown", {duration=comboAvailability})
	end
end
