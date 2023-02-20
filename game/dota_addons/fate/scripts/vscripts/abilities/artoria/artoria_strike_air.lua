-----------------------------
--    Strike Air - Hammer of the Wind King    --
-----------------------------

artoria_strike_air = class({})

LinkLuaModifier( "modifier_artoria_np_stun", "abilities/artoria/modifiers/modifier_artoria_np_stun", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier("modifier_artoria_strike_air_stun", "abilities/artoria/modifiers/modifier_artoria_strike_air_stun", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function artoria_strike_air:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
    local player = caster:GetPlayerOwner()
	
	self.vStartPosition = self:GetCaster():GetOrigin()
	self.vProjectileLocation = vStartPosition
	
	EmitGlobalSound("Saber.StrikeAir_Cast")

	Timers:CreateTimer(0.4, function()
		EmitGlobalSound("Saber.StrikeAir_Release"..math.random(1,2))
	end)
	
	Timers:CreateTimer(0.01, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration=1.25, activity=ACT_DOTA_CAST_ABILITY_6, rate=1.0})
		end
	end)
	
	--caster:AddNewModifier(caster, self, "modifier_artoria_np_stun", { Duration = 1.26 })
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 1.26)
	
	local strikeair = 
	{
		Ability = self,
        EffectName = "particles/custom/saber_strike_air_blast.vpcf",
        iMoveSpeed = 3500,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = self:GetSpecialValueFor("length") - self:GetSpecialValueFor("width"),
        fStartRadius = self:GetSpecialValueFor("width"),
        fEndRadius = self:GetSpecialValueFor("width"),
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 6.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 3500,
		bProvidesVision = true,
		iVisionRadius = 500
	}
    --ProjectileManager:CreateTrackingProjectile(strikeair)
	
	Timers:CreateTimer(0.4, function()
		if caster:IsAlive() then 
			strikeair.vSpawnOrigin = caster:GetAbsOrigin() 
			strikeair.vVelocity = caster:GetForwardVector() * 3500
			projectile = ProjectileManager:CreateLinearProjectile(strikeair)
		end
	end)
	caster:EmitSound("Hero_Invoker.Tornado")	
end

function artoria_strike_air:OnProjectileHit_ExtraData(target, vLocation, tData)
	if target == nil then return end
	
	local caster = self:GetCaster()

	local damage = self:GetSpecialValueFor( "damage" )  
	local wall_bonus_damage = self:GetSpecialValueFor( "wall_bonus_damage" )  
	local wall_stun = self:GetSpecialValueFor( "wall_stun" ) 
	
	if target:HasModifier("modifier_wind_protection_passive") or target:IsMagicImmune() then 
		return 
	end

	if caster:HasModifier("modifier_artoria_strike_air_attribute") then
		damage = damage + 200
	end
	
	vectorA = Vector(0,0,0)
	
	DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)
	giveUnitDataDrivenModifier(caster, target, "pause_sealenabled", 0.5)
	
	local pushTarget = Physics:Unit(target)
    target:PreventDI()
    target:SetPhysicsFriction(0)
	local vectorC = (target:GetAbsOrigin() - caster:GetAbsOrigin()) 
	-- get the direction where target will be pushed back to
	local vectorB = vectorC - vectorA
	target:SetPhysicsVelocity(vectorB:Normalized() * 1200)
    target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	local initialUnitOrigin = target:GetAbsOrigin()
	
	target:OnPhysicsFrame(function(unit) -- pushback distance check
		local unitOrigin = unit:GetAbsOrigin()
		local diff = unitOrigin - initialUnitOrigin
		local n_diff = diff:Normalized()
		unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) -- track the movement of target being pushed back
		if diff:Length() > 600 then -- if pushback distance is over 500, stop it
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
		target:AddNewModifier(caster, target, "modifier_artoria_strike_air_stun", { Duration = wall_stun })
		--giveUnitDataDrivenModifier(caster, target, "stunned",  WallStun)
		DoDamage(caster, unit, wall_bonus_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	end)
end