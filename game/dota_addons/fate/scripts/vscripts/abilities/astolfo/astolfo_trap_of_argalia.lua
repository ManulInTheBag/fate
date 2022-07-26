astolfo_trap_of_argalia = class({})

function astolfo_trap_of_argalia:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local qdProjectile = 
	{
		Ability = ability,
        EffectName = "particles/custom/false_assassin/fa_quickdraw.vpcf",
        iMoveSpeed = 1850,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = 925,
        fStartRadius = 150,
        fEndRadius = 150,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 1850
	}

	caster:EmitSound("Astolfo_Slide_" .. math.random(1,5))

	local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.5)
	caster:EmitSound("Hero_PhantomLancer.Doppelwalk") 
	local sin = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(caster:GetForwardVector() * 1850)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

	Timers:CreateTimer("trap_dash", {
		endTime = 0.5,
		callback = function()
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("trap_dash")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end)
end

function astolfo_trap_of_argalia:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local duration = self:GetSpecialValueFor("duration")

	--giveUnitDataDrivenModifier(caster, hTarget, "rooted", duration)
	giveUnitDataDrivenModifier(caster, hTarget, "locked", duration)

	hTarget:EmitSound("Hero_Sniper.AssassinateDamage")
	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

	if caster.bIsSanityAcquired then
		DoDamage(caster, hTarget, caster:GetAverageTrueAttackDamage(caster)*2.5, DAMAGE_TYPE_PHYSICAL, 0, self, false)
	end
end