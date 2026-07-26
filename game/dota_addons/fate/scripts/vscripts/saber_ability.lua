LinkLuaModifier("modifier_excalibur_slow", "saber_ability", LUA_MODIFIER_MOTION_NONE)

avalonCooldown = true -- UP if true, 
vectorA = Vector(0,0,0)
combo_available = false
currentHealth = 0

--[[
	Author: kritth
	Date: 10.01.2015.
	Create yellowish explosion upon hitting unit
]]
function OnExcaliburVfxStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:ApplyDataDrivenModifier(caster, caster, "excalibur_vfx_phase_1", {})
	ability:ApplyDataDrivenModifier(caster, caster, "excalibur_vfx_phase_3", {})
end

function OnExcaliburSwordVfxStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	Timers:CreateTimer(1.1, function()
		ability:ApplyDataDrivenModifier(caster, caster, "excalibur_vfx_phase_2", {})
	end)
end


function OnExcaliburStart(keys)
	EmitGlobalSound("Saber.Excalibur_Ready")
	local caster = keys.caster
	local targetPoint = keys.ability:GetCursorPosition()
	local ability = keys.ability
	keys.Range = keys.Range - keys.EndRadius -- We need this to take end radius of projectile into account
	local range = keys.Range
	local width = keys.EndRadius
	giveUnitDataDrivenModifier(keys.caster, keys.caster, "pause_sealdisabled", 2.7)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_excalibur", {})
	ability:ApplyDataDrivenModifier(caster, caster, "saber_anim_vfx", {})
	local excal = 
	{
		Ability = keys.ability,
        EffectName = "",
        iMoveSpeed = keys.Speed,
        vSpawnOrigin = casterloc,
        fDistance = keys.Range,
        fStartRadius = keys.StartRadius,
        fEndRadius = keys.EndRadius,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 5.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * keys.Speed/0.3
	}
	
	EmitGlobalSound("Saber_Ex")
	Timers:CreateTimer(0.55, function()
		EmitGlobalSound("saber_effect")
	end) 		

	Timers:CreateTimer(keys.Delay - 0.5, function() 
		if caster:IsAlive() then
			EmitGlobalSound("Saber_Kalibar") return 
		end
	end)

	-- Create linear projectile
	Timers:CreateTimer(keys.Delay - 0.4, function()
		if caster:IsAlive() then
			excal.vSpawnOrigin = caster:GetAbsOrigin() 
			excal.vVelocity = caster:GetForwardVector() * keys.Speed/0.3
			local counter = 10
			Timers:CreateTimer(0, function()        
            counter = counter -1
            if not caster:IsAlive() then return end
            local projectile = ProjectileManager:CreateLinearProjectile(excal)
            	if(counter == 0) then
                return  
            	end
            return 0.08
        	end)
 
			ScreenShake(caster:GetOrigin(), 5, 0.1, 2, 20000, 0, true)
			AddFOWViewer(2,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100, 10, 1, false)
    		AddFOWViewer(3,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100, 10, 1, false)
			local excalFxIndex = ParticleManager:CreateParticle("particles/saber/saber_excalibur_beam.vpcf", PATTACH_ABSORIGIN, caster)
			local pepega_end = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*(range + width-100), caster)
			local pepega_vec = (pepega_end - caster:GetAbsOrigin()):Normalized()
   			ParticleManager:SetParticleControl(excalFxIndex, 0, Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100)
   			ParticleManager:SetParticleControl(excalFxIndex, 1, caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.0 + Vector(0, 0, 266)) 
		   	Timers:CreateTimer(0.8, function()
		   		ParticleManager:DestroyParticle( excalFxIndex, false )
				ParticleManager:ReleaseParticleIndex( excalFxIndex )
			end)
			Timers:CreateTimer(0.1, function()
				AddFOWViewer(2,caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.0 + Vector(0, 0, 266), 10, 1, false)
    			AddFOWViewer(3,caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.0 + Vector(0, 0, 266), 10, 1, false)
				local excalpepegFxIndex = ParticleManager:CreateParticle("particles/saber/saber_excalibur_beam_pepeg.vpcf", PATTACH_ABSORIGIN, caster)
   				ParticleManager:SetParticleControl(excalpepegFxIndex, 0, caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.0 + Vector(0, 0, 266))
   				ParticleManager:SetParticleControl(excalpepegFxIndex, 1, pepega_end + Vector(0,0,400)) 
			   	Timers:CreateTimer(0.8, function()
			   		ParticleManager:DestroyParticle( excalpepegFxIndex, false )
					ParticleManager:ReleaseParticleIndex( excalpepegFxIndex )
				end)
			end)
		else
			StopGlobalSound("saber_effect")
		end
	end)
	
	-- for i=0,1 do
		Timers:CreateTimer(keys.Delay - 0.3, function() -- Adjust 2.5 to 3.2 to match the sound
			if caster:IsAlive() then
				-- Create Particle for projectile
				local casterFacing = caster:GetForwardVector()
				local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
				dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
				dummy:SetForwardVector(casterFacing)
				Timers:CreateTimer( function()
						if IsValidEntity(dummy) then
							local newLoc = dummy:GetAbsOrigin() + keys.Speed * 0.03 * casterFacing
							dummy:SetAbsOrigin(GetGroundPosition(newLoc,dummy))
							-- DebugDrawCircle(newLoc, Vector(255,0,0), 0.5, keys.StartRadius, true, 0.15)
							return 0.03
						else
							return nil
						end
					end
				)
				
				--local excalFxIndex = ParticleManager:CreateParticle( "particles/custom/saber/excalibur/shockwave.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, dummy )
				--ParticleManager:SetParticleControl(excalFxIndex, 4, Vector(keys.StartRadius,0,0))

				Timers:CreateTimer( 1.65, function()
						--ParticleManager:DestroyParticle( excalFxIndex, false )
						--ParticleManager:ReleaseParticleIndex( excalFxIndex )
						Timers:CreateTimer( 0.5, function()
								dummy:RemoveSelf()
								return nil
							end
						)
						return nil
					end
				)
				return 
			end
		end)
	-- end
end


function OnExcaliburHit(keys)
	local caster = keys.caster
	local target = keys.target 
	local damage = keys.Damage
	local ManaScaling = keys.ManaScaling
	local ply = caster:GetPlayerOwner()
	if caster.IsExcaliburAcquired == true then
		 damage = damage + (caster:GetMaxMana()*  ManaScaling/100)/10
	end
	if target:GetUnitName() == "gille_gigantic_horror" then keys.Damage = keys.Damage*1.3 end
	target:AddNewModifier(caster, keys.ability, "modifier_excalibur_slow", {Duration = 1})
	giveUnitDataDrivenModifier(caster, target, "locked", 1)
	DoDamage(keys.caster, keys.target, damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end

modifier_excalibur_slow = class({})

function modifier_excalibur_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_excalibur_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_power")
end

function modifier_excalibur_slow:IsHidden()
	return false 
end


function OnExcaliburVfxStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:ApplyDataDrivenModifier(caster, caster, "excalibur_vfx_phase_1", {})
	ability:ApplyDataDrivenModifier(caster, caster, "excalibur_vfx_phase_3", {})
end

function OnExcaliburSwordVfxStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	Timers:CreateTimer(1.1, function()
		ability:ApplyDataDrivenModifier(caster, caster, "excalibur_vfx_phase_2", {})
	end)
end
--[[
function OnExcaliburStart(keys)
	EmitGlobalSound("Saber.Excalibur_Ready")
	local caster = keys.caster
	local targetPoint = keys.ability:GetCursorPosition()
	local ability = keys.ability
	keys.Range = keys.Range - keys.EndRadius -- We need this to take end radius of projectile into account
	
	giveUnitDataDrivenModifier(keys.caster, keys.caster, "pause_sealdisabled", 4.0)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_excalibur", {})
	ability:ApplyDataDrivenModifier(caster, caster, "saber_anim_vfx", {})
	local excal = 
	{
		Ability = keys.ability,
        EffectName = "",
        iMoveSpeed = keys.Speed,
        vSpawnOrigin = casterloc,
        fDistance = keys.Range,
        fStartRadius = keys.StartRadius,
        fEndRadius = keys.EndRadius,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 5.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * keys.Speed
	}
	Timers:CreateTimer(0.5, function() 
		if caster:IsAlive() then
			EmitGlobalSound("Saber.Excalibur") return 
		end
	end)

	-- Create linear projectile
	Timers:CreateTimer(keys.Delay - 0.3, function()
		if caster:IsAlive() then
			excal.vSpawnOrigin = caster:GetAbsOrigin() 
			excal.vVelocity = caster:GetForwardVector() * keys.Speed
			local projectile = ProjectileManager:CreateLinearProjectile(excal)
			ScreenShake(caster:GetOrigin(), 5, 0.1, 2, 20000, 0, true)
		end
	end)
	
	local casterFacing = caster:GetForwardVector()
	-- for i=0,1 do
		Timers:CreateTimer(keys.Delay - 0.3, function() -- Adjust 2.5 to 3.2 to match the sound
			if caster:IsAlive() then
				-- Create Particle for projectile
				local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
				dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
				dummy:SetForwardVector(casterFacing)
				Timers:CreateTimer( function()
						if IsValidEntity(dummy) then
							local newLoc = dummy:GetAbsOrigin() + keys.Speed * 0.03 * casterFacing
							dummy:SetAbsOrigin(GetGroundPosition(newLoc,dummy))
							-- DebugDrawCircle(newLoc, Vector(255,0,0), 0.5, keys.StartRadius, true, 0.15)
							return 0.03
						else
							return nil
						end
					end
				)
				
				local excalFxIndex = ParticleManager:CreateParticle( "particles/custom/saber/excalibur/shockwave.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, dummy )
				ParticleManager:SetParticleControl(excalFxIndex, 4, Vector(keys.StartRadius,0,0))

				Timers:CreateTimer( 1.65, function()
						ParticleManager:DestroyParticle( excalFxIndex, false )
						ParticleManager:ReleaseParticleIndex( excalFxIndex )
						Timers:CreateTimer( 0.5, function()
								dummy:RemoveSelf()
								return nil
							end
						)
						return nil
					end
				)
				return 
			end
		end)
	-- end
end
]]



function OnMaxVfxStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:ApplyDataDrivenModifier(caster, caster, "excalibur_vfx_phase_1", {})
	ability:ApplyDataDrivenModifier(caster, caster, "excalibur_vfx_phase_3", {})
end

function OnMaxSwordVfxStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	Timers:CreateTimer(1.1, function()
		ability:ApplyDataDrivenModifier(caster, caster, "excalibur_vfx_phase_2", {})
	end)
end

function OnMaxStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local targetPoint = keys.ability:GetCursorPosition()
	keys.Range = keys.Range - keys.Width -- We need this to take end radius of projectile into account
	if caster.IsExcaliburAcquired == true then
		caster:SetMana(1)
	end

	caster:FindAbilityByName("saber_excalibur"):StartCooldown(37.0)
	giveUnitDataDrivenModifier(keys.caster, keys.caster, "pause_sealdisabled", 5.0)
	ability:ApplyDataDrivenModifier(caster, caster, "saber_max_excalibur_anim_vfx", {})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_max_excalibur", {})
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_max_excalibur_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})

	local plyID = caster:GetPlayerID()
	if caster.cinematic_true then
		PlayerResource:SetOverrideSelectionEntity(plyID, nil)
	    PlayerResource:SetCameraTarget(plyID, caster)
	    Timers:CreateTimer(4.5, function()
	        PlayerResource:SetCameraTarget(plyID, nil)
	        CameraModule:InitializeCamera(plyID)
	    end)
	    local cam_yaw = 90 + CameraModule:GetYawAngle(caster)
	    local cam_pitch = 30
	    local cam_offset = 400 + CameraModule:GetHeightDiff(caster)
	    local cam_distance = 600

	    --CameraModule:SetCameraPosition(plyID, 150 + CameraModule:GetYawAngle(caster), 5, 60 + CameraModule:GetHeightDiff(caster), 50, true)
	    --[[Timers:CreateTimer(FrameTime(), function()
	    	cam_counter = cam_counter + FrameTime()
	    	if cam_counter < 4.5 then
	    		CameraModule:SetCameraPosition(plyID, cam_yaw, cam_pitch, cam_offset, cam_distance)

	    		return FrameTime()
	    	end
	    end)]]
	    CameraModule:PositionSlip(plyID, 150 + CameraModule:GetYawAngle(caster), 5, 480 + CameraModule:GetHeightDiff(caster), 30, true, true, 0.5, "min", "decrease")
	    Timers:CreateTimer(0.5, function()
	    	CameraModule:PositionSlip(plyID, cam_yaw, cam_pitch, cam_offset, cam_distance, true, false, 2.5, "max", "edge_dec")
	    end)
	end
	
	local max_excal = 
	{
		Ability = keys.ability,
        EffectName = "",
        iMoveSpeed = keys.Speed,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = keys.Range,
        fStartRadius = keys.Width,
        fEndRadius = keys.Width,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 6.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * keys.Speed
	}

	--EmitGlobalSound("Saber_Oath")
	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.music == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Saber_Oath"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
	Timers:CreateTimer({endTime=0.1,
		callback = function()
		--EmitGlobalSound("Saber_Max_Chant_" .. math.random(1,2))
		EmitGlobalSound("saber_maxex_chant"..math.random(1,2))
	end})

	Timers:CreateTimer({
		endTime = 2.5, 
		callback = function()
	    --EmitGlobalSound("Saber_Max_Excalibur")
	    EmitGlobalSound("saber_maxexcalibar")
	    EmitGlobalSound("saber_effect")
	end})

	-- Charge particles
	ParticleManager:CreateParticle("particles/custom/saber/max_excalibur/charge.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	
	-- Create linear projectile
	Timers:CreateTimer(3.5, function()
		StartAnimation(caster, {duration=3.5, activity=ACT_DOTA_CAST_ABILITY_3, rate=0.01})
		if caster:IsAlive() then
			nBeams2 = 0
			Timers:CreateTimer(function()
				if nBeams2 == 10 then return end
				max_excal.vSpawnOrigin = caster:GetAbsOrigin() 
				max_excal.vVelocity = caster:GetForwardVector() * keys.Speed
				local projectile = ProjectileManager:CreateLinearProjectile(max_excal)
				nBeams2 = nBeams2 + 1
				return 0.1
			end)
			local YellowScreenFx = ParticleManager:CreateParticle("particles/custom/screen_yellow_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
			ScreenShake(caster:GetOrigin(), 7, 2.0, 2, 10000, 0, true)
			
        	Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( YellowScreenFx, false )
			end)
		end
	end)

	local casterFacing = caster:GetForwardVector()
	-- for i=0,1 do
		Timers:CreateTimer({
			endTime = 3, 
			callback = function()
			if caster:IsAlive() then
				nBeams = 0
				Timers:CreateTimer(function()
					if nBeams == 50 then return end
					FireSingleMaxParticle(keys)
					nBeams = nBeams + 1
					return 0.02
				end)
			end
		end})
	-- end
end

function FireSingleMaxParticle(keys)
	local caster = keys.caster
	local casterFacing = caster:GetForwardVector()
	if caster.AltPart.combo == 1 then
		local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin() + 700 * casterFacing, false, nil, nil, caster:GetTeamNumber())
		dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		dummy:SetForwardVector(casterFacing)
		Timers:CreateTimer( function()
				if IsValidEntity(dummy) then
					local newLoc = dummy:GetAbsOrigin() + keys.Speed * 0.015 * casterFacing
					dummy:SetAbsOrigin(GetGroundPosition(newLoc,dummy))
					-- DebugDrawCircle(newLoc, Vector(255,0,0), 0.5, keys.Width, true, 0.15)
					return 0.015
				else
					return nil
				end
			end
		)
		
		local excalFxIndex = ParticleManager:CreateParticle("particles/custom/saber/max_excalibur/shockwave", PATTACH_ABSORIGIN_FOLLOW, dummy)
		--local excalFxIndex = ParticleManager:CreateParticle("particles/custom/saber/excalibur/shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
			
		Timers:CreateTimer(0.36, function()
			ParticleManager:DestroyParticle( excalFxIndex, false )
			ParticleManager:ReleaseParticleIndex( excalFxIndex )
			Timers:CreateTimer( 0.1, function()
					dummy:RemoveSelf()
					return nil
				end
			)
			return nil
		end)
	else
		local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin() + 300 * casterFacing, false, nil, nil, caster:GetTeamNumber())
		dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
		dummy:SetForwardVector(casterFacing)
		Timers:CreateTimer( function()
				if IsValidEntity(dummy) then
					local newLoc = dummy:GetAbsOrigin() + keys.Speed * 0.015 * casterFacing
					dummy:SetAbsOrigin(GetGroundPosition(newLoc,dummy))
					-- DebugDrawCircle(newLoc, Vector(255,0,0), 0.5, keys.Width, true, 0.15)
					return 0.015
				else
					return nil
				end
			end
		)
		
		local excalFxIndex = ParticleManager:CreateParticle("particles/custom/saber/max_excalibur/shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
		--local excalFxIndex = ParticleManager:CreateParticle("particles/custom/saber/excalibur/shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy)
			
		Timers:CreateTimer(0.57, function()
			ParticleManager:DestroyParticle( excalFxIndex, false )
			ParticleManager:ReleaseParticleIndex( excalFxIndex )
			Timers:CreateTimer( 0.1, function()
					dummy:RemoveSelf()
					return nil
				end
			)
			return nil
		end)
	end
end

function OnMaxHit(keys)
	local caster = keys.caster
	local target = keys.target
	local ply = caster:GetPlayerOwner()
	if caster.IsExcaliburAcquired == true then keys.Damage = keys.Damage + 6500 end
	if target.IsMaxcaHit ~= true then
		target.IsMaxcaHit = true
		Timers:CreateTimer(3, function() target.IsMaxcaHit = false return end)
		DoDamage(keys.caster, keys.target, keys.Damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	end
	--DoDamage(keys.caster, keys.target, keys.Damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end

LinkLuaModifier("modifier_everdistant_utopia", "abilities/arturia/modifiers/modifier_everdistant_utopia", LUA_MODIFIER_MOTION_NONE)

-- function end

LinkLuaModifier("modifier_chivalry_attribute","abilities/arturia/modifiers/modifier_chivalry_attribute.lua",LUA_MODIFIER_MOTION_NONE)

