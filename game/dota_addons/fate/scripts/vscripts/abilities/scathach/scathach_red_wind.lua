LinkLuaModifier("modifier_scathach_combo_window", "abilities/scathach/scathach_red_wind", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stachach_gae_bolg_curse", "abilities/scathach/scathach_gae_bolg", LUA_MODIFIER_MOTION_NONE)
scathach_red_wind = class({})

function scathach_red_wind:GetCastRange(vLocation, hTarget)
    local range = 1100

    if self:GetCaster():HasModifier("modifier_scathach_primeval_rune_attribute") then
        range = range + 200
    end
    return range
end

function scathach_red_wind:OnSpellStart()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
	    if self:GetAutoCastState() and caster:FindAbilityByName("scathach_gate_of_skye"):IsCooldownReady() and caster:IsAlive() then 		
	    	caster:AddNewModifier(caster, self, "modifier_scathach_combo_window", {duration = 3})
		end
	end
	
	local randomVec = RandomInt(-400,400)

	StartAnimation(caster, {duration=1.00, activity=ACT_DOTA_CAST_ABILITY_1, rate=1.0})
	local point = self:GetCursorPosition()
	local distance = (point - caster:GetAbsOrigin()):Length2D()
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
	
	charge_distance = self:GetSpecialValueFor("distance")
	
	if distance > charge_distance then
		distance = charge_distance
	end


	local bindingchain_projectile = 
	{
		Ability = self,
        EffectName = nil,
        iMoveSpeed =  charge_distance*2,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = distance,
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
		vVelocity = caster:GetForwardVector() * 1250
	}
	local dash_time = distance/(charge_distance*2)
	local projectile = ProjectileManager:CreateLinearProjectile(bindingchain_projectile)

	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", dash_time+0.1)
	caster:EmitSound("caster_PhantomLancer.Doppelwalk") 
	local sin = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(caster:GetForwardVector() * charge_distance*2)
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
		endTime = dash_time,
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
	
	--self:CheckCombo()
end

function scathach_red_wind:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local chaindamage = self:GetSpecialValueFor("damage")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	
	if caster:HasModifier("modifier_scathach_primeval_rune_attribute") then
		chaindamage = chaindamage + 100
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

modifier_scathach_combo_window = class({})

function modifier_scathach_combo_window:IsHidden() return true end
function modifier_scathach_combo_window:IsDebuff() return false end
function modifier_scathach_combo_window:OnCreated()
	if IsServer() then
		local caster = self:GetParent()
			print("3")
		if caster:GetAbilityByIndex(3):GetName() == "scathach_pinning_thorn" then	    		
			caster:SwapAbilities("scathach_gate_of_skye", "scathach_pinning_thorn", true, false)	
		end
	end
end
function modifier_scathach_combo_window:OnDestroy()
	if IsServer() then
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(3):GetName() == "scathach_gate_of_skye" then
			caster:SwapAbilities("scathach_gate_of_skye", "scathach_pinning_thorn", false, true)
		end
	end
end
