iskander_ionioi = class({})

LinkLuaModifier("modifier_inside_marble", "abilities/general/modifiers/modifier_inside_marble", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_iskander_units_bonus_dmg", "abilities/iskandar/iskander_ionioi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_iskander_units_bonus_dmg_clickable", "abilities/iskandar/iskander_ionioi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_army_of_the_king_death_checker", "abilities/iskandar/iskander_ionioi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sanya_combo_cd", "abilities/iskandar/iskander_ionioi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ubw_chronosphere", "abilities/emiya/emiya_unlimited_bladeworks", LUA_MODIFIER_MOTION_NONE)

modifier_sanya_combo_cd = class({})

function modifier_sanya_combo_cd:IsHidden()
    return false 
end

function modifier_sanya_combo_cd:RemoveOnDeath()
    return false
end

function modifier_sanya_combo_cd:IsDebuff()
    return true 
end

function modifier_sanya_combo_cd:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end


aotkTargets = nil
aotkCenter = Vector(288,-4564, 261)
ubwCenter = Vector(5926, -4837, 222)
aotkCasterPos = nil

function iskander_ionioi:CastFilterResult()
	if self:GetCaster():HasModifier("modifier_gordius_wheel") then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function iskander_ionioi:GetCustomCastError()
	return "Cant use while riding"
end

function iskander_ionioi:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(1))
	caster:AddNewModifier(caster, self, "modifier_sanya_combo_cd", {duration =  self:GetCooldown(-1)})
    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    for q,w in pairs(targets) do
    	giveUnitDataDrivenModifier(caster, w, "pause_sealdisabled", 2.5) 
        giveUnitDataDrivenModifier(caster, w, "rooted", 2.5)
        giveUnitDataDrivenModifier(caster, w, "locked", 2.5)
    end


	StartAnimation(caster, {duration=2, activity=ACT_DOTA_CAST_ABILITY_3, rate=0.8})
	if caster:GetAbsOrigin().y < -3100 then
		FireGameEvent( 'custom_error_show', { player_ID = caster:GetPlayerOwnerID(), _error = "Already Within Reality Marble" } )
		caster:SetMana(caster:GetMana() + 800)
		self:EndCooldown()
		return
	end
	if caster.IsRiding then 
		FireGameEvent( 'custom_error_show', { player_ID = caster:GetPlayerOwnerID(), _error = "Cant cast while riding" } )
		caster:GiveMana(800)
		self:EndCooldown() 
		return 
	end
	LoopOverPlayers(function(player, playerID, playerHero)
       	if playerHero.gachi == true then
           	CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound = "one_piece_is_real"})
       	end
    end)
	caster.AOTKSoldiers = {}
	if caster.AOTKSoldierCount == nil then caster.AOTKSoldierCount = 0 end --initialize soldier count if its not made yet
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 2)
	EmitGlobalSound("Iskander.AOTK")

	local aotkAbilityHandle = self

	-- particle
	--CreateGlobalParticle("particles/custom/iskandar/iskandar_aotk.vpcf", caster:GetAbsOrigin(), 0)
	CreateGlobalParticle("particles/custom/iskandar/iskandar_aotk.vpcf", {[0] = caster:GetAbsOrigin()}, 2)

	local firstRowPos = aotkCenter + Vector(300, 0,0) 
	local maharajaPos = aotkCenter + Vector(600, 0,0)

	local infantrySpawnCounter = 0
	local soldierCount = 6
	if caster.IsBeyondTimeAcquired then
		soldierCount = 8
	end

	Timers:CreateTimer(function()
		if infantrySpawnCounter == soldierCount then return end
		local soldier = CreateUnitByName("iskander_infantry", firstRowPos + Vector(0, math.pow(-1,(infantrySpawnCounter+1))* infantrySpawnCounter*100,0), true, nil, nil, caster:GetTeamNumber())
		soldier:SetForwardVector(Vector(-1,0,0))
		--soldier:AddNewModifier(caster, nil, "modifier_phased", {})
		soldier:SetOwner(caster)
		soldier.IsAOTKSoldier = true
		--soldier:SetForwardVector(Vector(-0.999991, 0.004154, -0.000000))
		table.insert(caster.AOTKSoldiers, soldier)
		caster.AOTKSoldierCount = caster.AOTKSoldierCount + 1
		soldier:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg", {duration = 18, dmg = self:GetSpecialValueFor("infantry_bonus_damage")})
		infantrySpawnCounter = infantrySpawnCounter+1
		return 0.03
	end)

	local archerSpawnCounter1 = 0
	Timers:CreateTimer(0.99, function()
		if archerSpawnCounter1 == (soldierCount / 2) then return end
		local soldier = CreateUnitByName("iskander_archer", aotkCenter + Vector(800, 700 - archerSpawnCounter1*100, 0), true, nil, nil, caster:GetTeamNumber())
		--soldier:AddNewModifier(caster, nil, "modifier_phased", {})
		soldier:SetOwner(caster)
		soldier.IsAOTKSoldier = true
		soldier:SetForwardVector(Vector(-1,0,0))
		--soldier:SetForwardVector(Vector(-0.999991, 0.004154, -0.000000))
		table.insert(caster.AOTKSoldiers, soldier)
		caster.AOTKSoldierCount = caster.AOTKSoldierCount + 1
		soldier:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg", {duration = 18, dmg = self:GetSpecialValueFor("archer_bonus_damage")})
		archerSpawnCounter1 = archerSpawnCounter1+1
		return 0.03
	end)

	local archerSpawnCounter2 = 0
	Timers:CreateTimer(1.49, function()
		if archerSpawnCounter2 == (soldierCount / 2) then return end
		local soldier = CreateUnitByName("iskander_archer", aotkCenter + Vector(800, -700 + archerSpawnCounter2*100, 0), true, nil, nil, caster:GetTeamNumber())
		--soldier:AddNewModifier(caster, nil, "modifier_phased", {})
		soldier:SetOwner(caster)
		soldier.IsAOTKSoldier = true
		soldier:SetForwardVector(Vector(-1,0,0))
		--soldier:SetForwardVector(Vector(-0.999991, 0.004154, -0.000000))
		table.insert(caster.AOTKSoldiers, soldier)
		caster.AOTKSoldierCount = caster.AOTKSoldierCount + 1
		soldier:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg", {duration = 18, dmg = self:GetSpecialValueFor("archer_bonus_damage")})

		archerSpawnCounter2 = archerSpawnCounter2+1
		return 0.03
	end)
	
	Timers:CreateTimer({
		endTime = 2,
		callback = function()
		if caster:IsAlive() then 
		    caster.AOTKLocator = CreateUnitByName("ping_sign2", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
		    caster.AOTKLocator:FindAbilityByName("ping_sign_passive"):SetLevel(1)
		    caster.AOTKLocator:AddNewModifier(caster, caster, "modifier_kill", {duration = 16.5})
		    caster.AOTKLocator:SetAbsOrigin(caster:GetAbsOrigin())
			self:OnAOTKStart()
			
		end
	end
	})

	
	
end

--[[what the actual fuck am I witnessing here? Like, just why?!!!!!!!!!!!
ManulInTheBag, 09.06.2022]]
--- IDK but not gonna fix OR READ all of this LOL. Just change what i actually need to change. Zlodemon, 04.14.2023



function iskander_ionioi:OnUpgrade()
	local caster = self:GetCaster()
	local ability = self
	caster:FindAbilityByName("iskandar_arrow_bombard"):SetLevel(ability:GetLevel())
	--caster:FindAbilityByName("iskander_summon_hephaestion"):SetLevel(ability:GetLevel())
end

function iskander_ionioi:OnAOTKStart()
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local ability = self
	local ability = self
	local radius = self:GetSpecialValueFor("radius") 
	caster.IsAOTKActive = true
	caster:EmitSound("Ability.SandKing_SandStorm.loop")
	CreateUITimer("Army of the King", 16, "aotk_timer")
	--aotkQuest = StartQuestTimer("aotkTimerQuest", "Army of the King", 16) -- Start timer

	local aotkAbilityHandle = self

	-- Swap abilities
	if(caster:GetAbilityByIndex(4):GetName() == "fate_empty1") then
		caster:SwapAbilities("iskander_ionioi", "fate_empty1", true, false)
	 end
	caster:SwapAbilities("iskander_ionioi", "iskander_summon_hephaestion", false, true)
	--caster:SwapAbilities("iskandar_gordius_wheel", "iskandar_arrow_bombard", false, true)
	if caster.IsBeyondTimeAcquired then
		caster:SwapAbilities("iskandar_charisma", "iskander_summon_waver", false, true) 
	else 
		caster:SwapAbilities("iskandar_charisma", "fate_empty4", false, true) 
	end

	-- Find eligible targets
	aotkTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius
            , DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	caster.IsAOTKDominant = true

	-- Remove any dummy or hero in jump
	i = 1
	while i <= #aotkTargets do
		if IsValidEntity(aotkTargets[i]) and not aotkTargets[i]:IsNull() then
			ProjectileManager:ProjectileDodge(aotkTargets[i]) -- Disjoint particles
			if aotkTargets[i]:HasModifier("jump_pause") or string.match(aotkTargets[i]:GetUnitName(),"dummy") or aotkTargets[i]:HasModifier("spawn_invulnerable") and aotkTargets[i] ~= caster then 
				table.remove(aotkTargets, i)
				i = i - 1
			end
		end
		i = i + 1
	end

	if caster:GetAbsOrigin().x > 3000 and caster:GetAbsOrigin().y < -2000 then
		caster.IsAOTKDominant = false
	end


 	-- spawn sight dummy
	local truesightdummy = CreateUnitByName("sight_dummy_unit", aotkCenter, false, caster, caster, caster:GetTeamNumber())
	truesightdummy:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 3000}) 
	truesightdummy:AddNewModifier(caster, caster, "modifier_kill", {duration = 16}) 
	truesightdummy:SetDayTimeVisionRange(2500)
	truesightdummy:SetNightTimeVisionRange(2500)
	local unseen = truesightdummy:FindAbilityByName("dummy_unit_passive")
	unseen:SetLevel(1)

	-- Summon soldiers
	local marbleCenter = 0
	if caster.IsAOTKDominant then marbleCenter = aotkCenter else marbleCenter = ubwCenter end
	local firstRowPos = marbleCenter + Vector(300, -500,0) 
	local maharajaPos = marbleCenter + Vector(600, 0,0)

	for i=1, #caster.AOTKSoldiers do
		local soldierHandle = caster.AOTKSoldiers[i]
		local soldierPos = caster.AOTKSoldiers[i]:GetAbsOrigin()
		local diffFromCenter = soldierPos - aotkCenter
		soldierHandle:SetAbsOrigin(diffFromCenter + marbleCenter)
	end
	local maharaja = CreateUnitByName("iskander_maharaja", maharajaPos, true, nil, nil, caster:GetTeamNumber())
	maharaja:SetControllableByPlayer(caster:GetPlayerID(), true)
	maharaja:SetOwner(caster)
	maharaja:SetForwardVector(Vector(-1,0,0))
	maharaja:FindAbilityByName("iskander_battle_horn"):SetLevel(aotkAbilityHandle:GetLevel())
	table.insert(caster.AOTKSoldiers, maharaja)
	caster.AOTKSoldierCount = caster.AOTKSoldierCount + 1
	maharaja:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg_clickable", {duration = 16.5, dmg = self:GetSpecialValueFor("maharaja_bonus_damage")})
	if not caster.IsAOTKDominant then return end -- If Archer's UBW is already active, do not teleport units


	aotkTargetLoc = {}
	local diff = nil
	local aotkTargetPos = nil
	aotkCasterPos = caster:GetAbsOrigin()

	-- record location of units and move them into UBW(center location : 6000, -4000, 200)
	for i=1, #aotkTargets do
		if IsValidEntity(aotkTargets[i]) and not aotkTargets[i]:IsNull() then
			if aotkTargets[i]:GetName() ~= "npc_dota_ward_base" then
				aotkTargets[i]:RemoveModifierByName("modifier_aestus_domus_aurea_enemy")
				aotkTargets[i]:RemoveModifierByName("modifier_aestus_domus_aurea_ally")
				aotkTargets[i]:RemoveModifierByName("modifier_aestus_domus_aurea_nero")

				if aotkTargets[i]:GetTeamNumber() ~= caster:GetTeamNumber() then
					aotkTargets[i]:AddNewModifier(caster, self, "modifier_silence", {duration = 2})
				end
				
				if aotkTargets[i]:GetName() == "npc_dota_hero_bounty_hunter" or aotkTargets[i]:GetName() == "npc_dota_hero_riki" then
	                aotkTargets[i]:AddNewModifier(caster, ability, "modifier_inside_marble", { Duration = 16 })
	            end

				aotkTargetPos = aotkTargets[i]:GetAbsOrigin()
		        aotkTargetLoc[i] = aotkTargetPos
		        diff = (aotkCasterPos - aotkTargetPos)

		        local forwardVec = aotkTargets[i]:GetForwardVector()
		        -- scale position difference to size of AOTK
		        diff.y = diff.y * 0.7
		        if aotkTargets[i]:GetTeam() ~= caster:GetTeam() then 
		        	if diff.x <= 0 then 
		        		diff.x = diff.x * -1 
		        		forwardVec.x = forwardVec.x * -1
		        	end
		        elseif aotkTargets[i]:GetTeam() == caster:GetTeam() then
		        	if diff.x >= 0 then 
		        		diff.x = diff.x * -1
		        		forwardVec.x = forwardVec.x * -1
		        	end
		        end
		        aotkTargets[i]:SetAbsOrigin(aotkCenter - diff)
				FindClearSpaceForUnit(aotkTargets[i], aotkTargets[i]:GetAbsOrigin(), true)
				Timers:CreateTimer(0.1, function() 
					if caster:IsAlive() and IsValidEntity(aotkTargets[i]) then
						aotkTargets[i]:AddNewModifier(aotkTargets[i], aotkTargets[i], "modifier_camera_follow", {duration = 1.0})
					end
				end)
				Timers:CreateTimer(0.033, function()
					if caster:IsAlive() and IsValidEntity(aotkTargets[i]) then
						ExecuteOrderFromTable({
							UnitIndex = aotkTargets[i]:entindex(),
							OrderType = DOTA_UNIT_ORDER_STOP,
							Queue = false
						})
						aotkTargets[i]:SetForwardVector(forwardVec)
					end
				end)
			end
		end
    end
	

	caster:AddNewModifier(caster, self, "modifier_army_of_the_king_death_checker", {duration = 16})
	EmitGlobalSound("Iskander.Annihilate")
	Timers:CreateTimer(1.5, function()
		EmitGlobalSound("Iskander.Aye")
	end)
	EmitGlobalSound("Hero_LegionCommander.PressTheAttack")
	StartAnimation(caster, {duration=2, activity=ACT_DOTA_CAST_ABILITY_1, rate=0.5})

