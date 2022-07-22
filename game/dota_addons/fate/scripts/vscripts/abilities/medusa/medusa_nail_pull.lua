medusa_nail_pull = class({})

function medusa_nail_pull:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_POINT
end

function medusa_nail_pull:OnSpellStart()
	local caster = self:GetCaster()
	local projectile_vector = self:GetCursorPosition() - caster:GetAbsOrigin()
	local aoe = self:GetSpecialValueFor("nail_aoe")
	local range = self:GetSpecialValueFor("range")	

	projectile_vector.z = 0
	projectile_vector = projectile_vector:Normalized()

    local projectileTable = {
		Ability = self,
		EffectName = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf",
		iMoveSpeed = 900,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = range,
		Source = caster,
		fStartRadius = aoe,
        fEndRadius = aoe,
		bHasFrontialCone = true,
		bReplaceExisting = true,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() + 3,
		bDeleteOnHit = true,
		vVelocity = projectile_vector * 900,
	}

    local projectile = ProjectileManager:CreateLinearProjectile(projectileTable)

    self.NailDummy = SpawnDummy(caster, caster:GetAbsOrigin(), projectile_vector)
    self.NailParticle = ParticleManager:CreateParticle("particles/econ/items/drow/drow_ti6/drow_ti6_silence_arrow.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.NailDummy)
    ParticleManager:SetParticleControl( self.NailParticle, 0, self.NailDummy:GetAbsOrigin() )
end

function medusa_nail_pull:OnProjectileThink(vLocation)
	--[[print("thonkang")

	if IsValidEntity(self.NailDummy) then		
		self.NailDummy:SetAbsOrigin(GetGroundPosition(vLocation, nil))
	end	]]

	--self:SyncFx(vLocation)
end

--[[function medusa_nail_pull:SyncFx(vLocation)
	print("synching particle")
	FxDestroyer(self.ChainFx, false)
	self.ChainFx =  ParticleManager:CreateParticle("particles/custom/rider/chain_web_current.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.NailDummy)
	ParticleManager:SetParticleControl(self.ChainFx, 2, self:GetCaster():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.ChainFx, 3, vLocation)
end

function medusa_nail_pull:DestroyFx()
	FxDestroyer(self.ChainFx, false)
end]]

function medusa_nail_pull:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	if IsValidEntity(self.NailDummy) then
		self.NailDummy:RemoveSelf()
	end

	ParticleManager:DestroyParticle(self.NailParticle, true)
	ParticleManager:ReleaseParticleIndex(self.NailParticle)


	local hCaster = self:GetCaster()
	local pull_distance = self:GetSpecialValueFor("pull_distance")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local collide_damage = self:GetSpecialValueFor("collide_damage")
	local initialUnitOrigin = hTarget:GetAbsOrigin()

	hTarget:EmitSound("Hero_Pudge.AttackHookImpact")
	
	local sin = Physics:Unit(hTarget)
	hTarget:SetPhysicsFriction(0)
	hTarget:SetPhysicsVelocity((hCaster:GetAbsOrigin() - hTarget:GetAbsOrigin()):Normalized() * (pull_distance / 0.25))
	hTarget:SetNavCollisionType(PHYSICS_NAV_BOUNCE)	

	hTarget:OnPhysicsFrame(function(unit) 									 -- pushback distance check
		local unitOrigin = unit:GetAbsOrigin()
		local diff = unitOrigin - initialUnitOrigin
		local n_diff = diff:Normalized()
		unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) -- track the movement of target being pushed back
		if diff:Length() > pull_distance then 								 -- if pushback distance is over 400, stop it
			unit:PreventDI(false)
			unit:SetPhysicsVelocity(Vector(0,0,0))
			unit:OnPhysicsFrame(nil)
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
		end
	end)		
	
	hTarget:OnPreBounce(function(unit, normal) 								 -- stop the pushback when unit hits wall
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		giveUnitDataDrivenModifier(hCaster, hTarget, "stunned", stun_duration)
		DoDamage(hCaster, hTarget, collide_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	end)
end