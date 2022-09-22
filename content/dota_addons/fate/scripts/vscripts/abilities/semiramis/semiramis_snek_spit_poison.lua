semiramis_snek_spit_poison = class({})

LinkLuaModifier("modifier_snek_poison", "abilities/semiramis/modifiers/modifier_snek_poison", LUA_MODIFIER_MOTION_NONE)

function semiramis_snek_spit_poison:OnSpellStart()
	local caster = self:GetCaster()
	local target_loc = self:GetCursorPosition()

	local range = self:GetSpecialValueFor("range")
	local aoe = self:GetSpecialValueFor("aoe")

	local projectileTable = {
		Ability = self,
		EffectName = "particles/units/heroes/hero_venomancer/venomancer_venomous_gale.vpcf",
		iMoveSpeed = 1500,
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
		vVelocity = caster:GetForwardVector() * 1350,
	}

    local projectile = ProjectileManager:CreateLinearProjectile(projectileTable)
end

function semiramis_snek_spit_poison:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	hTarget:AddNewModifier(self:GetCaster(), self, "modifier_snek_poison", { Duration = self:GetSpecialValueFor("duration"),
																			 DamagePerSec = self:GetSpecialValueFor("damage"),
																			 Slow = self:GetSpecialValueFor("slow")})
end