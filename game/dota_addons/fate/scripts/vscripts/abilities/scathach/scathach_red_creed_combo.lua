scathach_red_creed_combo = class({})
LinkLuaModifier( "modifier_scathach_combo_invul", "abilities/scathach/modifiers/modifier_scathach_combo_invul", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_scathach_combo_2_cooldown", "abilities/scathach/modifiers/modifier_scathach_combo_2_cooldown", LUA_MODIFIER_MOTION_NONE )

function scathach_red_creed_combo:OnSpellStart()
	local caster = self:GetCaster()
	local hCaster = self:GetCaster()
	local ability = self
	
	local hTarget = self:GetCursorTarget()
	local target = self:GetCursorTarget()

	local retreatDist = self:GetSpecialValueFor("retreat_distance")
	local forwardVec = caster:GetForwardVector()

	local casterPos = caster:GetAbsOrigin()
	local counter  = 1
	local archer = Physics:Unit(caster)

	ProjectileManager:ProjectileDodge(caster)

    local enemy = PickRandomEnemy(hCaster)
	
    if enemy then
        hCaster:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = 2.5 })
    end
	
	EmitGlobalSound("scathach_gait_attack_3")
	
	Timers:CreateTimer(0.4, function()
		EmitGlobalSound("scathach_gait_3")
	end)
	
	hCaster:AddNewModifier(hCaster, self, "modifier_scathach_combo_invul", { Duration = 1.5 })
	
	hCaster:AddNewModifier(hCaster, self, "modifier_scathach_combo_2_cooldown", { Duration = self:GetCooldown(1) })

	local masterCombo = hCaster.MasterUnit2:FindAbilityByName("scathach_combo_2_proxy")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(1))

	caster:PreventDI()
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(-forwardVec * retreatDist * 0.5 + Vector(0,0,1000))
	caster:SetPhysicsAcceleration(Vector(0,0,-1000))
	caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	caster:FollowNavMesh(false)

  	Timers:CreateTimer(2.0, function()
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:OnPhysicsFrame(nil)
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	end)

	StartAnimation(caster, {duration=2.19, activity=ACT_DOTA_CAST_DRAGONBREATH, rate=1.0})

	Timers:CreateTimer(1.35, function() -- Start Main Timer
	
	local redcreedDummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	redcreedDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	
	local right_vec = caster:GetForwardVector()
	right_vec = Vector(right_vec.y, -right_vec.x, 0)
	
	redcreedDummy:SetAbsOrigin(caster:GetAbsOrigin() + (right_vec * -2000) + Vector(0, 0, -1200))

	local info = {
		Target = target,
		Source = redcreedDummy, 
		Ability = self,
		EffectName = "particles/custom/scathach/gae_bolg.vpcf",
		vSpawnOrigin = redcreedDummy:GetAbsOrigin(),
		bDodgeable = false,
		 flExpireTime = GameRules:GetGameTime() + 10,
		iMoveSpeed = 2500
	}	

	local target_origin = target:GetAbsOrigin()

	local extra_projectiles = self:GetSpecialValueFor("extra_projectiles")
	
	local projectile_height_count = 0
	
	local projectile count = 0
	local radius = self:GetSpecialValueFor("radius")

	if extra_projectiles > 0 then
		redcreedDummy:SetAbsOrigin(caster:GetAbsOrigin() + (right_vec * -3300) + Vector(0, 0, -1500))
		info.vSpawnOrigin = redcreedDummy:GetAbsOrigin()
	end

	ProjectileManager:CreateTrackingProjectile(info) 
	caster:EmitSound("")

	Timers:CreateTimer(0.1, function()
		if extra_projectiles <= 0 or not caster:IsAlive() then return end 
		local targets = FindUnitsInRadius(caster:GetTeam(), target_origin, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		
		if #targets >= 1 then
			info.Target = targets[1]
			
			caster:EmitSound("")
			
			if projectile_height_count == 6 then
				redcreedDummy:SetAbsOrigin(redcreedDummy:GetAbsOrigin() + (right_vec * 300))
				info.vSpawnOrigin = redcreedDummy:GetAbsOrigin()
			elseif projectile_height_count > 6 then
				redcreedDummy:SetAbsOrigin(redcreedDummy:GetAbsOrigin() + (right_vec * 300) - Vector(0,0,400))
				info.vSpawnOrigin = redcreedDummy:GetAbsOrigin()
			else
				redcreedDummy:SetAbsOrigin(redcreedDummy:GetAbsOrigin() + (right_vec * 300) + Vector(0,0,400))
				info.vSpawnOrigin = redcreedDummy:GetAbsOrigin()
			end

			ProjectileManager:CreateTrackingProjectile(info) 
		else
			if projectile_height_count == 6 then
				redcreedDummy:SetAbsOrigin(redcreedDummy:GetAbsOrigin() + (right_vec * 300))
				info.vSpawnOrigin = redcreedDummy:GetAbsOrigin()
			elseif projectile_height_count > 6 then
				redcreedDummy:SetAbsOrigin(redcreedDummy:GetAbsOrigin() + (right_vec * 300) - Vector(0,0,400))
				info.vSpawnOrigin = redcreedDummy:GetAbsOrigin()
			else
				redcreedDummy:SetAbsOrigin(redcreedDummy:GetAbsOrigin() + (right_vec * 300) + Vector(0,0,400))
				info.vSpawnOrigin = redcreedDummy:GetAbsOrigin()
			end

			ProjectileManager:CreateTrackingProjectile(info) 
		end
			

		extra_projectiles = extra_projectiles - 1
		
		projectile_height_count = projectile_height_count + 1

		return 0.1
	end)
	
	end)
end

function scathach_red_creed_combo:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local hCaster = self:GetCaster()
	local caster = self:GetCaster()
	local damage_primary = self:GetSpecialValueFor("damage_primary")
	local damage_secondary = self:GetSpecialValueFor("damage_secondary")
	local explosion_radius = self:GetSpecialValueFor("explosion_radius")
	local heartbreak = self:GetSpecialValueFor("heartbreak")	
	
	hTarget:EmitSound("scathach_gae_bolg_explosion")

	local blastFx = ParticleManager:CreateParticle("particles/custom/cu_chulainn/gae_bolg_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl( blastFx, 0, hTarget:GetAbsOrigin())

	--hTarget:RemoveModifierByName("modifier_heart_of_harmony")
	--hTarget:RemoveModifierByName("modifier_share_damage")
	--hTarget:RemoveModifierByName("modifier_master_intervention")

	DoDamage(hCaster, hTarget, damage_primary, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)
	
--	ScreenShake(hTarget:GetOrigin(), 15, 0.5, 1, 20000, 0, true)
	
	local targets = FindUnitsInRadius(caster:GetTeam(), hTarget:GetOrigin(), nil, explosion_radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	
	for k,blast_radius_target in pairs(targets) do
		if blast_radius_target:IsMagicImmune() then
			return
		end
			
		DoDamage(caster, blast_radius_target, damage_secondary, DAMAGE_TYPE_MAGICAL, 0, self, false)
			
		local slashParticleName = "particles/custom/saber/caliburn/slash.vpcf"
		local explodeParticleName = "particles/custom/saber/caliburn/explosion.vpcf"


			-- Create particle
		local slashFxIndex = ParticleManager:CreateParticle( slashParticleName, PATTACH_ABSORIGIN, blast_radius_target )
		local explodeFxIndex = ParticleManager:CreateParticle( explodeParticleName, PATTACH_ABSORIGIN, blast_radius_target )
	end

	local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, hTarget)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(culling_kill_particle)

	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
	end)
end