end

if(IsServer()) then
function iskander_ionioi:OnAOTKDeath()
	local caster = self:GetCaster()
	Timers:CreateTimer(0.066, function()
		self:EndAOTK(caster)
	end)
end
end

function iskander_ionioi:EndAOTK(caster)
	if caster.IsAOTKActive == false then return end
	print("AOTK ended")
	-- Revert abilities

	caster:SwapAbilities("fate_empty1", "iskander_summon_hephaestion", true, false)
	--caster:SwapAbilities("iskandar_gordius_wheel", "iskandar_arrow_bombard", false, true)
	caster:SwapAbilities("iskandar_charisma", caster:GetAbilityByIndex(3):GetName(), true, false) 
	CreateUITimer("Army of the King", 0, "aotk_timer")
	caster.IsAOTKActive = false
	if not caster.AOTKLocator:IsNull() and IsValidEntity(caster.AOTKLocator) then
		caster.AOTKLocator:RemoveSelf()
	end

	StopSoundEvent("Ability.SandKing_SandStorm.loop", caster)

	self:CleanUpHammer(caster)

	-- Remove soldiers 
	for i=1, #caster.AOTKSoldiers do
		if IsValidEntity(caster.AOTKSoldiers[i]) and not caster.AOTKSoldiers[i]:IsNull() then
			if caster.AOTKSoldiers[i]:IsAlive() then
				caster.AOTKSoldiers[i]:ForceKill(true)
			end
		end
	end

    local units = FindUnitsInRadius(caster:GetTeam(), aotkCenter, nil, 1800, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
 
    for i=1, #units do
    	if IsValidEntity(units[i]) and not units[i]:IsNull() then
			if string.match(units[i]:GetUnitName(),"dummy") then 
				table.remove(units, i)
			end
		end
	end

    for i=1, #units do
    	if IsValidEntity(units[i]) and not units[i]:IsNull() then 
	    	ProjectileManager:ProjectileDodge(units[i])
	    	-- If unit is Archer and UBW is active, deactive it as well

	    	units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_enemy")
			units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_ally")
			units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_nero")

			if units[i]:GetName() == "npc_dota_hero_bounty_hunter" or units[i]:GetName() == "npc_dota_hero_riki" then
                units[i]:RemoveModifierByName("modifier_inside_marble")
            end

			if units[i]:GetName() == "npc_dota_hero_ember_spirit" and units[i]:HasModifier("modifier_unlimited_bladeworks") then
				units[i]:RemoveModifierByName("modifier_unlimited_bladeworks")
			end
			if units[i]:HasModifier("modifier_annihilate_mute") then
				units[i]:RemoveModifierByName("modifier_annihilate_mute")
			end

	    	local IsUnitGeneratedInAOTK = true
	    	if aotkTargets ~= nil then
		    	for j=1, #aotkTargets do
		    		if IsValidEntity(aotkTargets[j]) and not aotkTargets[j]:IsNull() then
			    		if units[i] == aotkTargets[j] then
			    			if aotkTargets[j] ~= nil then
			    				units[i]:SetAbsOrigin(aotkTargetLoc[j]) 
			    			end
			    			FindClearSpaceForUnit(units[i], units[i]:GetAbsOrigin(), true)
			    			Timers:CreateTimer(0.1, function() 
			    				if IsValidEntity(units[i]) and not units[i]:IsNull() then 
									units[i]:AddNewModifier(units[i], units[i], "modifier_camera_follow", {duration = 1.0})
								end
							end)
			    			IsUnitGeneratedInAOTK = false
			    			break 
			    		end
			    	end
		    	end 
	    	end
	    	if IsUnitGeneratedInAOTK then
	    		diff = aotkCenter - units[i]:GetAbsOrigin()
	    		if aotkCasterPos ~= nil then 
	    			units[i]:SetAbsOrigin(aotkCasterPos - diff * 0.7)
	    		end
	    		FindClearSpaceForUnit(units[i], units[i]:GetAbsOrigin(), true) 
				Timers:CreateTimer(0.1, function() 
					if IsValidEntity(units[i]) and not units[i]:IsNull() then
						units[i]:AddNewModifier(units[i], units[i], "modifier_camera_follow", {duration = 1.0})
					end
				end)
	    	end
	    end
    end

    aotkTargets = nil
    aotkTargetLoc = nil

    Timers:RemoveTimer("aotk_timer")
end

function iskander_ionioi:CleanUpHammer(hero)
    local hammerTimers = hero.HammerTimers
    if hammerTimers ~= nil then
        for i=1,hammerTimers do
            Timers:RemoveTimer("hammer_charge" .. i)
        end
    end
    local oldCavalryTable = hero.CavalryTable
    if oldCavalryTable ~= nil then
        for i=1,#oldCavalryTable do
	    local unit = oldCavalryTable[i]
	    if unit ~= nil and not unit:IsNull() then
                unit:PreventDI(false)
                unit:SetPhysicsVelocity(Vector(0,0,0))
                unit:OnPhysicsFrame(nil)
                unit:RemoveModifierByName("round_pause")
	    end
        end
    end

    hero.CavalryTable = nil
    hero.HammerTimers= nil
end

modifier_iskander_units_bonus_dmg = class({})


function modifier_iskander_units_bonus_dmg:DeclareFunctions()
	return { MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE}
end

function modifier_iskander_units_bonus_dmg:OnCreated(args)
	self.bonusdmg = args.dmg
end


function modifier_iskander_units_bonus_dmg:GetModifierBaseAttack_BonusDamage()	
	return self.bonusdmg
end

function modifier_iskander_units_bonus_dmg:RemoveOnDeath() return true end

function modifier_iskander_units_bonus_dmg:CheckState()
    local state = { 
                    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
                    [MODIFIER_STATE_INVULNERABLE] = true,
                    --[MODIFIER_STATE_NO_UNIT_COLLISION] = true, 
					[MODIFIER_STATE_UNSELECTABLE] = true,
                }
    return state
end

modifier_iskander_units_bonus_dmg_clickable = class({})


function modifier_iskander_units_bonus_dmg_clickable:DeclareFunctions()
	return { MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE}
end

function modifier_iskander_units_bonus_dmg_clickable:OnCreated(args)
	self.bonusdmg = args.dmg
end


function modifier_iskander_units_bonus_dmg_clickable:GetModifierBaseAttack_BonusDamage()	
	return self.bonusdmg
end

function modifier_iskander_units_bonus_dmg_clickable:RemoveOnDeath() return true end

function modifier_iskander_units_bonus_dmg_clickable:CheckState()
    local state = { 
                    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
                    [MODIFIER_STATE_INVULNERABLE] = true,
                    --[MODIFIER_STATE_NO_UNIT_COLLISION] = true, 
                }
    return state
end
modifier_army_of_the_king_death_checker = class({})

function modifier_army_of_the_king_death_checker:IsHidden()	
	return true
end

function modifier_army_of_the_king_death_checker:OnDestroy()	
	self:GetAbility():OnAOTKDeath()
end