gille_subterranean_skewer = class({})

function gille_subterranean_skewer:OnSpellStart()
	local caster = self:GetCaster()
	local casterLoc = caster:GetAbsOrigin()
	local targetPoint = self:GetCursorPosition()
	local diff = (targetPoint - casterLoc):Normalized()
	local frontward = caster:GetForwardVector()

	caster:EmitSound("ZC.Tentacle1")

	local skewer =
	{
		Ability = self,
		EffectName = "",
		iMoveSpeed = 3000,
		vSpawnOrigin = casterLoc - frontward*100,
		fDistance = 1000 + 100,
		fStartRadius = 200,
		fEndRadius = 200,
		Source = caster,
		bHasFrontalCone = true,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 3000
	}
	Timers:CreateTimer(1.0, function()
		ProjectileManager:CreateLinearProjectile(skewer)
		caster:EmitSound("Hero_Lion.Impale")
	end)

	local tentacleCounter1 = 0
	Timers:CreateTimer(1.0, function()
		if tentacleCounter1 > 10 then return end

		local tentacleFx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_spell_ravage_hit.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(tentacleFx, 0, casterLoc + diff * 110 * tentacleCounter1 )
		Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( tentacleFx, false )
			ParticleManager:ReleaseParticleIndex( tentacleFx )
		end)
		tentacleCounter1 = tentacleCounter1 + 1
		return 0.033
	end)
end

function gille_subterranean_skewer:OnProjectileHit(hTarget, vLocation)
	if not hTarget then return end
	local caster = self:GetCaster()
	ApplyAirborne(caster, hTarget, self:GetSpecialValueFor("stun_duration"))
	DoDamage(caster, hTarget, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
end
