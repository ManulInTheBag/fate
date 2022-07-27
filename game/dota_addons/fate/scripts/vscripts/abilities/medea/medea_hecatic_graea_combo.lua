medea_hecatic_graea_combo = class({})

LinkLuaModifier("modifier_hecatic_graea_anim", "abilities/medea/modifiers/modifier_hecatic_graea_anim", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hecatic_graea_powered_cooldown", "abilities/medea/modifiers/modifier_hecatic_graea_powered_cooldown", LUA_MODIFIER_MOTION_NONE)

function medea_hecatic_graea_combo:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function medea_hecatic_graea_combo:CastFilterResultLocation(vLocation)
	if IsServer() then
		if GridNav:IsBlocked(vLocation) or not GridNav:IsTraversable(vLocation) or not IsInSameRealm(self:GetCaster():GetAbsOrigin(), vLocation) then
			return UF_FAIL_CUSTOM
		end

		return UF_SUCCESS
	end	
end

function medea_hecatic_graea_combo:GetCustomCastErrorLocation(vLocation)
	return "#Cannot_Travel"
end

function medea_hecatic_graea_combo:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local targetPoint = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local boltradius = self:GetSpecialValueFor("radius_bolt")
	local boltvector = nil
	local boltCount  = 0
	local maxBolt = 20
	local barrageRadius_small = self:GetSpecialValueFor("radius_small")
	local barrageRadius_big = self:GetSpecialValueFor("radius_big")
	local travelTime = 0.7
	local ascendTime = travelTime + 4.0
	local descendTime = ascendTime + 0.75
	local damage = self:GetSpecialValueFor("damage")

	print("something")

	if not IsInSameRealm(caster:GetOrigin(), targetPoint) then
		self:EndCooldown() 
		caster:GiveMana(800) 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Travel")
		return 
	end 

	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(ability:GetCooldown(ability:GetLevel()))
	--ability:ApplyDataDrivenModifier(caster, caster, "modifier_hecatic_graea_powered_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})

	caster:AddNewModifier(caster, ability, "modifier_hecatic_graea_powered_cooldown", { Duration = ability:GetCooldown(ability:GetLevel()) })

	local HGAbility = caster:FindAbilityByName("medea_hecatic_graea")
	local HGCooldown = HGAbility:GetCooldown(HGAbility:GetLevel())
	HGAbility:StartCooldown(HGCooldown)
	
	if caster.IsHGImproved then
		maxBolt = 23
		damage = damage + caster:GetIntellect() * 1
	end 

	caster:AddNewModifier(caster, ability, "modifier_hecatic_graea_anim", { Duration = 4 })
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", descendTime)

	local diff = (targetPoint - caster:GetAbsOrigin()) * 1 / travelTime
	local fly = Physics:Unit(caster)
	caster:PreventDI()
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(Vector(diff:Normalized().x * diff:Length2D(), diff:Normalized().y * diff:Length2D(), 1000))
	caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	caster:FollowNavMesh(false)
	caster:SetAutoUnstuck(false)
	Timers:CreateTimer(travelTime, function()  
		ParticleManager:CreateParticle("particles/custom/screen_purple_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:SetAutoUnstuck(true)
	return end) 
	Timers:CreateTimer(ascendTime, function()  
		local dummy = CreateUnitByName( "sight_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber() );
		caster:SetPhysicsVelocity( Vector( 0, 0, -950 ) )
		dummy:RemoveSelf()
	return end) 
	Timers:CreateTimer(descendTime, function()  
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit( caster, caster:GetAbsOrigin(), true )
	return end)
	local isFirstLoop = false
	Timers:CreateTimer(travelTime - 0.5, function()
		LoopOverPlayers(function(player, playerID, playerHero)
       		 --print("looping through " .. playerHero:GetName())
        		if playerHero.voice == true then
            	-- apply legion horn vsnd on their client
           			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="medea_casino"})
            	--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        		end
    		end)
	end)
	 
	local isFirstLoop  = false
 
	local targeted_rays_amount = 0
	local big_bolts  = 0
	local big_bolts_temp = 0
	Timers:CreateTimer(travelTime, function()
		-- For the first round of shots, find all servants within AoE and guarantee one ray hit
		if isFirstLoop == false then
			isFirstLoop = true
			self:DropRay(caster, damage, boltradius, ability, targetPoint, "particles/custom/caster/hecatic_graea/ray.vpcf")
			initTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, barrageRadius_big, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false) 
			targeted_rays_amount = #initTargets
			big_bolts = math.ceil(maxBolt/3)
			big_bolts_temp = big_bolts
			return 0.1
		elseif targeted_rays_amount ~= 0 then
		self:DropRay(caster, damage, boltradius, ability, initTargets[targeted_rays_amount]:GetAbsOrigin(), "particles/custom/caster/hecatic_graea/ray.vpcf")
		targeted_rays_amount = targeted_rays_amount - 1
 		maxBolt = maxBolt - 1
		big_bolts = math.ceil(maxBolt/3)
		 big_bolts_temp = big_bolts
		return 0.1
		else
			if maxBolt <= boltCount then return end
		end
		local radius = barrageRadius_big
		local maxbolt_temp = 	maxBolt  
		local lazy_removal = 0
		if(big_bolts ~= 0) then 
			 radius = barrageRadius_small
			big_bolts = big_bolts - 1
			maxbolt_temp = big_bolts_temp
	 	else
			lazy_removal = big_bolts_temp
		end
		rayTarget =  PointOnCircle(GetGroundPosition(caster:GetAbsOrigin(), caster), radius - 150, (maxbolt_temp -  boltCount    )*360/(maxbolt_temp-lazy_removal) )

		self:DropRay(caster, damage, boltradius, ability, rayTarget, "particles/custom/caster/hecatic_graea/ray.vpcf")
	    boltCount = boltCount + 1
		return 0.085
    end
    
    )

	
	Timers:CreateTimer(travelTime + 2.5, function()
		local targets = FindUnitsInRadius(caster:GetTeam(), GetGroundPosition(caster:GetAbsOrigin(), caster), nil, barrageRadius_big, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for k,v in pairs(targets) do
        	DoDamage(caster, v, 1500, DAMAGE_TYPE_MAGICAL, 0, ability, false)
        	v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 1.5})
		end
  	  	local particle = ParticleManager:CreateParticle("particles/custom/caster/hecatic_graea_powered/area.vpcf", PATTACH_CUSTOMORIGIN, caster)
  	  	ParticleManager:SetParticleControl(particle, 0, GetGroundPosition(caster:GetAbsOrigin(), caster)) 
	    ParticleManager:SetParticleControl(particle, 1, Vector(barrageRadius_big * 2.5, 1, 1))
	    ParticleManager:SetParticleControl(particle, 2, Vector(barrageRadius_big * 75, 1, 1))
	    EmitGlobalSound("Medea_Combo_1")
	    caster:EmitSound("Hero_ObsidianDestroyer.SanityEclipse.Cast")
		return
    end
    )

	Timers:CreateTimer(1.0, function() 
		EmitGlobalSound("Caster.Hecatic")
		EmitGlobalSound("Caster.Hecatic_Spread") 
		caster:EmitSound("Misc.Crash") 
	return end)

	print("most timers created blabla")
