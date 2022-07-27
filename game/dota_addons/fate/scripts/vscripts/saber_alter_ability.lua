--vortigernCount = 0
--isLeftside = nil

LinkLuaModifier("modifier_vortigern_ferocity", "abilities/arturia_alter/modifiers/modifier_vortigern_ferocity", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_morgan_slow", "saber_alter_ability", LUA_MODIFIER_MOTION_NONE)

--[[function OnDerangeStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	
	DSCheckCombo(keys.caster, keys.ability)
	ability:ApplyDataDrivenModifier( caster, caster, "modifier_derange", {} )

	if caster.IsManaBlastAcquired then
		--[[
			Fix a bug where user can have more than 7 charges and add VFX
		
		local maximum_charges = keys.ability:GetLevelSpecialValueFor( "maximum_charges", keys.ability:GetLevel() - 1 )
		
		-- Check the amount of next charge
		local next_charge = RandomInt(1, 3)

		-- Check if the charges will become over capacity
		if not caster.ManaBlastCount then caster.ManaBlastCount = 0 end	-- This might be because I was debugging it to double check nil value

		if caster.ManaBlastCount + next_charge > maximum_charges then
			if caster.ManaBlastCount == maximum_charges then
				next_charge = 0
			else
				next_charge = caster.ManaBlastCount + next_charge - maximum_charges
			end
			caster.ManaBlastCount = maximum_charges
		else
			caster.ManaBlastCount = caster.ManaBlastCount + next_charge
		end
		
		-- Adding modifiers
		for i = 1, next_charge do
			keys.ability:ApplyDataDrivenModifier( caster, caster, "modifier_derange_mana_catalyst_VFX", {} )
		end
		
		-- Update the charge
		caster:SetModifierStackCount( "modifier_derange_counter", caster, caster.ManaBlastCount )
	end

	caster:EmitSound("Saber_Alter.Derange")
	caster:EmitSound("saber_alter_other_01")
end]]

function OnDerangeAttackStart(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	ability:ApplyDataDrivenModifier( caster, target, "modifier_armor_reduction", {} )
end

function OnDerangeDeath(keys)
	local caster = keys.caster
	caster.ManaBlastCount = 0
	caster:SetModifierStackCount( "modifier_derange_counter", caster, caster.ManaBlastCount )
end

function OnDarklightProc(keys)
	DoDamage(keys.caster, keys.target, 400 , DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
end

function OnUFStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local UFCount = 0
	local bonusDamage = 0

	if caster.IsFerocityImproved then
		bonusDamage = caster:GetStrength()*0.75 + caster:GetIntellect()*0.75
	end

	caster:EmitSound("saber_alter_other_03") 

	DSCheckCombo(caster, keys.ability)
	Timers:CreateTimer(function()
		if UFCount == 5 or not caster:IsAlive() then return end
		caster:EmitSound("Saber_Alter.Unleashed") 
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, keys.Radius
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
	         DoDamage(caster, v, v:GetHealth() * keys.Damage / 100 + bonusDamage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	         v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 0.1})
	    end
		UFCount = UFCount + 1;
		return 0.5
		end
	)

	ability:ApplyDataDrivenModifier( caster, caster, "modifier_unleashed_ferocity_caster_VFX_controller", {} )
end

function OnUFCreateVfx(keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:ApplyDataDrivenModifier( caster, caster, "modifier_unleashed_ferocity_caster_VFX", {} )
end

function OnDarklightCrit(keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:ApplyDataDrivenModifier( caster, caster, "modifier_darklight_crit_hit", {} )
end

function OnDarklightCritHit(keys)
	local caster = keys.caster
	local hTarget = keys.target
	local ability = keys.ability
	hTarget:AddNewModifier(caster, ability, "modifier_disarmed", { duration = 0.5 })
end

function OnMBStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local stunDuration = 0.2

	if caster.IsManaBlastAcquired then
		keys.Damage = keys.Damage + (caster:GetMana() * 0.1)
		caster:SpendMana(caster:GetMana() * 0.1, ability)
		stunDuration = 0.5
		keys.Radius = keys.Radius + 200 
	end

	caster:EmitSound("Saber_Alter.ManaBurst") 
	caster:EmitSound("saber_alter_attack_03")
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, keys.Radius
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	
	local info = {
		Target = nil,
		Source = caster, 
		Ability = keys.ability,
		EffectName = "particles/items2_fx/skadi_projectile.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = 500
	}
	
	if caster.IsManaBlastAcquired and #targets ~= 0 then
		-- Force remove all particles
		while caster:HasModifier( "modifier_derange_mana_catalyst_VFX" ) do
			caster:RemoveModifierByName( "modifier_derange_mana_catalyst_VFX" )
		end

		while caster:GetModifierStackCount("modifier_catalyst", self) ~= 0 do
			info.Target = targets[math.random(#targets)]
			ProjectileManager:CreateTrackingProjectile(info) 
			caster:SetModifierStackCount("modifier_catalyst", self, caster:GetModifierStackCount("modifier_catalyst", self) - 1)
		end
	end

	-- 1.24c particle fix
	-- Slight fix to make the particle size respect the actual AoE after obtaining SA
	local mbParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(mbParticle, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(mbParticle, 1, Vector(keys.Radius, 0, 0))
	ParticleManager:SetParticleControl(mbParticle, 2, Vector(1.0, 0, 0))

	for k,v in pairs(targets) do
	    DoDamage(caster, v, keys.Damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	    v:AddNewModifier(caster, v, "modifier_stunned", {Duration = stunDuration})
	end

	ability:ApplyDataDrivenModifier( caster, caster, "modifier_mana_burst_VFX", {} )
end

function OnManaBlastHit(keys)
	DoDamage(keys.caster, keys.target, 100 , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end

function OnMMBStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local radius = keys.Radius
	local ply = caster:GetPlayerOwner()

	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_max_mana_burst_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})

	caster:FindAbilityByName("saber_alter_mana_burst"):StartCooldown(15.0)

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	EmitGlobalSound("Saber_Alter.MMB" ) 
	EmitGlobalSound("saber_alter_other_04")
	EmitGlobalSound("Saber_Alter.MMBAfter") 
	--EmitGlobalSound("Killer_Queen")
	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.music == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Killer_Queen"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
	local BlueSplashFx = ParticleManager:CreateParticle("particles/custom/screen_blue_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
	ScreenShake(caster:GetOrigin(), 15, 2.0, 2, 10000, 0, true)
	-- Destroy particle
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( BlueSplashFx, false )
	end)

	local dmg = caster:GetMaxMana()*1.2
	if caster.IsManaBlastAcquired then
		dmg = caster:GetMaxMana()*1.5
	end
	local finaldmg = dmg

	for k,v in pairs(targets) do
		local dist = (v:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() 
		if dist <= 700 then
			finaldmg = dmg
		elseif dist > 700 and dist <= 1300 then
			finaldmg = dmg*0.6
		elseif dist > 1300 and dist <= 2000 then
			finaldmg = dmg*0.4
		end

	    DoDamage(caster, v, finaldmg , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	end

	ability:ApplyDataDrivenModifier( caster, caster, "modifier_max_mana_burst_VFX", {} )
end

vortigernCount = 0
function OnVortigernStart(keys)
	ArsenalReturnMana(keys.caster)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local forward = ( keys.target_points[1] - caster:GetAbsOrigin() ):Normalized() -- caster:GetForwardVector() 
	local angle = 120
	local increment_factor = 30
	local origin = caster:GetAbsOrigin()
	local destination = origin + forward

	if (math.abs(destination.x - origin.x) < 0.01) and (math.abs(destination.y - origin.y) < 0.01) then
		destination = caster:GetForwardVector() + caster:GetAbsOrigin()
	end
	
	giveUnitDataDrivenModifier(keys.caster, keys.caster, "pause_sealdisabled", 0.70) -- Beam interval * 9 + 0.44
	EmitGlobalSound("Saber_Alter.Vortigern")

	local vortigernBeam =
	{
		Ability = keys.ability,
		EffectName = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf",
		iMoveSpeed = 3000,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = 600,
		Source = caster,
		fStartRadius = 75,
        fEndRadius = 120,
		bHasFrontialCone = true,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() + 0.4,
		bDeleteOnHit = false,
		vVelocity = 0,
	}

	if caster.IsFerocityImproved then
		if caster:HasModifier("modifier_vortigern_ferocity") then
			local ferocity_modifier = caster:FindModifierByName("modifier_vortigern_ferocity")
			local stacks = ferocity_modifier:GetStackCount()
			if stacks > 1 then
				ability:EndCooldown()
				ferocity_modifier:SetStackCount(stacks - 1)
			else
				caster:RemoveModifierByName("modifier_vortigern_ferocity")
			end
		else
			local ferocity_modifier = caster:AddNewModifier(caster, ability, "modifier_vortigern_ferocity", { Duration = 3 })
			ability:EndCooldown()
			ferocity_modifier:SetStackCount(2)
		end		
	end

	
	--[[local casterAngle = QAngle(0, 120 ,0)
	Timers:CreateTimer(function() 
			if vortigernCount == 10 then vortigernCount = 0 return end -- finish spell
			vortigernBeam.vVelocity = RotatePosition(caster:GetAbsOrigin(), casterAngle, forward * 3000) 
			local projectile = ProjectileManager:CreateLinearProjectile(vortigernBeam)
			casterAngle.y = casterAngle.y - 24;
			print(casterAngle.y)
			vortigernCount = vortigernCount + 1; 
			
			return 0.040 
		end
	)]]
	
	-- Base variables


	vortigernCount = 0
	Timers:CreateTimer( function()
			-- Finish spell, need to include the last angle as well
			-- Note that the projectile limit is currently at 9, to increment this, need to create either dummy or thinker to store them
			if vortigernCount == 9 then return end
			
			-- Start rotating
			local theta = ( angle - vortigernCount * increment_factor ) * math.pi / 180
			local px = math.cos( theta ) * ( destination.x - origin.x ) - math.sin( theta ) * ( destination.y - origin.y ) + origin.x
			local py = math.sin( theta ) * ( destination.x - origin.x ) + math.cos( theta ) * ( destination.y - origin.y ) + origin.y

			local new_forward = ( Vector( px, py, origin.z ) - origin ):Normalized()
			vortigernBeam.vVelocity = new_forward * 3000
			vortigernBeam.fExpireTime = GameRules:GetGameTime() + 0.4
			
			-- Fire the projectile
			local projectile = ProjectileManager:CreateLinearProjectile( vortigernBeam )
			vortigernCount = vortigernCount + 1
			
			-- Create particles
			local fxIndex1 = ParticleManager:CreateParticle( "particles/custom/saber_alter/saber_alter_vortigern_line.vpcf", PATTACH_CUSTOMORIGIN, caster )
			ParticleManager:SetParticleControl( fxIndex1, 0, caster:GetAbsOrigin() )
			ParticleManager:SetParticleControl( fxIndex1, 1, vortigernBeam.vVelocity )
			ParticleManager:SetParticleControl( fxIndex1, 2, Vector( 0.2, 0.2, 0.2 ) )
			
			Timers:CreateTimer( 0.2, function()
					ParticleManager:DestroyParticle( fxIndex1, false )
					ParticleManager:ReleaseParticleIndex( fxIndex1 )
					return nil
				end
			)
			
			return 0.06
		end
	)
end

function OnVortigernHit(keys)
	local caster = keys.caster
	local target = keys.target
	local ply = caster:GetPlayerOwner()
	local damage = keys.Damage
	local StunDuration = keys.StunDuration
	local vortSwingDamage = 5

	damage = damage * (80 + vortigernCount * vortSwingDamage) / 100

	--[[if caster.IsFerocityImproved then 
		if caster:HasModifier("modifier_vortigern_ferocity") then
			damage = damage * 0.66
		end		
	end]]
	
	StunDuration = StunDuration * (80 + vortigernCount * 5)/100
	if target.IsVortigernHit ~= true then
		target.IsVortigernHit = true
		Timers:CreateTimer(0.54, function() target.IsVortigernHit = false return end)
		DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
		target:AddNewModifier(caster, caster, "modifier_stunned", {Duration = StunDuration})
		print(damage)
		
	end

end

--[[ function OnVortigernStart(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local casterVec = caster:GetForwardVector()
	local targetVec = Vector(0,0,0)
	local damage = keys.Damage
	giveUnitDataDrivenModifier(keys.caster, keys.caster, "pause_sealdisabled", 0.4)
	if caster.IsFerocityImproved then 
		damage = damage + 100
		keys.StunDuration = keys.StunDuration + 0.3
	end

	local angle = 0
	EmitGlobalSound("Saber_Alter.Vortigern")

	local vortigerndmg = {
		attacker = caster,
		victim = nil,
		damage = 0,
		damage_type = DAMAGE_TYPE_MAGICAL,
		damage_flags = 0,
		ability = ability
	}

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, keys.Radius
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
        targetVec = v:GetAbsOrigin() - caster:GetAbsOrigin() 
        degree = CalculateAngle(casterVec, targetVec)*180/math.pi -- degree from caster to target
        -- Starts at 120(85% damage), ends at -120(120% damage)
        if degree <= 120 and degree >= -120 then
        	local multiplier = 0.85 + (120 - degree)/(240/0.35)
        	DoDamage(caster, v, damage * multiplier , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
        	--print(degree .. " " .. multiplier)
        	v:AddNewModifier(caster, target, "modifier_stunned", {duration = keys.StunDuration})
        end
    end
end]]

function OnDexVfxControllerStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:ApplyDataDrivenModifier(caster, caster, "dark_excalibur_vfx_phase_1", {})
	ability:ApplyDataDrivenModifier(caster, caster, "dark_excalibur_vfx_phase_3", {})
end

function OnDexVfxPhase2Start(keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:ApplyDataDrivenModifier(caster, caster, "dark_excalibur_vfx_phase_2", {})
end


function OnDexStart(keys)
	local caster = keys.caster
	local ability = keys.ability 
	giveUnitDataDrivenModifier(keys.caster, keys.caster, "pause_sealdisabled", 3)
	keys.Range = keys.Range - keys.Width -- We need this to take end radius of projectile into account
	print(keys.Range)
	local range = keys.Range
	local width = keys.Width
	EmitGlobalSound("Saber.Caliburn")
	--EmitGlobalSound("Excalibur_Morgan_Precast")
	ability:ApplyDataDrivenModifier(caster, caster, "dark_excalibur_VFX_controller", {})
	StartAnimation(caster, {duration = 2, activity = ACT_DOTA_CAST_ABILITY_4, rate = 1.35})
	local dex = 
	{
		Ability = keys.ability,
        EffectName = "",
        iMoveSpeed = keys.Speed,
        vSpawnOrigin = nil,
        fDistance = keys.Range,
        fStartRadius = keys.Width,
        fEndRadius = keys.Width,
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

	Timers:CreateTimer(0, function() 
		if caster:IsAlive() then
			EmitGlobalSound("Excalibur_Morgan")
		end
	end)

	Timers:CreateTimer(2, function()
		if caster:IsAlive() then
			dex.vSpawnOrigin = caster:GetAbsOrigin() 
			dex.vVelocity = caster:GetForwardVector() * keys.Speed/0.3
			
			local counter = 10
			Timers:CreateTimer(0, function()        
            counter = counter -1
            if not caster:IsAlive() then return end
            local projectile = ProjectileManager:CreateLinearProjectile(dex)
            	if(counter == 0) then
                return  
            	end
            return 0.08
        	end)
			ScreenShake(caster:GetOrigin(), 5, 0.1, 2, 20000, 0, true)
			AddFOWViewer(2,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100, 10, 1, false)
    		AddFOWViewer(3,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100, 10, 1, false)
			local excalFxIndex = ParticleManager:CreateParticle("particles/saber_alter/saber_alter_excalibur_beam.vpcf", PATTACH_ABSORIGIN, caster)
			local pepega_end = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*(range + width-100), caster)
			local pepega_vec = (pepega_end - caster:GetAbsOrigin()):Normalized()
   			ParticleManager:SetParticleControl(excalFxIndex, 0, Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100)
   			ParticleManager:SetParticleControl(excalFxIndex, 1, caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.0 + Vector(0, 0, 266)) 
		   	Timers:CreateTimer(0.8, function()
		   		ParticleManager:DestroyParticle( excalFxIndex, false )
				ParticleManager:ReleaseParticleIndex( excalFxIndex )
			end)
			Timers:CreateTimer(0.1, function()
				AddFOWViewer(2,caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.2 + Vector(0, 0, 266), 10, 1, false)
    			AddFOWViewer(3,caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.2 + Vector(0, 0, 266), 10, 1, false)
				local excalpepegFxIndex = ParticleManager:CreateParticle("particles/saber_alter/saber_alter_excalibur_beam_pepeg.vpcf", PATTACH_ABSORIGIN, caster)
   				ParticleManager:SetParticleControl(excalpepegFxIndex, 0, caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.2 + Vector(0, 0, 266))
   				ParticleManager:SetParticleControl(excalpepegFxIndex, 1, pepega_end + Vector(0,0,400)) 
			   	Timers:CreateTimer(0.8, function()
			   		ParticleManager:DestroyParticle( excalpepegFxIndex, false )
					ParticleManager:ReleaseParticleIndex( excalpepegFxIndex )
				end)
			end)
		end
	end)
end

function OnDexHit(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	if caster.IsDarklightAcquired then keys.Damage = keys.Damage + caster:GetMaxMana()*(25 + ability:GetLevel()*5)/1000 end
	if target:GetUnitName() == "gille_gigantic_horror" then keys.Damage = keys.Damage*1.3 end
	DoDamage(keys.caster, keys.target, keys.Damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	target:AddNewModifier(caster, ability, "modifier_morgan_slow", {Duration = 1})
	giveUnitDataDrivenModifier(caster, target, "locked", 1)
end

modifier_morgan_slow = class({})

function modifier_morgan_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_morgan_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_power")
end

function modifier_morgan_slow:IsHidden()
	return false 
end


	--[[
	local vortigernBeam =
	{
		Ability = keys.ability,
		EffectName = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf",
		iMoveSpeed = 10000,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = keys.Radius,
		Source = caster,
		fStartRadius = 10,
        fEndRadius = 50,
		bHasFrontialCone = true,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() + 0.4,
		bDeleteOnHit = false,
		vVelocity = 0.0,
	}

	local casterAngle = QAngle(0,120,0)
	EmitGlobalSound("Saber_Alter.Vortigern")
	Timers:CreateTimer(function() 
			vortigernBeam.vVelocity = RotatePosition(Vector(0,0,0), casterAngle, caster:GetForwardVector()) * 10000
			projectile = ProjectileManager:CreateLinearProjectile(vortigernBeam)
			casterAngle.y = casterAngle.y - 6.66;
			vortigernCount = vortigernCount + 1; 
			if vortigernCount == 36 then vortigernCount = 0 return end -- finish spell
			
			return .01 -- tick every 0.01
		end
	)
end]]

DUsed = false
DTime = GameRules:GetGameTime()
UFTime = 0
	
function DSCheckCombo(caster, ability)
	if caster:HasModifier("modifier_arturia_alter_combo_window") then
		if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
	    	if caster:FindAbilityByName("saber_alter_max_mana_burst"):IsCooldownReady() and caster:FindAbilityByName("saber_alter_mana_burst"):IsCooldownReady() and caster:IsAlive() then	    		
	    		caster:SwapAbilities("saber_alter_max_mana_burst", "saber_alter_mana_burst", true, false)
	    		Timers:CreateTimer(3, function()
	    			caster:SwapAbilities("saber_alter_max_mana_burst", "saber_alter_mana_burst", false, true)
	    	    end)   		
	    	end
	    end
	end
end