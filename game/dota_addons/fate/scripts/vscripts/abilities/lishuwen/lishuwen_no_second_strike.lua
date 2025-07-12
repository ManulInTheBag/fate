lishuwen_no_second_strike = class({})

LinkLuaModifier("modifier_nss_knockback_stun", "abilities/lishuwen/modifiers/modifier_nss_knockback_stun.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nss_shock", "abilities/lishuwen/modifiers/modifier_nss_shock.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nss_shock_no_revoke", "abilities/lishuwen/modifiers/modifier_nss_shock.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_berserk","abilities/lishuwen/modifiers/modifier_berserk", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nss_shock_stackable", "abilities/lishuwen/lishuwen_no_second_strike.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shuwen_passive_nss_attack_stacking", "abilities/lishuwen/lishuwen_no_second_strike.lua", LUA_MODIFIER_MOTION_NONE)



function lishuwen_no_second_strike:AddShock(target, amount)
	local caster = self:GetCaster()
	local stacks = 0

	if not target or not target:IsAlive() or target:IsNull() then return end

	if target:HasModifier("modifier_nss_shock_stackable") then
		stacks = target:FindModifierByName("modifier_nss_shock_stackable"):GetStackCount()
	end
	if (stacks + amount) > 50 then 
		target:AddNewModifier(caster, self, "modifier_nss_shock_stackable", {duration = self:GetSpecialValueFor("stacks_duration")})
		target:FindModifierByName("modifier_nss_shock_stackable"):SetStackCount(50)
	else
		target:AddNewModifier(caster, self, "modifier_nss_shock_stackable", {duration = self:GetSpecialValueFor("stacks_duration")})
		target:FindModifierByName("modifier_nss_shock_stackable"):SetStackCount(stacks + amount)

	end

end

modifier_nss_shock_stackable = class({})

function lishuwen_no_second_strike:GetIntrinsicModifierName()
	return "modifier_shuwen_passive_nss_attack_stacking"
end

modifier_shuwen_passive_nss_attack_stacking = class({})



function modifier_shuwen_passive_nss_attack_stacking:DeclareFunctions()
	local funcs = {	MODIFIER_EVENT_ON_ATTACK_LANDED
	 }
	return funcs
end

function modifier_shuwen_passive_nss_attack_stacking:OnAttackLanded(keys)	
	if IsServer() then
		if keys.attacker ~= self:GetParent() then return end
		local caster = self:GetParent()
		local target = keys.target
		caster:FindAbilityByName("lishuwen_no_second_strike"):AddShock(target, 1)
	end
end



function modifier_shuwen_passive_nss_attack_stacking:IsHidden()
	return true
end

function modifier_shuwen_passive_nss_attack_stacking:IsDebuff()
	return false
end

function modifier_shuwen_passive_nss_attack_stacking:RemoveOnDeath()
	return false
end

function modifier_shuwen_passive_nss_attack_stacking:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_nss_shock_stackable:IsHidden() return false end
function modifier_nss_shock_stackable:IsDebuff() return true end
function modifier_nss_shock_stackable:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
end
function modifier_nss_shock_stackable:GetModifierTotalDamageOutgoing_Percentage(keys)
    if IsNotNull(self.hCaster)
        and IsNotNull(self.hParent) then
        if IsClient() or bit.band(keys.damage_type or DAMAGE_TYPE_NONE, DAMAGE_TYPE_MAGICAL) ~= 0 then
            return -self.reduction
        end
    end
end



function modifier_nss_shock_stackable:GetModifierHealAmplify_PercentageTarget()
	return -self.heal_reduction
end

function modifier_nss_shock_stackable:GetModifierHPRegenAmplify_Percentage()
	return -self.heal_reduction
end


function modifier_nss_shock_stackable:GetModifierPhysicalArmorBonus()

	if IsServer() then
		CustomNetTables:SetTableValue("sync","nss_variables", { ms_reduction =  -self.slow_power, mr_reduction = -self.mr_reduction, armor_reduction = -self.armor_reduction })
		return -self.armor_reduction
	elseif IsClient() then
		local armor_reduction_jopa = CustomNetTables:GetTableValue("sync","nss_variables").armor_reduction
		return armor_reduction_jopa
	end
end

function modifier_nss_shock_stackable:GetModifierMagicalResistanceBonus()
	if IsServer() then
		CustomNetTables:SetTableValue("sync","nss_variables", { ms_reduction =  -self.slow_power, mr_reduction = -self.mr_reduction, armor_reduction = -self.armor_reduction })
		return -self.mr_reduction
	elseif IsClient() then
		local mr_reduction_jopa = CustomNetTables:GetTableValue("sync","nss_variables").mr_reduction
		return mr_reduction_jopa
	end
end
function modifier_nss_shock_stackable:OnCreated(tTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
	self.stacks = self:GetStackCount()
	self.reduction = 0
	self.slow_power = 0
	self.armor_reduction = 0
	self.mr_reduction = 0
	self.heal_reduction = 0
	if IsServer() then
		Timers:RemoveTimer("liShuwenDebuffsTimer")
	end
	if self.hCaster.LiShuwenNewSa then 
		if self.stacks >= 10 then
			self.reduction = self.hAbility:GetSpecialValueFor("magical_damage_reduction_1")
		end
		if self.stacks>= 25 then
			self.slow_power = self.hAbility:GetSpecialValueFor("slow_power")
			self.heal_reduction = self.hAbility:GetSpecialValueFor("heal_reduction_1")
		end
		if self.stacks >= 50 then
			self.reduction = self.hAbility:GetSpecialValueFor("magical_damage_reduction_2")
			self.armor_reduction = self.hAbility:GetSpecialValueFor("armor_reduction")
			self.mr_reduction = self.hAbility:GetSpecialValueFor("mr_reduction")
			self.heal_reduction = self.hAbility:GetSpecialValueFor("heal_reduction_2")
		end
		CustomNetTables:SetTableValue("sync","nss_variables", { ms_reduction =  -self.slow_power, mr_reduction = -self.mr_reduction, armor_reduction = -self.armor_reduction })

	end
	Timers:CreateTimer("liShuwenDebuffsTimer", {
		endTime = 3,
		callback = function()
			self.reduction = 0
			self.slow_power = 0
			self.armor_reduction = 0
			self.mr_reduction = 0
			self.heal_reduction = 0
			CustomNetTables:SetTableValue("sync","nss_variables", { ms_reduction =  0, mr_reduction =0, armor_reduction = 0 })
		return end
	})
end
function modifier_nss_shock_stackable:OnRefresh(tTable)
    self:OnCreated(tTable)
end

function modifier_nss_shock_stackable:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then
		CustomNetTables:SetTableValue("sync","nss_variables", { ms_reduction =  -self.slow_power, mr_reduction = -self.mr_reduction, armor_reduction = -self.armor_reduction })
		return  -self.slow_power
	elseif IsClient() then
		local ms_reduction_jopa = CustomNetTables:GetTableValue("sync","nss_variables").ms_reduction
		return ms_reduction_jopa
	end
end


function modifier_nss_shock_stackable:GetTexture()
    return "custom/lishuwen_attribute_circulatory_shock"
end

function modifier_nss_shock_stackable:OnDestroy()
	if not IsServer() then return end
end


function lishuwen_no_second_strike:GetCastPoint()
	return self:GetSpecialValueFor("cast_delay")
end
--[[
function lishuwen_no_second_strike:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
end

function lishuwen_no_second_strike:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_OTHER 
		elseif self:GetCaster():HasModifier("modifier_berserk") then
			return UF_FAIL_CUSTOM
		--elseif not self:GetCaster():HasModifier("modifier_cosmic_orbit") then
			--return UF_FAIL_CUSTOM
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function lishuwen_no_second_strike:GetCustomCastErrorTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" then
		return "#Invalid_Target"
	elseif self:GetCaster():HasModifier("modifier_berserk") then
		return "#Berserked_Error"
	--elseif not self:GetCaster():HasModifier("modifier_cosmic_orbit") then
	--	return "#Not_Under_Cosmic_Orbit_Effect"
	else
		return "#Cannot_Cast"
	end
end
]]

function lishuwen_no_second_strike:OnAbilityPhaseStart()
	local caster = self:GetCaster()
    --local target = self:GetCursorTarget()
    local delay = self:GetSpecialValueFor("cast_delay")
	EmitZlodemonTrueSoundEveryone("moskes_li_r")
   	caster:EmitSound("Lishuwen_NP1")
	local vector = (self:GetCursorPosition() - caster:GetAbsOrigin()):Normalized()
	vector.z = 0
	caster:SetForwardVector(vector)
    local windupFx = ParticleManager:CreateParticle( "particles/custom/lishuwen/lishuwen_no_second_strike_windup.vpcf", PATTACH_ABSORIGIN, caster )
    ParticleManager:SetParticleControlTransformForward( windupFx, 0, caster:GetAbsOrigin() + Vector(0,0,100), caster:GetForwardVector())
    ParticleManager:SetParticleControlTransformForward( windupFx, 3, caster:GetAbsOrigin()+ Vector(0,0,100), caster:GetForwardVector())
	local windupFx2 = ParticleManager:CreateParticle( "particles/custom_game/heroes/saitama/saitama_windup.vpcf", PATTACH_ABSORIGIN, caster )
    ParticleManager:SetParticleControl( windupFx2, 0, caster:GetAbsOrigin() )
    ParticleManager:SetParticleControl( windupFx2, 3, caster:GetAbsOrigin())
    Timers:CreateTimer(delay, function()
		ParticleManager:DestroyParticle( windupFx, false )
		ParticleManager:ReleaseParticleIndex( windupFx )
		ParticleManager:DestroyParticle( windupFx2, false )
		ParticleManager:ReleaseParticleIndex( windupFx2 )
    end)

    return true
end

function lishuwen_no_second_strike:OnSpellStart()
	local caster = self:GetCaster()
	local stunDuration = self:GetSpecialValueFor("stun_duration")
	StartAnimation(caster, {duration=0.4, activity=ACT_DOTA_CAST_ABILITY_4_END, rate=0.8})
	local ability = self
	local distance = 700
	EmitGlobalSound("Lishuwen.NoSecondStrike")
	self.firsthit = false
	local vector = (self:GetCursorPosition() - caster:GetAbsOrigin()):Normalized()
	local dash_fx = ParticleManager:CreateParticle("particles/zlodemon/shuwen_jopa_1.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl( dash_fx, 0, caster:GetAbsOrigin() + caster:GetForwardVector() * -150)
	ParticleManager:SetParticleControl( dash_fx, 1, vector*2000)
	ParticleManager:ReleaseParticleIndex(dash_fx)
	local dash_fx2 = ParticleManager:CreateParticle("particles/zlodemon/shuwen_jopa_2.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlTransformForward( dash_fx2, 0, caster:GetAbsOrigin() + vector*100, -vector )
	ParticleManager:SetParticleControl( dash_fx2, 4, self:GetCursorPosition() )
	if caster:IsRooted() then 
		ParticleManager:SetParticleControl( dash_fx2, 5, Vector(-100,0,0) )
	else
		ParticleManager:SetParticleControl( dash_fx2, 5, Vector(-2000,0,0) )
	end
	
	local proj = {}
	if caster:IsRooted() then
	 proj = 
	{
		Ability = ability,
        EffectName = "",
        iMoveSpeed = 2000,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = distance/2,
        fStartRadius = 200,
        fEndRadius = 200,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = vector * 2000
	}
	else

	 proj = 
	{
		Ability = ability,
        EffectName = "",
        iMoveSpeed = 2000,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = distance,
        fStartRadius = 200,
        fEndRadius = 200,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = vector * 2000
	}
	end

	--self.rushfx = ParticleManager:CreateParticle("particles/karna/karna_dash_cone.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
	--ParticleManager:SetParticleControl(self.rushfx, 0, caster:GetAbsOrigin())
	vector.z = 0
	caster:SetForwardVector(vector)
	local projectile = ProjectileManager:CreateLinearProjectile(proj)

	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.3)

	local sin = Physics:Unit(caster)
	if not caster:IsRooted() then
		caster:SetPhysicsFriction(0)
		caster:SetPhysicsVelocity(vector * 2000)
		caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
	
	end
	Timers:CreateTimer("li_shuwen_r_dash", {
		endTime = 0.3,
		callback = function()
		if not caster:IsRooted() then
			caster:OnPreBounce(nil)
			caster:SetBounceMultiplier(0)
			caster:PreventDI(false)
			caster:SetPhysicsVelocity(Vector(0,0,0))
		end
		caster:RemoveModifierByName("pause_sealenabled")
		if not caster:IsRooted() then
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		end
				ParticleManager:DestroyParticle(dash_fx2, false)
		ParticleManager:ReleaseParticleIndex(dash_fx2)
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("li_shuwen_r_dash")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		ProjectileManager:DestroyLinearProjectile(projectile)
		caster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)

		ParticleManager:ReleaseParticleIndex(dash_fx2)

	end)
	
end

function lishuwen_no_second_strike:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("initial_damage")
	local stacks = 0
	if hTarget:HasModifier("modifier_nss_shock_stackable") then
		stacks = hTarget:FindModifierByName("modifier_nss_shock_stackable"):GetStackCount()
	end
	if caster.bIsCirculatoryShockAcquired  then
		--[[if (target:GetName() ~= "npc_dota_hero_juggernaut" and target:GetName() ~= "npc_dota_hero_shadow_shaman") and target:IsHero() then
			target:SetMana(target:GetMana()/5)
			local mana_shock_damage = (target:GetMaxMana() - target:GetMana()) * 0.8
			DoDamage(caster, target, mana_shock_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end]]

		damage = damage + 0.2*(hTarget:GetMaxHealth()-hTarget:GetHealth()) --+
		-- stacks * (self:GetSpecialValueFor("damage_per_nss_stack") + self:GetSpecialValueFor("sa_bonus_damage_per_stack"))
		--stunDuration = self:GetSpecialValueFor("attribute_stun_duration")
		if not self.firsthit then
			hTarget:AddNewModifier(caster, self, "modifier_nss_shock", { Duration = self:GetSpecialValueFor("revoke_duration"),
																		ShockDamage = self:GetSpecialValueFor("shock_damage") + 
																		stacks * (self:GetSpecialValueFor("damage_per_nss_stack") + self:GetSpecialValueFor("sa_bonus_damage_per_stack"))})
			self.firsthit = true		
		else
			hTarget:AddNewModifier(caster, self, "modifier_nss_shock_no_revoke", { Duration = self:GetSpecialValueFor("revoke_duration"),
																		ShockDamage = self:GetSpecialValueFor("shock_damage") + 	stacks * (self:GetSpecialValueFor("damage_per_nss_stack") + self:GetSpecialValueFor("sa_bonus_damage_per_stack"))})
																	
		end
	else
		if not self.firsthit then
			hTarget:AddNewModifier(caster, self, "modifier_nss_shock", { Duration = self:GetSpecialValueFor("revoke_duration"),
																	  ShockDamage = self:GetSpecialValueFor("shock_damage") + 
																	stacks * self:GetSpecialValueFor("damage_per_nss_stack")})
			self.firsthit = true	
		end
	end
	hTarget:RemoveModifierByName("modifier_nss_shock_stackable")
	if caster:HasModifier("modifier_berserk") then
		DoDamage(caster, hTarget, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
	else
		DoDamage(caster, hTarget, damage, DAMAGE_TYPE_PURE, 0, self, false)
	end


	local groundFx1 = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_ABSORIGIN, hTarget )
    ParticleManager:SetParticleControl( groundFx1, 0, hTarget:GetAbsOrigin())
    ParticleManager:SetParticleControl( groundFx1, 1, hTarget:GetAbsOrigin())
    local groundFx2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_ABSORIGIN, hTarget )
    ParticleManager:SetParticleControl( groundFx2, 0, hTarget:GetAbsOrigin())
    ParticleManager:SetParticleControl( groundFx2, 1, hTarget:GetAbsOrigin())
    ParticleManager:SetParticleControlOrientation(groundFx1, 0, RandomVector(3), Vector(0,1,0), Vector(1,0,0))
    ParticleManager:SetParticleControlOrientation(groundFx2, 0, RandomVector(3), Vector(0,1,0), Vector(1,0,0))
    local firstStrikeFx = ParticleManager:CreateParticle("particles/custom/lishuwen/lishuwen_no_second_strike_hit.vpcf", PATTACH_ABSORIGIN, hTarget)
	ParticleManager:SetParticleControl( firstStrikeFx, 0, hTarget:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(groundFx1)
	ParticleManager:ReleaseParticleIndex(groundFx2)
	ParticleManager:ReleaseParticleIndex(firstStrikeFx)
	if not hTarget:IsAlive() then
		if caster.bIsCirculatoryShockAcquired then
			hTarget.MasterUnit:SetMana(hTarget.MasterUnit:GetMana() - 1) 
			hTarget.MasterUnit2:SetMana(hTarget.MasterUnit2:GetMana() - 1) 
		end
		local enemyfx1 = ParticleManager:CreateParticle( "particles/custom_game/heroes/kenshiro/kenshiro_ganzan_hit/kenshiro_ganzan_hit_j.vpcf", PATTACH_ABSORIGIN, hTarget )
		ParticleManager:SetParticleControl( enemyfx1, 0, hTarget:GetAbsOrigin())
		ParticleManager:SetParticleControl( enemyfx1, 1, hTarget:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(enemyfx1)
	end
	ApplyAirborne(caster, hTarget, self:GetSpecialValueFor("stun_duration"))


end

function lishuwen_no_second_strike:ApplyMarkOfFatality(caster, target)
	local abil = caster:FindAbilityByName("lishuwen_martial_arts")
	SpawnAttachedVisionDummy(caster, target, abil:GetLevelSpecialValueFor("vision_radius", abil:GetLevel()-1 ), abil:GetLevelSpecialValueFor("duration", abil:GetLevel()-1 ), false)

	local currentStack = target:GetModifierStackCount("modifier_mark_of_fatality", abil)
	target:RemoveModifierByName("modifier_mark_of_fatality") 
	abil:ApplyDataDrivenModifier(caster, target, "modifier_mark_of_fatality", {}) 
	target:SetModifierStackCount("modifier_mark_of_fatality", abil, currentStack + 1)
end

--[[local pushTarget = Physics:Unit(target)
		target:PreventDI()
		target:SetPhysicsFriction(0)
		local vectorC = (target:GetAbsOrigin() - caster:GetAbsOrigin()) + Vector(0, 0, self:GetSpecialValueFor("attribute_kb_distance")) --knockback in direction as fissure
		-- get the direction where target will be pushed back to
		target:SetPhysicsVelocity(vectorC:Normalized() * 1500)
		target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
		local initialUnitOrigin = target:GetAbsOrigin()
		
		target:OnPhysicsFrame(function(unit) -- pushback distance check
			local unitOrigin = unit:GetAbsOrigin()
			local diff = unitOrigin - initialUnitOrigin
			local n_diff = diff:Normalized()
			unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) -- track the movement of target being pushed back
			if diff:Length() > self:GetSpecialValueFor("attribute_kb_distance") then -- if pushback distance is over 400, stop it
				unit:PreventDI(false)
				unit:SetPhysicsVelocity(Vector(0,0,0))
				unit:OnPhysicsFrame(nil)
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
			end
		end)

		knockback_damage = (knockback_damage - target:GetHealth()) * self:GetSpecialValueFor("attribute_kb_damage")

		target:AddNewModifier(caster, target, "modifier_nss_knockback_stun", {Duration = stunDuration,
																			StunDuration = stunDuration,
																			RevokeDuration = self:GetSpecialValueFor("attribute_revoke_duration"),
																			Damage = knockback_damage,
																			AreaOfEffect = self:GetSpecialValueFor("attribute_kb_aoe"),
																			KnockbackDistance = self:GetSpecialValueFor("attribute_kb_distance")})

		target:AddNewModifier(target, nil, "modifier_knockback", modifierKnockback)
	else]]