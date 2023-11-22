lu_bu_relentless_assault_four = class({})
LinkLuaModifier( "modifier_lu_bu_relentless_assault_four_silence", "abilities/lu_bu/modifiers/modifier_lu_bu_relentless_assault_four_silence", LUA_MODIFIER_MOTION_NONE )

function lu_bu_relentless_assault_four:OnSpellStart()
	local caster = self:GetCaster()
	local projectile_vector = caster:GetAbsOrigin()
	local aoe = self:GetSpecialValueFor("aoe")
	local range = self:GetSpecialValueFor("radius")	

	projectile_vector.z = 0
	projectile_vector = projectile_vector:Normalized()
	
	caster:EmitSound("lu_bu_relentless_assault_three")

    local projectileTable1 = {
		Ability = self,
		EffectName = "",
		iMoveSpeed = 0,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = 1,
		Source = caster,
		fStartRadius = 500,
        fEndRadius = 500,
		bHasFrontialCone = true,
		bReplaceExisting = true,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() -10,
		bDeleteOnHit = true,
		vVelocity = caster:GetForwardVector() * 1
	}

    local projectile = ProjectileManager:CreateLinearProjectile(projectileTable1)
	
	local projectileTable2 = {
		Ability = self,
		EffectName = "",
		iMoveSpeed = 0,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = 1,
		Source = caster,
		fStartRadius = 500,
        fEndRadius = 500,
		bHasFrontialCone = true,
		bReplaceExisting = true,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() -10,
		bDeleteOnHit = true,
		vVelocity = caster:GetForwardVector() * -1
	}

    local projectile = ProjectileManager:CreateLinearProjectile(projectileTable2)
	
	ScreenShake(caster:GetOrigin(), 7, 4.0, 2, 20000, 0, true)

	-- Create Particle
	local blastFx = ParticleManager:CreateParticle("particles/custom/lu_bu/lu_bu_relentless_four.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl( blastFx, 0, caster:GetAbsOrigin())
	
	local blastFxx = ParticleManager:CreateParticle("particles/custom/lu_bu/lu_bu_armistice_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( blastFxx, 0, caster:GetAbsOrigin())
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( blastFx, false )
		ParticleManager:DestroyParticle( blastFxx, false )
		ParticleManager:ReleaseParticleIndex( blastFx )
		ParticleManager:ReleaseParticleIndex( blastFxx )
	end)
	
	local hp_heal = self:GetSpecialValueFor("heal")
	
	caster:Heal(hp_heal, caster)
	
	caster:RemoveModifierByName("modifier_assault_skillswap_4")
	caster:RemoveModifierByName("modifier_relentless_assault_blocker")
	caster:RemoveModifierByName("modifier_relentless_assault_blocker_combo")
	local relentless_assault = caster:FindModifierByName("modifier_lu_bu_relentless_assault")
	relentless_assault:SetStackCount(1)
end

function lu_bu_relentless_assault_four:OnProjectileThink(vLocation)
	--[[print("thonkang")

	if IsValidEntity(self.NailDummy) then		
		self.NailDummy:SetAbsOrigin(GetGroundPosition(vLocation, nil))
	end	]]

	--self:SyncFx(vLocation)
end

--[[function lu_bu_relentless_assault_four:SyncFx(vLocation)
	print("synching particle")
	FxDestroyer(self.ChainFx, false)
	self.ChainFx =  ParticleManager:CreateParticle("particles/custom/rider/chain_web_current.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.NailDummy)
	ParticleManager:SetParticleControl(self.ChainFx, 2, self:GetCaster():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.ChainFx, 3, vLocation)
end

function lu_bu_relentless_assault_four:DestroyFx()
	FxDestroyer(self.ChainFx, false)
end]]

function lu_bu_relentless_assault_four:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local hCaster = self:GetCaster()
	local pull_distance = self:GetSpecialValueFor("pushback")
	local collide_damage = self:GetSpecialValueFor("collide_damage")
	local silence_duration = self:GetSpecialValueFor("silence_duration")
	local initialUnitOrigin = hTarget:GetAbsOrigin()

	hTarget:EmitSound("Hero_Pudge.AttackHookImpact")
	
	DoDamage(hCaster, hTarget, collide_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	hTarget:AddNewModifier(caster, self, "modifier_lu_bu_relentless_assault_four_silence", { Duration = silence_duration })
	
	local sin = Physics:Unit(hTarget)
	hTarget:SetPhysicsFriction(0)
	hTarget:SetPhysicsVelocity((hCaster:GetAbsOrigin() + hTarget:GetAbsOrigin()):Normalized() * (pull_distance / 0.25))
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
	end)
end