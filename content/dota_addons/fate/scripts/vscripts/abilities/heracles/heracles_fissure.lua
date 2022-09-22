heracles_fissure = class({})

function heracles_fissure:OnSpellStart()
	local caster = self:GetCaster()
	local projectile_length = self:GetSpecialValueFor("fissure_length")
	local projectile_speed = self:GetSpecialValueFor("projectile_speed")
	local fissure_count = projectile_length / 100

	local frontward = caster:GetForwardVector()
	local fiss = 
	{
		Ability = self,
        EffectName = "particles/custom/berserker/fissure_strike/shockwave.vpcf",
        iMoveSpeed = projectile_speed,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = projectile_length,
        fStartRadius = 200,
        fEndRadius = 200,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 0.5,
		bDeleteOnHit = false,
		vVelocity = frontward * projectile_speed
	}
	caster.FissureOrigin  = caster:GetAbsOrigin()
	caster.FissureTarget = keys.target_points[1]
	projectile = ProjectileManager:CreateLinearProjectile(fiss)

	Timers:CreateTimer(function()
		if counter >= fissure_count then return end 
			local projectile_location = 

			local rock_dummy = CreateUnitByName("ubw_sword_confine_dummy", Vector(0,0,0), false, caster, caster, caster:GetTeamNumber())
			rock_dummy:FindAbilityByName("dummy_visible_unit_passive_no_fly"):SetLevel(1)
			rock_dummy:SetForwardVector(Vector(0,0,-1))
		return 0.1
	end)
end