gille_tentacle_hook = class({})

function gille_tentacle_hook:OnSpellStart()
	local caster = self:GetCaster()
	caster.unithit = false
	local targetPoint = self:GetCursorPosition()
	local range = self:GetSpecialValueFor("range")
	local direction = (targetPoint - caster:GetAbsOrigin()):Normalized()
	direction.z = 0

	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = "",
		iMoveSpeed = 1800,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = range,
		fStartRadius = 150,
		fEndRadius = 150,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO,
		bDeleteOnHit = false,
		vVelocity = direction * 1800,
	})
end

function gille_tentacle_hook:OnProjectileHit(hTarget, vLocation)
	if not hTarget then return end
	local caster = self:GetCaster()
	local target = hTarget

	if caster.IsHookHit or caster.unithit then return end

	if(target:GetUnitName() ~= "gille_gigantic_horror") then
		caster.unithit = true
		caster.IsHookHit = true
	else
		return
	end
	target:EmitSound("Hero_Pudge.AttackHookImpact")
	local diff = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	target:AddNewModifier(target, target, "modifier_stunned", {Duration = 0.75})
	if not IsKnockbackImmune(target) then
		local pullTarget = Physics:Unit(target)
		local pullVector = (caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized() * diff * 2

		target:PreventDI()
		target:SetPhysicsFriction(0)
		target:SetPhysicsVelocity(Vector(pullVector.x, pullVector.y, 2000))
		target:SetNavCollisionType(PHYSICS_NAV_NOTHING)
		target:FollowNavMesh(false)
		target:SetAutoUnstuck(false)

		Timers:CreateTimer({
			endTime = 0.25,
			callback = function()
			target:SetPhysicsVelocity(Vector(pullVector.x, pullVector.y, -2000))
		end
		})

		Timers:CreateTimer(0.5, function()
			target:PreventDI(false)
			target:SetPhysicsVelocity(Vector(0,0,0))
			target:OnPhysicsFrame(nil)
			target:SetAutoUnstuck(true)
			FindClearSpaceForUnit(target, target:GetAbsOrigin(), true)

		end)
	end
	Timers:CreateTimer(1.0, function()
		caster.IsHookHit = false
		caster.unithit = false
	end)
end
