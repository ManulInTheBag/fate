emiya_arrow_rain = class({})

LinkLuaModifier("modifier_arrow_rain_cooldown", "abilities/emiya/modifiers/modifier_arrow_rain_cooldown", LUA_MODIFIER_MOTION_NONE)

function emiya_arrow_rain:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self

	if not caster.IsUBWActive then return end
	local ascendCount = 0
	local descendCount = 0
	local radius = 1000

	caster:RemoveModifierByName("modifier_arrow_rain_window")
	caster:AddNewModifier(caster, ability, "modifier_arrow_rain_cooldown", {duration = self:GetCooldown(1)})
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(1))

	caster:EmitSound("Archer.Combo") 
	
	local broken_phantasm = caster:FindAbilityByName("emiya_broken_phantasm")

	local info = {
		Target = nil,
		Source = caster, 
		Ability = broken_phantasm,
		EffectName = "particles/units/heroes/hero_clinkz/clinkz_searing_arrow.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = 3000
	}

	local BrownSplashFx = ParticleManager:CreateParticle("particles/custom/screen_brown_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
	Timers:CreateTimer( 4.0, function()
		ParticleManager:DestroyParticle( BrownSplashFx, false )
		ParticleManager:ReleaseParticleIndex( BrownSplashFx )
	end)
	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 4.5)

	Timers:CreateTimer('rain_ascend', {
		endTime = 0,
		callback = function()
	   	if ascendCount == 20 then return end
		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z+40))
		ascendCount = ascendCount + 1;
		return 0.01
	end
	})

	-- Barrage attack
	local barrageCount = 0
	Timers:CreateTimer(0.3, function()
		if barrageCount == 100 or not caster:IsAlive() then return end
		local arrowVector = Vector( RandomFloat( -radius, radius ), RandomFloat( -radius, radius ), 0 )
		caster:EmitSound("Hero_DrowRanger.FrostArrows")
		-- Create Arrow particles
		-- Main variables
		local speed = 3000				-- Movespeed of the arrow

		-- Side variables
		local groundVector = caster:GetAbsOrigin() - Vector(0,0,1000)
		local spawn_location = caster:GetAbsOrigin()
		local target_location = groundVector + arrowVector
		local forwardVec = ( target_location - caster:GetAbsOrigin() ):Normalized()
		local delay = ( target_location - caster:GetAbsOrigin() ):Length2D() / speed
		local distance = delay * speed
		
		local arrowFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_arrow_rain_model.vpcf", PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( arrowFxIndex, 0, spawn_location )
		ParticleManager:SetParticleControl( arrowFxIndex, 1, forwardVec * speed )
		
		-- Delay Damage
		Timers:CreateTimer( delay, function()
			-- Destroy arrow
			ParticleManager:DestroyParticle( arrowFxIndex, false )
			ParticleManager:ReleaseParticleIndex( arrowFxIndex )
			
			-- Delay damage
			local targets = FindUnitsInRadius(caster:GetTeam(), groundVector + arrowVector, nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for k,v in pairs(targets) do
				if not v:HasModifier("modifier_protection_from_arrows_active") then
					DoDamage(caster, v, self:GetSpecialValueFor("arrow_damage") , DAMAGE_TYPE_MAGICAL, 0, self, false)
				end
			end
			
			-- Particles on impact
			local explosionFxIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_gyrocopter/gyro_guided_missile_explosion.vpcf", PATTACH_CUSTOMORIGIN, caster )
			ParticleManager:SetParticleControl( explosionFxIndex, 0, groundVector + arrowVector + Vector(0,0,200))
			
			local impactFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_sword_barrage_impact_circle.vpcf", PATTACH_CUSTOMORIGIN, caster )
			ParticleManager:SetParticleControl( impactFxIndex, 0, groundVector + arrowVector + Vector(0,0,200))
			ParticleManager:SetParticleControl( impactFxIndex, 1, Vector(300, 300, 300))
			
			-- Destroy Particle
			Timers:CreateTimer( 0.5, function()
				ParticleManager:DestroyParticle( explosionFxIndex, false )
				ParticleManager:DestroyParticle( impactFxIndex, false )
				ParticleManager:ReleaseParticleIndex( explosionFxIndex )
				ParticleManager:ReleaseParticleIndex( impactFxIndex )
				return nil
			end)
			return nil
		end)
		
	    barrageCount = barrageCount + 1
		return 0.03
    end)

	-- BP Attack
	local bpCount = 0 
	Timers:CreateTimer(2.8, function()
		if bpCount == 5 or not caster:IsAlive() then return end
		local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		info.Target = units[math.random(#units)]
		if info.Target ~= nil then 
			ProjectileManager:CreateTrackingProjectile(info) 
		end
		bpCount = bpCount + 1
		return 0.2
    end)

	Timers:CreateTimer('rain_descend', {
		endTime = 3.8,
		callback = function()
	   	if descendCount == 20 then return end
		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z-40))
		descendCount = descendCount + 1;
		return 0.01
	end
	})
end

function emiya_arrow_rain:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	print("its triggering from rain 4head")
	if IsSpellBlocked(hTarget) then return end -- Linken effect checker
	local caster = self:GetCaster()
	local ability = caster:FindAbilityByName("emiya_broken_phantasm")
	local targetdmg = ability:GetLevelSpecialValueFor("target_damage") 
	local splashdmg = ability:GetLevelSpecialValueFor("splash_damage") 
	local radius = ability:GetLevelSpecialValueFor("radius")
	local stunDuration = ability:GetLevelSpecialValueFor("stun_duration")

	if not hTarget:HasModifier("modifier_lancer_protection_from_arrows_active") then
		DoDamage(caster, hTarget, targetdmg , DAMAGE_TYPE_MAGICAL, 0, self, false)
	end
	
	local targets = FindUnitsInRadius(caster:GetTeam(), hTarget:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
         DoDamage(caster, v, splashdmg, DAMAGE_TYPE_MAGICAL, 0, self, false)
    end
    local ArrowExplosionFx = ParticleManager:CreateParticle("particles/units/heroes/hero_sven/sven_storm_bolt_projectile_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget)
    ParticleManager:SetParticleControl(ArrowExplosionFx, 3, hTarget:GetAbsOrigin())
	-- Destroy Particle
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( ArrowExplosionFx, false )
		ParticleManager:ReleaseParticleIndex( ArrowExplosionFx )
		return nil
	end)
	hTarget:AddNewModifier(caster, hTarget, "modifier_stunned", {Duration = stunDuration})
end
