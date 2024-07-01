-----------------------------
--    Armistice    --
-----------------------------

LinkLuaModifier( "modifier_lu_bu_halberd_throw", "abilities/lu_bu/modifiers/modifier_lu_bu_halberd_throw", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( "modifier_lu_bu_halberd_throw_debuff", "abilities/lu_bu/modifiers/modifier_lu_bu_halberd_throw_debuff", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lu_bu_halberd_throw_self_stun", "abilities/lu_bu/modifiers/modifier_lu_bu_halberd_throw_self_stun", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_lu_bu_halberd_throw_knockback", "abilities/lu_bu/modifiers/modifier_lu_bu_halberd_throw_knockback", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_assault_skillswap_2", "abilities/lu_bu/modifiers/modifier_assault_skillswap_2", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_relentless_assault_blocker", "abilities/lu_bu/modifiers/modifier_relentless_assault_blocker", LUA_MODIFIER_MOTION_NONE )

lu_bu_halberd_throw = class({})

--------------------------------------------------------------------------------
-- Ability Start
function lu_bu_halberd_throw:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- load data
	local projectile_name = "particles/custom/lu_bu/lu_bu_spear.vpcf"
	local projectile_distance = self:GetSpecialValueFor("spear_range")-70
	local projectile_speed = self:GetSpecialValueFor("spear_speed")
	local projectile_radius = self:GetSpecialValueFor("spear_width")
	local projectile_vision = self:GetSpecialValueFor("spear_vision")
	
	if caster:HasModifier("modifier_lu_bu_ruthless_warrior_attribute") then
		projectile_distance = projectile_distance + 200 + (caster:GetStrength()*1)
	end
	
	-- calculate direction
	self.direction = point - caster:GetOrigin()
	self.direction.z = 0
	self.direction = self.direction:Normalized()

	local info = {
		Source = caster,
		Ability = self,
		vSpawnOrigin = caster:GetOrigin()+ self.direction * 70,
		
	    bDeleteOnHit = false,
	    
	   iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
	    
	    EffectName = projectile_name,
	    fDistance = projectile_distance,
	    fStartRadius = projectile_radius,
	    fEndRadius =projectile_radius,
		vVelocity = self.direction * projectile_speed,
	
		bHasFrontalCone = false,
		bReplaceExisting = false,
		fExpireTime = GameRules:GetGameTime() + 10.0,
		
		bProvidesVision = true,
		iVisionRadius = projectile_vision,
		fVisionDuration = 10,
		iVisionTeamNumber = caster:GetTeamNumber()
	}
	ProjectileManager:CreateLinearProjectile(info)

	-- play effects
	caster:EmitSound("lu_bu_spear_throw")
	
	local relentless_assault = caster:FindModifierByNameAndCaster( "modifier_lu_bu_relentless_assault", caster )
	local assault_stack = caster:GetModifierStackCount("modifier_lu_bu_relentless_assault", caster)
	
	if caster:HasModifier("modifier_lu_bu_insurmountable_assault_attribute") and assault_stack < 3 and not caster:HasModifier("modifier_relentless_assault_blocker") then
		relentless_assault:SetStackCount(assault_stack + 1)
	elseif caster:HasModifier("modifier_lu_bu_insurmountable_assault_attribute") and assault_stack >= 3 and not caster:HasModifier("modifier_relentless_assault_blocker") then
		caster:AddNewModifier(caster, self, "modifier_assault_skillswap_2", {})
		caster:AddNewModifier(caster, self, "modifier_relentless_assault_blocker", {})
	end
end

function lu_bu_halberd_throw:OnProjectileHit_ExtraData(target, vLocation, tData)
	if target == nil then return end
	
	local caster = self:GetCaster()

	local damage = self:GetSpecialValueFor( "damage" )  
	local wall_bonus_damage =  100
	local wall_stun = self:GetSpecialValueFor( "stun_duration" ) 
	
	if caster:HasModifier("modifier_lu_bu_ruthless_warrior_attribute") then
		wall_stun = wall_stun + 0.5
		damage = damage + 100
		wall_bonus_damage = wall_bonus_damage + 50
	end
	
	vectorA = Vector(0,0,0)
	
	target:EmitSound("lu_bu_spear_throw_impact")
	
	DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, self, false)
	
	local pushTarget = Physics:Unit(target)
    target:PreventDI()
    target:SetPhysicsFriction(0)
	--local vectorC = (target:GetAbsOrigin() - caster:GetAbsOrigin()) 


	-- get the direction where target will be pushed back to
	local vectorB = self.direction - vectorA
	if not IsKnockbackImmune(target) then
		target:SetPhysicsVelocity(vectorB:Normalized() * 1750)
	    target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
		local initialUnitOrigin = target:GetAbsOrigin()
		
		target:OnPhysicsFrame(function(unit) -- pushback distance check
			local unitOrigin = unit:GetAbsOrigin()
			local diff = unitOrigin - initialUnitOrigin
			local n_diff = diff:Normalized()
			unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) -- track the movement of target being pushed back
			if diff:Length() > 500 then -- if pushback distance is over 500, stop it
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
			target:AddNewModifier(caster, target, "modifier_stunned", { Duration = wall_stun })
			--giveUnitDataDrivenModifier(caster, target, "stunned",  WallStun)
			DoDamage(caster, unit, wall_bonus_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end)
	end
end

function lu_bu_halberd_throw:OnUpgrade()
    local relentless_assault = self:GetCaster():FindAbilityByName("lu_bu_relentless_assault_two")
    relentless_assault:SetLevel(self:GetLevel())
end