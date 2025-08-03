scathach_red_wind = class({})
LinkLuaModifier("modifier_scathach_combo_2_window", "abilities/scathach/modifiers/modifier_scathach_combo_2_window", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stachach_gae_bolg_curse", "abilities/scathach/scathach_gae_bolg.lua", LUA_MODIFIER_MOTION_NONE)
function scathach_red_wind:GetCastRange(vLocation, hTarget)
    local range = self:GetSpecialValueFor("distance")

    if self:GetCaster():HasModifier("modifier_scathach_primeval_rune_attribute") then
        range = range + 200
    end
    return range
end

function scathach_red_wind:OnSpellStart()
	local caster = self:GetCaster()
	
	 local randomVec = RandomInt(-400,400)

	StartAnimation(caster, {duration=1.00, activity=ACT_DOTA_CAST_ABILITY_1, rate=1.0})
	
	local proc = RandomInt(1, 100)
	
	if 0 < proc and proc < 33 then
		caster:EmitSound("scathach_red_wind")
	elseif 34 < proc and proc < 66 then
		caster:EmitSound("scathach_red_wind_2")
	elseif 67 < proc and proc < 101 then
		caster:EmitSound("scathach_red_wind_3")
	end

	chaindamage = self:GetSpecialValueFor("damage")
	
	stun_duration = self:GetSpecialValueFor("stun_duration")
	
	chain_distance = self:GetSpecialValueFor("distance")
	
	charge_distance = self:GetSpecialValueFor("charge_distance")
	
	if caster:HasModifier("modifier_scathach_primeval_rune_attribute") then
		chain_distance = chain_distance + 200
	end
	
	if caster:HasModifier("modifier_scathach_primeval_rune_attribute") then
		charge_distance = charge_distance + 500
	end

	local bindingchain_projectile = 
	{
		Ability = self,
        EffectName = nil,
        iMoveSpeed = 1500,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = chain_distance,
        fStartRadius = 300,
        fEndRadius = 300,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 1250
	}

	local projectile = ProjectileManager:CreateLinearProjectile(bindingchain_projectile)
	caster:AddNewModifier(caster, self, "modifier_scathach_red_wind_stun", { Duration = 0.75 })
	caster:EmitSound("caster_PhantomLancer.Doppelwalk") 
	local sin = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(caster:GetForwardVector() * charge_distance)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	
	local particle3 = ParticleManager:CreateParticle("particles/custom/scathach/red_wind_lightning_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	
	ScreenShake(caster:GetOrigin(), 1.5, 0.5, 2, 5000, 0, true)
	
	-- Stomp
	local stompParticleIndex = ParticleManager:CreateParticle( "particles/custom/scathach/red_wind_impact.vpcf", PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( stompParticleIndex, 0, caster:GetAbsOrigin() )
	ParticleManager:SetParticleControl( stompParticleIndex, 1, Vector( radius, radius, radius ) )
	
	 local particle = ParticleManager:CreateParticle("particles/custom/scathach/red_wind_lightning_1.vpcf", PATTACH_CUSTOMORIGIN, caster)
     local particle2 = ParticleManager:CreateParticle("particles/custom/scathach/red_wind_lightning_1.vpcf", PATTACH_CUSTOMORIGIN, caster)
    --local particle = ParticleManager:CreateParticle("particles/units/casteres/caster_zuus/zuus_static_field.vpcf", PATTACH_CUSTOMORIGIN, caster)
    --local particle2 = ParticleManager:CreateParticle("particles/units/casteres/caster_zuus/zuus_static_field.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(particle3, 1, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle3, 2, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl( particle, 0, caster:GetForwardVector() + Vector(randomVec, 0, 250))
    ParticleManager:SetParticleControl( particle2, 0, caster:GetForwardVector() + Vector(randomVec, 0, 100))
	Timers:CreateTimer( 1.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
		ParticleManager:DestroyParticle( particle2, false )
		ParticleManager:ReleaseParticleIndex( particle2 )
	end)

	Timers:CreateTimer("scathach_red_wind", {
		endTime = 0.5,
		callback = function()
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("modifier_scathach_red_wind_stun")
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("scathach_red_wind")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("modifier_scathach_red_wind_stun")
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end)
	
	self:CheckCombo()
end

function scathach_red_wind:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local chaindamage = self:GetSpecialValueFor("damage")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	
	if caster:HasModifier("modifier_scathach_primeval_rune_attribute") then
		chaindamage = chaindamage + 300
		stun_duration = stun_duration + 0.2
	end
	
	DoDamage(caster, hTarget, chaindamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	hTarget:AddNewModifier(caster, self, "modifier_stachach_gae_bolg_curse", {duration = 10})
	hTarget:AddNewModifier(caster, self, "modifier_stunned", {Duration = stun_duration})
	--hTarget:AddNewModifier(caster, self, "modifier_scathach_red_wind_stun", { Duration = stun_duration })
end

function scathach_red_wind:CheckCombo()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect(false) >= 29.1 then
		if caster:FindAbilityByName("scathach_red_creed_combo"):IsCooldownReady() and caster:FindAbilityByName("scathach_combo_gate_of_sky"):IsCooldownReady() then
			caster:AddNewModifier(caster, self, "modifier_scathach_combo_2_window", { Duration = 4 })
		end
	end
end