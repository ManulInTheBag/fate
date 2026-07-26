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
	for i=0, 16 do
		local item = hero:GetItemInSlot(i) 
		if item ~= nil then
			item:EndCooldown()
		end
	end
end

function ResetMasterAbilities(hero)
	local masterUnit = hero.MasterUnit

	-- У героя может не оказаться мастера (упал его спавн-обработчик,
	-- игрок влетел криво): раньше цепочка вызовов без проверок роняла
	-- ВЕСЬ InitializeRound -> ни таймеров, ни раундов
	if not IsNotNull(masterUnit) then
		print("[Fate] WARNING: ResetMasterAbilities - no MasterUnit for " .. hero:GetName())
		return
	end
	for _, abilityName in pairs({ "cmd_seal_1", "cmd_seal_2", "cmd_seal_3",
		"cmd_seal_4", "master_presence_resonator", "master_intervention" }) do
		local ability = masterUnit:FindAbilityByName(abilityName)
		if ability then ability:EndCooldown() end
	end

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

function AddMasterAbility(master, name)
    --local ply = master:GetPlayerOwner()
    local attributeTable = FindAttribute(name)
    if attributeTable == nil then return end
    LoopThroughAttr(master, attributeTable)
	master:AddAbility("master_strength")
	master:AddAbility("master_agility")
	master:AddAbility("master_intelligence")
	master:AddAbility("master_damage")
	--master:AddAbility("master_armor")
	master:AddAbility("master_health_regen")
	master:AddAbility("master_mana_regen")
	master:AddAbility("master_gold_per_second_new")
	--master:AddAbility("master_movement_speed")
	master:AddAbility("master_2_passive")
end

function LoopThroughAttr(hero, attrTable)
	hero:RemoveAbility("twin_gate_portal_warp")
    for i=1, #attrTable do
        --print("Added " .. attrTable[i])
        if hero:AddAbility(attrTable[i]) == nil then
            -- нет такого блока в KV: раньше следующий print ронял весь
            -- OnHeroInGame (мастер оставался без статов и без пассивки)
            print("[Fate] WARNING: LoopThroughAttr - нет способности " .. tostring(attrTable[i]))
        end
    end
    if #attrTable == 5 then
    	hero:AddAbility("fate_empty1")
    	hero:SwapAbilities(attrTable[#attrTable], "fate_empty1", true, true)
   	end
    hero.ComboName = attrTable[#attrTable]
    --print(attrTable[#attrTable])
    --hero:SwapAbilities(attrTable[#attrTable], hero:GetAbilityByIndex(4):GetName(), true, true)
    --hero:SwapAbilities("master_close_list", "fate_empty1", true, true)
    local combo = hero:FindAbilityByName(attrTable[#attrTable])
    if combo then combo:StartCooldown(9999) end
    if #attrTable == 6 then
    	local slot5 = hero:GetAbilityByIndex(5)
    	if slot5 then
    		hero:SwapAbilities(hero.ComboName, slot5:GetAbilityName(), true, true)
    	end
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

-- Remove all abilities and save it to caster handle
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
	if oldEnemyTable then
		for i=1,#oldEnemyTable do
			for j=1, #newEnemyTable do
				if oldEnemyTable[i] == newEnemyTable[j] then 
					--print(" " .. newEnemyTable[j]:GetName() .. " has not been out of range since last presence detection")
					newEnemyTable[j].IsPresenceDetected = false
					break
				end
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

