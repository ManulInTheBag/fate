heracles_nine_lives = class({})

LinkLuaModifier("modifier_heracles_nine_lives", "abilities/heracles/modifiers/modifier_heracles_nine_lives", LUA_MODIFIER_MOTION_NONE)

function heracles_nine_lives:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function heracles_nine_lives:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_CAST_ABILITY_5, rate=0.2})

	return true
end

--[[function heracles_nine_lives:CastFilterResultLocation(vLocation)
	if self:GetCaster():HasModifier("modifier_heracles_berserk") then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function heracles_nine_lives:GetCustomCastErrorLocation(vLocation)
	return "Cannot use while Berserked"
end]]

function heracles_nine_lives:OnSpellStart()
	local caster = self:GetCaster()
	local casterName = caster:GetName()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	local berserker = Physics:Unit(caster)
	local origin = caster:GetAbsOrigin()
	local distance = (targetPoint - origin):Length2D()/0.3
	local forward = (targetPoint - origin):Normalized() * distance
	local berserked = caster:HasModifier("modifier_heracles_berserk")
	local time = 0.3
	if berserked then
		time = 0.01
	end

	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(caster:GetForwardVector()*distance)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 3.75) --change to sealdisabled to return revoke here, if you want
	caster:EmitSound("Hero_OgreMagi.Ignite.Cast")

	StartAnimation(caster, {duration=1, activity=ACT_DOTA_RUN, rate=2.0})

	caster.NineTimer = Timers:CreateTimer(time, function()
		self:StartNineLives(berserked)
	end)
	caster:OnPhysicsFrame(function(unit)
		if CheckDummyCollide(unit) then
			self:StartNineLives()
		end
	end)
	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		self:StartNineLives()
	end)
end

function heracles_nine_lives:StartNineLives(berserked)
	local caster = self:GetCaster()
	local time = 0.01
	if berserked then time = 0.3 end
	Timers:CreateTimer(time, function()
		caster:OnPreBounce(nil)
		caster:OnPhysicsFrame(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		Timers:RemoveTimer(caster.NineTimer)
		caster.NineTimer = nil
	end)

	if caster:IsAlive() then
		self:NineLivesHits()
		return 
	end

	return
end

function heracles_nine_lives:NineLivesHits()
	local caster = self:GetCaster()
	local bonus_damage = 0--caster:GetIntellect()

	local casterInitOrigin = caster:GetAbsOrigin() 

	caster:AddNewModifier(caster, self, "modifier_heracles_nine_lives", { Duration = 4,
																 SmallDamage = self:GetSpecialValueFor("damage")+bonus_damage,
																 LargeDamage = self:GetSpecialValueFor("damage_lasthit")+bonus_damage,
																 SmallRadius = self:GetSpecialValueFor("radius"),
																 LargeRadius = self:GetSpecialValueFor("radius_lasthit")})
end