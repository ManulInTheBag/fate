atalanta_dash = class({})

function atalanta_dash:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local target = self:GetCursorPosition()
	local dist = self:GetSpecialValueFor("distance")

	if (target - caster:GetAbsOrigin()):Length2D() > dist then
		target = caster:GetAbsOrigin() + (((target - caster:GetAbsOrigin()):Normalized()) * dist)
	end

	dist = (target - caster:GetAbsOrigin()):Length2D()

	local time = dist/1200

	local qdProjectile = 
	{
		Ability = ability,
        EffectName = nil,--"particles/custom/false_assassin/fa_quickdraw.vpcf",
        iMoveSpeed = 1200,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = dist,
        fStartRadius = 200,
        fEndRadius = 200,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 1200
	}
	local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)

	--giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", time)

	--[[local fxIndex = ParticleManager:CreateParticle("particles/okita/okita_counterhelix.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl( fxIndex, 0, caster:GetAbsOrigin())]]
	local sin = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(caster:GetForwardVector() * 1200)
	caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)

	Timers:CreateTimer("atalanta_dash", {
		endTime = time,
		callback = function()
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	return end
	})
end

function atalanta_dash:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local ability = self
	local damage = ability:GetSpecialValueFor("damage")

	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	for i = 1,self:GetSpecialValueFor("curse_stacks") do
		caster:FindAbilityByName("atalanta_curse"):Curse(hTarget)
	end
end