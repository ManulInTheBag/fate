lancelot_harpe = class({})

function lancelot_harpe:OnSpellStart()
	local caster = self:GetCaster()
	local dummyProjectile = {
        Ability = self,
        vSpawnOrigin = caster:GetAbsOrigin(),
        vVelocity = 3000,
        fDistance = self:GetSpecialValueFor("pull_range"),
        fStartRadius = self:GetSpecialValueFor("min_radius"),
        fEndRadius = self:GetSpecialValueFor("max_radius"),
        Source = self:GetCaster(),
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        bProvidesVision = false,
    }

    ProjectileManager:CreateLinearProjectile(dummyProjectile)
end

function lancelot_harpe:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	local hCaster = self:GetCaster()
	local diff = (hCaster:GetAbsOrigin() - hTarget:GetAbsOrigin()):Length2D() - 100
	local damage = self:GetSpecialValueFor("damage")
	local modifierKnockback =
	{
		center_x = hTarget:GetAbsOrigin().x,
		center_y = hTarget:GetAbsOrigin().y,
		center_z = hTarget:GetAbsOrigin().z,
		duration = 0.3,
		knockback_duration = 0.3,
		knockback_distance = diff,
		knockback_height = 100,
	}

	hTarget:AddNewModifier(hCaster, self, "modifier_knockback", modifierKnockback)

	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
end