end

function medea_hecatic_graea_combo:DropRay(caster, damage, radius, ability, targetPoint, particle)
	local casterLocation = caster:GetAbsOrigin()
	
	-- print(damage)
	-- Particle
	local dummy = CreateUnitByName("dummy_unit", targetPoint, false, caster, caster, caster:GetTeamNumber())
	dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

	local fxIndex = ParticleManager:CreateParticle(particle, PATTACH_POINT, dummy)
	ParticleManager:SetParticleControlEnt(fxIndex, 0, dummy, PATTACH_POINT, "attach_hitloc", dummy:GetAbsOrigin(), true)
	local portalLocation = casterLocation + (targetPoint - casterLocation):Normalized() * 300
	portalLocation.z = casterLocation.z
	ParticleManager:SetParticleControl(fxIndex, 4, portalLocation)

	local casterDirection = (portalLocation - targetPoint):Normalized()
	casterDirection.x = casterDirection.x * -1
	casterDirection.y = casterDirection.y * -1
	dummy:SetForwardVector(casterDirection)

	--DebugDrawCircle(targetPoint, Vector(255,0,0), 0.5, radius, true, 0.5)

	Timers:CreateTimer(2, function()
		dummy:RemoveSelf()
	end)
		
	local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	for k,v in pairs(targets) do
    	DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
    	if not v:IsNull() then
    		v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 0.01})
    	end
	end
end