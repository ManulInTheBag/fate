LinkLuaModifier("modifier_arcueid_shut_up_slow", "abilities/arcueid/arcueid_shut_up", LUA_MODIFIER_MOTION_NONE)

arcueid_shut_up = class({})

function arcueid_shut_up:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local damage = self:GetSpecialValueFor("damage")
	local collide_damage = self:GetSpecialValueFor("collide_damage")
	local pushback_range = self:GetSpecialValueFor("range")
	local target = self:GetCursorTarget()
	if IsSpellBlocked(target) then return end
	if caster.MonstrousStrengthAcquired then
		collide_damage = collide_damage + caster:GetStrength()*self:GetSpecialValueFor("collide_mult")
		--pushback_range = pushback_range + caster:GetStrength()*self:GetSpecialValueFor("range_mult")
	end

	caster:EmitSound("arcueid_swing")
	caster:EmitSound("arcueid_shut_"..math.random(1,4))

	--[[local enemies = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        caster:GetAbsOrigin(),
								        caster:GetAbsOrigin() + caster:GetForwardVector()*200,
								        nil,
								        100,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_NONE
    								)]]

	--for _, target in pairs(enemies) do
		DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)
		caster:FindAbilityByName("arcueid_impulses"):Pepeg(target)
		target:AddNewModifier(caster, self, "modifier_arcueid_shut_up_slow", {Duration = self:GetSpecialValueFor("slow_duration")})

		if caster.RecklesnessAcquired then
			target:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.1})
		end

		local qdProjectile = 
		{
			Ability = ability,
	        EffectName = nil,
	        iMoveSpeed = self:GetSpecialValueFor("speed"),
	        vSpawnOrigin = caster:GetOrigin(),
	        fDistance = pushback_range,
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
			vVelocity = caster:GetForwardVector() * self:GetSpecialValueFor("speed")
		}

		--local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)

		if not IsKnockbackImmune(target) then
			local casterfacing = caster:GetForwardVector()
			local pushTarget = Physics:Unit(target)
			local casterOrigin = caster:GetAbsOrigin()
			local initialUnitOrigin = target:GetAbsOrigin()
			target:PreventDI()
			target:SetPhysicsFriction(0)
			target:SetPhysicsVelocity(casterfacing:Normalized() * self:GetSpecialValueFor("speed"))
			target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
		    target:OnPhysicsFrame(function(unit) 
				local unitOrigin = unit:GetAbsOrigin()
				local diff = unitOrigin - initialUnitOrigin
				local n_diff = diff:Normalized()
				unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) 
				if diff:Length() > pushback_range then
					unit:PreventDI(false)
					unit:SetPhysicsVelocity(Vector(0,0,0))
					unit:OnPhysicsFrame(nil)
					FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
				end
			end)	
			target:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
				unit:SetBounceMultiplier(0)
				unit:PreventDI(false)
				unit:SetPhysicsVelocity(Vector(0,0,0))
				giveUnitDataDrivenModifier(caster, target, "stunned", self:GetSpecialValueFor("stun_duration"))
				target:EmitSound("Hero_EarthShaker.Fissure")
				DoDamage(caster, target, collide_damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
				ProjectileManager:DestroyLinearProjectile(projectile)
			end)
		end

		target:EmitSound("Hero_EarthShaker.Fissure")
		--[[local groundFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_ABSORIGIN, target )
		ParticleManager:SetParticleControl( groundFx, 1, target:GetAbsOrigin())]]
		local groundFx = ParticleManager:CreateParticle( "particles/arcueid/arcueid_blast.vpcf", PATTACH_ABSORIGIN, caster )
		ParticleManager:SetParticleControl( groundFx, 0, Vector(0, -180, 0))
		ParticleManager:SetParticleControl( groundFx, 5, target:GetAbsOrigin() + Vector(0, 0, 60))
	--end
end

function arcueid_shut_up:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local target = hTarget
	local damage = self:GetSpecialValueFor("damage")
	local duration = self:GetSpecialValueFor("duration")

	--giveUnitDataDrivenModifier(caster, hTarget, "rooted", duration)
	DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)
	caster:FindAbilityByName("arcueid_impulses"):Pepeg(target)
	target:AddNewModifier(caster, self, "modifier_arcueid_shut_up_slow", {Duration = self:GetSpecialValueFor("slow_duration")})
end

modifier_arcueid_shut_up_slow = class({})

function modifier_arcueid_shut_up_slow:IsHidden() return false end
function modifier_arcueid_shut_up_slow:IsDebuff() return true end
function modifier_arcueid_shut_up_slow:RemoveOnDeath() return true end
function modifier_arcueid_shut_up_slow:DeclareFunctions()
  return {  MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE  }
end
function modifier_arcueid_shut_up_slow:GetModifierMoveSpeedBonus_Percentage()
  return -1*self:GetAbility():GetSpecialValueFor("slow_percent")
end