lishuwen_tiger_strike = class({})

LinkLuaModifier("modifier_tiger_strike_tracker", "abilities/lishuwen/modifiers/modifier_tiger_strike_tracker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tiger_strike_marker", "abilities/lishuwen/modifiers/modifier_tiger_strike_marker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tiger_strike_slow", "abilities/lishuwen/modifiers/modifier_tiger_strike_slow", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furious_chain_regen", "abilities/lishuwen/modifiers/modifier_furious_chain_regen", LUA_MODIFIER_MOTION_NONE)

function lishuwen_tiger_strike:GetCastPoint()
	if self:CheckSequence() == 2 then
		return 0.35
	elseif self:CheckSequence() == 1 then
		return 0.30
	else
		return 0.25
	end
end

function lishuwen_tiger_strike:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function lishuwen_tiger_strike:GetCustomCastError()
    return "#Invalid_Target"
end

function lishuwen_tiger_strike:CheckSequence()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_tiger_strike_tracker") then
		local stack = caster:GetModifierStackCount("modifier_tiger_strike_tracker", caster)

		return stack
	else
		return 0
	end	
end

function lishuwen_tiger_strike:GetCastAnimation()
	if self:CheckSequence() == 2 then
		return ACT_DOTA_CAST_ABILITY_3
	elseif self:CheckSequence() == 1 then
		return ACT_DOTA_CAST_ABILITY_2
	else
		return ACT_DOTA_ATTACK
	end
end

function lishuwen_tiger_strike:GetCastRange(vLocation, hTarget)
	if self:CheckSequence() == 3 then
		return 1500
	elseif self:CheckSequence() == 2 then
		return self:GetSpecialValueFor("strike_2_range")
	else
		return self:GetSpecialValueFor("strike_1_range")
	end
end

function lishuwen_tiger_strike:GetAbilityTextureName()
	if self:CheckSequence() == 3 then
		return "custom/lishuwen_fierce_tiger_strike_3"
	elseif self:CheckSequence() == 2 then
		return "custom/lishuwen_fierce_tiger_strike_2"
	else
		return "custom/lishuwen_fierce_tiger_strike"
	end
end

function lishuwen_tiger_strike:SequenceSkill()
	local caster = self:GetCaster()	
	local ability = self
	local modifier = caster:FindModifierByName("modifier_tiger_strike_tracker")

	if not modifier then
		caster:AddNewModifier(caster, ability, "modifier_tiger_strike_tracker", {Duration = self:GetSpecialValueFor("window_duration")})
		caster:SetModifierStackCount("modifier_tiger_strike_tracker", ability, 2)
	else
		caster:SetModifierStackCount("modifier_tiger_strike_tracker", ability, modifier:GetStackCount() + 1)
	end
end

function lishuwen_tiger_strike:GrantFuriousChainBuff()
	local caster = self:GetCaster()
	local modifier = caster:FindModifierByName("modifier_furious_chain_regen")

	if not modifier then
		caster:AddNewModifier(caster, self, "modifier_furious_chain_regen", {Duration = self:GetSpecialValueFor("regen_duration"),
																			 RegenAmount = self:GetSpecialValueFor("regen_amount")})
		caster:SetModifierStackCount("modifier_furious_chain_regen", self, 1)
	else
		caster:AddNewModifier(caster, self, "modifier_furious_chain_regen", {Duration = self:GetSpecialValueFor("regen_duration"),
																			 RegenAmount = self:GetSpecialValueFor("regen_amount")})
		caster:SetModifierStackCount("modifier_furious_chain_regen", self, modifier:GetStackCount() + 1)
	end
end

function lishuwen_tiger_strike:OnSpellStart()
	local caster = self:GetCaster()

	ProjectileManager:ProjectileDodge(caster)

	if self:CheckSequence() == 3 then
		self:TigerStrike3()
	elseif self:CheckSequence() == 2 then
		self:TigerStrike2()
	else
		self:TigerStrike1()
	end
end

function lishuwen_tiger_strike:TigerStrike1()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local ability = self
	local DamageType = DAMAGE_TYPE_MAGICAL
	local damage = self:GetSpecialValueFor("damage_1")
	EmitZlodemonTrueSoundEveryone("moskes_li_e1")
	local trailFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_trail.vpcf", PATTACH_CUSTOMORIGIN, target )
	ParticleManager:SetParticleControl( trailFx, 1, caster:GetAbsOrigin() )
	
	-- Sequenced such that spell blocks only prevents the remainder of the effects
	-- Li Shuwen should move to the target regardless
	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	caster:SetAbsOrigin(target:GetAbsOrigin() - diff*100)
	FindClearSpaceForUnit( caster, caster:GetAbsOrigin(), true )
	ParticleManager:SetParticleControl( trailFx, 0, target:GetAbsOrigin() )

	self:SequenceSkill()
	self:EndCooldown()
	self:StartCooldown(0.1)

	-- Don't do anything if the spell is blocked
	if IsSpellBlocked(target) then return end

	-- Damage type to physical and calculate for crit 
	if caster:HasModifier("modifier_berserk") then 
		--DamageType = DAMAGE_TYPE_PHYSICAL
		--if self:CalculateCrit() then 
			--print("crit")			
			caster:EmitSound("Hero_Juggernaut.BladeDance")
			damage = damage + caster:GetAverageTrueAttackDamage(caster)
			--damage = damage * self:GetSpecialValueFor("crit_multiplier") / 100 

			self:CreateCritFx(target)
		--end
	else
		damage = damage + (caster:GetAverageTrueAttackDamage(caster) * self:GetSpecialValueFor("damage_2_physical") / 100)
	end

	-- Grant Furious Chain related effects, and perform a fake attack to apply on hit effects
	if caster.bIsFuriousChainAcquired then 
		self:GrantFuriousChainBuff()
		target:AddNewModifier(caster, self, "modifier_tiger_strike_marker", {Duration = self:GetSpecialValueFor("window_duration")})
		--[[if target:HasModifier("modifier_tiger_strike_marker") then
			print("should have the buff")
		end]]
	end

	local health_1 = target:GetHealth()

	if caster.bIsMartialArtsImproved then
		caster:PerformAttack( target, true, true, true, true, false, true, true )
	end
	DoDamage(caster, target, damage, DamageType, 0, self, false)

	self.health_lost = health_1 - target:GetHealth()

	if not IsImmuneToSlow(target) then 
		target:AddNewModifier(caster, self, "modifier_tiger_strike_slow", {Duration = self:GetSpecialValueFor("slow_duration"),
																		   SlowPct = self:GetSpecialValueFor("slow_amount")})
	end	
	
	target:EmitSound("Hero_EarthShaker.Attack")
	self:PlayRandomSounds()
    local groundFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_f_fallback_low.vpcf", PATTACH_ABSORIGIN, target )
    ParticleManager:SetParticleControl( groundFx, 1, target:GetAbsOrigin())
    local firstStrikeFx = ParticleManager:CreateParticle("particles/custom/lishuwen/lishuwen_first_hit.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl( firstStrikeFx, 0, target:GetAbsOrigin())
end


function lishuwen_tiger_strike:TigerStrike2()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local ability = self
	local damage = self:GetSpecialValueFor("damage_2")
	EmitZlodemonTrueSoundEveryone("moskes_li_e2")
	caster:SetAbsOrigin(target:GetAbsOrigin()-(caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()*130)
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	--caster:SetForwardVector(target:GetAbsOrigin())

	self:SequenceSkill()
	self:EndCooldown()
	self:StartCooldown(0.1)

	if IsSpellBlocked(target) then return end
	
	if caster.bIsFuriousChainAcquired then 
		self:GrantFuriousChainBuff()
		
		if target:HasModifier("modifier_tiger_strike_marker") then 
			--print("chaining")
			damage = damage * self:GetSpecialValueFor("chain_bonus_multiplier") 
		else 
			--print("breaking")
			damage = damage * self:GetSpecialValueFor("chain_switch_penalty")
		end
	end

	if caster.bIsMartialArtsImproved then
		caster:PerformAttack( target, true, true, true, true, false, true, true )
	end

	if caster:HasModifier("modifier_berserk") then --and self:CalculateCrit() 
		--print("crit")
		caster:EmitSound("Hero_Juggernaut.BladeDance")
		damage = damage + caster:GetAverageTrueAttackDamage(caster)

		self:CreateCritFx(target)
	else
		damage = damage + (caster:GetAverageTrueAttackDamage(caster) * self:GetSpecialValueFor("damage_2_physical") / 100)
	end

	local health_2 = target:GetHealth()

	DoDamage(caster, target, damage , DAMAGE_TYPE_PHYSICAL, 0, self, false)
	target:AddNewModifier(caster, target, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration")})

	local casterfacing = caster:GetForwardVector()
	local pushTarget = Physics:Unit(target)
	local casterOrigin = caster:GetAbsOrigin()
	local initialUnitOrigin = target:GetAbsOrigin()
	target:PreventDI()
	target:SetPhysicsFriction(0)
	target:SetPhysicsVelocity(casterfacing:Normalized() * 2500)
	target:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
    target:OnPhysicsFrame(function(unit) 
		local unitOrigin = unit:GetAbsOrigin()
		local diff = unitOrigin - initialUnitOrigin
		local n_diff = diff:Normalized()
		unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * n_diff) 
		if diff:Length() > (500 + caster:GetStrength() * 4 ) then
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
		giveUnitDataDrivenModifier(caster, target, "stunned",1)
		target:EmitSound("Hero_EarthShaker.Fissure")
		DoDamage(caster, target, 200 + caster:GetStrength() * 3, DAMAGE_TYPE_PHYSICAL, 0, ability, false)	
	end)

	self.health_lost = self.health_lost + health_2 - target:GetHealth()

	

	target:EmitSound("Hero_EarthShaker.Fissure")
	self:PlayRandomSounds()
	local groundFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_ABSORIGIN, target )
	ParticleManager:SetParticleControl( groundFx, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl( groundFx, 1, target:GetAbsOrigin())
	local firstStrikeFx = ParticleManager:CreateParticle("particles/custom/lishuwen/lishuwen_second_hit.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl( firstStrikeFx, 0, target:GetAbsOrigin())
end

function lishuwen_tiger_strike:TigerStrike3()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local ability = self
	EmitZlodemonTrueSoundEveryone("moskes_li_e3")
	if IsSpellBlocked(target) then return end

	print(self.health_lost)

	local damage = self:GetSpecialValueFor("damage_3_magical") + self.health_lost*self:GetSpecialValueFor("losthealth_multiplier")

	caster:RemoveModifierByName("modifier_tiger_strike_tracker")
	
	self:EndCooldown()

	if caster.bIsFuriousChainAcquired then
		self:GrantFuriousChainBuff()
		self:StartCooldown(self:GetSpecialValueFor("furious_chain_cooldown"))
		if target:HasModifier("modifier_tiger_strike_marker") then 
			--print("chaining")
			damage = damage * self:GetSpecialValueFor("chain_bonus_multiplier") 
		else 
			--print("breaking")
			damage = damage * self:GetSpecialValueFor("chain_switch_penalty")
		end
	else
		self:StartCooldown(self:GetSpecialValueFor("reduced_cooldown"))
	end

	if target:IsAlive() then 
		caster:SetAbsOrigin(target:GetAbsOrigin()+(caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()*130)
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	else
		caster:SetMana(caster:GetMana()+300)
	end

	if caster.bIsMartialArtsImproved then
		caster:PerformAttack( target, true, true, true, true, false, true, true )
	end

	target:RemoveModifierByName("modifier_tiger_strike_marker")

	if caster:HasModifier("modifier_berserk") then
		--if self:CalculateCrit() then 
			--print("crit")
			caster:EmitSound("Hero_Juggernaut.BladeDance")
			damage = damage + caster:GetAverageTrueAttackDamage(caster)
			--damage = damage * self:GetSpecialValueFor("crit_multiplier") / 100 

			self:CreateCritFx(target)
		--end
		--DoDamage(caster, target, damage/2, DAMAGE_TYPE_PHYSICAL, 0, self, false)
		--DoDamage(caster, target, damage/2, DAMAGE_TYPE_MAGICAL, 0, self, false)
		DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, 0, self, false)
	else
		damage = damage + (caster:GetAverageTrueAttackDamage(caster) * self:GetSpecialValueFor("damage_2_physical") / 100)
		DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, 0, self, false)
	end
	
	target:EmitSound("Hero_EarthShaker.Totem")
	self:PlayRandomSounds()
	local groundFx1 = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_ABSORIGIN, target )
	ParticleManager:SetParticleControl( groundFx1, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl( groundFx1, 1, target:GetAbsOrigin())
	local groundFx2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_ABSORIGIN, target )
	ParticleManager:SetParticleControl( groundFx2, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl( groundFx2, 1, target:GetAbsOrigin())
	ParticleManager:SetParticleControlOrientation(groundFx1, 0, RandomVector(3), Vector(0,1,0), Vector(1,0,0))
	ParticleManager:SetParticleControlOrientation(groundFx2, 0, RandomVector(3), Vector(0,1,0), Vector(1,0,0))
	local firstStrikeFx = ParticleManager:CreateParticle("particles/custom/lishuwen/lishuwen_third_hit.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl( firstStrikeFx, 0, target:GetAbsOrigin())
end

function lishuwen_tiger_strike:CalculateCrit()
	local caster = self:GetCaster()
	local crit_rate = (caster:GetStrength() * self:GetSpecialValueFor("strength_ratio")) + self:GetSpecialValueFor("critical_chance")

	return (crit_rate - RandomInt(0, 100) ) > 0
end

function lishuwen_tiger_strike:CreateCritFx(target)
	local crit_fx = ParticleManager:CreateParticle( "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_ABSORIGIN, target )
    --ParticleManager:SetParticleControl( crit_fx, 0, target:GetAbsOrigin() - self:GetCaster():GetAbsOrigin())
    ParticleManager:SetParticleControl( crit_fx, 1, target:GetAbsOrigin())

    Timers:CreateTimer(0.2, function()
		ParticleManager:DestroyParticle( crit_fx, false )
		ParticleManager:ReleaseParticleIndex( crit_fx )
		return nil
	end)
end

function lishuwen_tiger_strike:PlayRandomSounds()
	local caster = self:GetCaster()
	local soundQueue = math.random(1,4)

	caster:EmitSound("Lishuwen_Attack" .. soundQueue)
end