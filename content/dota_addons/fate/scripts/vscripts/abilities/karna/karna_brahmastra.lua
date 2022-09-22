karna_brahmastra = class({})

LinkLuaModifier("modifier_brahmastra_stun", "abilities/karna/modifiers/modifier_brahmastra_stun", LUA_MODIFIER_MOTION_NONE)

--[[function karna_brahmastra:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end]]

function karna_brahmastra:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("cast_range")
end

function karna_brahmastra:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	caster:EmitSound("karna_brahmastra_" .. math.random(1,4))

	return true
end

function karna_brahmastra:OnSpellStart()
	local caster = self:GetCaster()

	local aoe = self:GetSpecialValueFor("beam_aoe")
	local range = self:GetSpecialValueFor("range")	

	forwardVec = GetGroundPosition(caster:GetForwardVector(), caster)

    local projectileTable = {
		Ability = self,
		EffectName = "",
		iMoveSpeed = 2000,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = range,
		Source = self:GetCaster(),
		fStartRadius = aoe,
        fEndRadius = aoe,
		bHasFrontialCone = true,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() + 3,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 3000,
	}

    local projectile = ProjectileManager:CreateLinearProjectile(projectileTable)

    self.Dummy = CreateUnitByName("dummy_unit", caster:GetOrigin(), false, caster, caster, caster:GetTeamNumber())
	self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

    self.Laser = ParticleManager:CreateParticle("particles/custom/karna/brahmastra_laser/brahmastra_laser.vpcf", PATTACH_CUSTOMORIGIN, self.Dummy)
    ParticleManager:SetParticleControlEnt(self.Laser, 1, caster, PATTACH_POINT_FOLLOW, "attach_head", caster:GetOrigin(), true)
	ParticleManager:SetParticleControl(self.Laser, 9, caster:GetOrigin())

	caster:EmitSound("karna_brahmastra_laser")
end

function karna_brahmastra:OnProjectileThink(vLocation)
	vLocation = vLocation + Vector(0, 0, 32)

	self.Dummy:SetAbsOrigin(vLocation)
	ParticleManager:SetParticleControlEnt(self.Laser, 1, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_head", self:GetCaster():GetOrigin(), true)
	ParticleManager:SetParticleControl(self.Laser, 9, vLocation)
end

function karna_brahmastra:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	local caster = self:GetCaster()

	if hTarget == nil then
		ParticleManager:DestroyParticle(self.Laser, true)
		ParticleManager:ReleaseParticleIndex(self.Laser)
		self.Dummy:RemoveSelf()
		return 
	else
		DoDamage(caster, hTarget, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
		hTarget:AddNewModifier(caster, hTarget, "modifier_stunned", { Duration = 0.01 })
	end
end