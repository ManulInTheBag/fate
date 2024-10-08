-----------------------------
--    Yew Bow    --
-----------------------------

robin_yew_bow = class({})

LinkLuaModifier( "modifier_robin_yew_bow", "abilities/robin/modifiers/modifier_robin_yew_bow", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_poison_stack", "abilities/robin/modifiers/modifier_robin_poison_stack", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_yew_bow_silence", "abilities/robin/modifiers/modifier_robin_yew_bow_silence", LUA_MODIFIER_MOTION_NONE )

-- Ability Phase Start
function robin_yew_bow:OnAbilityPhaseInterrupted()
	StopGlobalSound("robin_yew_bow")
	if self.modifier then
		local modifier = self:RetATValue( self.modifier )
		if not modifier:IsNull() then
			modifier:Destroy()
			StopGlobalSound("robin_yew_bow")
		end
		self.modifier = nil
	end
end

function robin_yew_bow:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local debuff_duration = 4

	local modifier = target:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_robin_yew_bow", -- modifier name
		{ duration = debuff_duration } -- kv
	)

	self.modifier = self:AddATValue( modifier )

	EmitGlobalSound("robin_yew_bow")

	return true -- if success
end

--------------------------------------------------------------------------------
-- Ability Start
function robin_yew_bow:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- local point = self:GetCursorPosition()
	
	if caster:HasModifier("modifier_robin_may_king_invis") then
		caster:RemoveModifierByName("modifier_robin_may_king_invis")
	end
	
	local enemy = PickRandomEnemy(caster)
	
    if enemy then
        caster:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = 0.5 })
    end

	-- load data
	local projectile_name = "particles/custom/robin/robin_yew_bow.vpcf"
	local projectile_speed = self:GetSpecialValueFor("projectile_speed")
	
	EmitGlobalSound("robin_yew_bow_launch")
	
	if not target:HasModifier("modifier_robin_poison_stack") then
		target:AddNewModifier(caster, self, "modifier_robin_poison_stack", { Duration = 15 })
		local poison_stack_ability = target:FindModifierByNameAndCaster( "modifier_robin_poison_stack", caster )
		poison_stack_ability:SetStackCount(1)
	else
		target:AddNewModifier(caster, self, "modifier_robin_poison_stack", { Duration = 15 })
	end

	local info = {
		Target = target,
		Source = caster,
		Ability = self,	
		
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_3,
		bDodgeable = true,                           -- Optional
		ExtraData = { modifier = self.modifier }
	}
	ProjectileManager:CreateTrackingProjectile(info)
	self.modifier = nil

	local sound_target = "Hero_Sniper.AssassinateProjectile"
	EmitSoundOn( sound_cast, target )
end
--------------------------------------------------------------------------------
-- Projectile
function robin_yew_bow:OnProjectileHit_ExtraData( target, location, extradata )
	-- cancel if gone
	if (not target) or target:IsInvulnerable() or target:IsOutOfGame() or target:TriggerSpellAbsorb( self ) then
		return
	end
	
	local caster = self:GetCaster()
	
	local poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
	
	target:EmitSound("robin_yew_bow_impact")

	-- apply damage
	local damage = self:GetSpecialValueFor("damage")
	local damage_stack = self:GetSpecialValueFor("damage_stack")
	local silence_duration = self:GetSpecialValueFor("silence_duration")
	local poison_detonation_radius = self:GetSpecialValueFor("poison_detonation_radius")
	
		if not target:HasModifier("modifier_robin_poison_stack") then
			target:AddNewModifier(caster, self, "modifier_robin_poison_stack", { Duration = 15 })
			local poison_stack_ability = target:FindModifierByNameAndCaster( "modifier_robin_poison_stack", caster )
			poison_stack_ability:SetStackCount(1)
		else
			target:AddNewModifier(caster, self, "modifier_robin_poison_stack", { Duration = 15 })
		end
	
		local poison_stack_ability = target:FindModifierByNameAndCaster( "modifier_robin_poison_stack", caster )
		local poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
	
		if caster:HasModifier("modifier_robin_yew_bow_attribute") and caster:HasModifier("modifier_robin_of_sherwood_attribute") and poison_stack < 50 and target:HasModifier("modifier_robin_poison_stack") then
				poison_stack_ability:SetStackCount(poison_stack + 20)
				poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 50 then
					poison_stack_ability:SetStackCount(50)
				end
		elseif caster:HasModifier("modifier_robin_yew_bow_attribute") and poison_stack < 50 and target:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack + 10)
			poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 50 then
					poison_stack_ability:SetStackCount(50)
				end
		elseif caster:HasModifier("modifier_robin_yew_bow_attribute") and poison_stack >= 50 and target:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack)
		elseif caster:HasModifier("modifier_robin_of_sherwood_attribute") and poison_stack < 30 and target:HasModifier("modifier_robin_poison_stack")  then
			poison_stack_ability:SetStackCount(poison_stack + 20)
			poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 30 then
					poison_stack_ability:SetStackCount(30)
				end
		elseif poison_stack < 30 and target:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack + 10)
			poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 30 then
					poison_stack_ability:SetStackCount(30)
				end
		elseif  poison_stack >= 30 and target:HasModifier("modifier_robin_poison_stack")  then
			poison_stack_ability:SetStackCount(poison_stack)
		end
		
	
	if caster:HasModifier("modifier_robin_of_sherwood_attribute") then
		target:AddNewModifier(
			self:GetCaster(), -- player source
			self, -- ability source
			"modifier_robin_yew_bow_silence", -- modifier name
			{ duration = silence_duration } -- kv
		)
		if target:GetMaxMana() > 0 then
			target:Script_ReduceMana(600, nil)
		end
	end
	
	local poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
	
	local real_damage = damage + (damage_stack * poison_stack)
	
	if caster:HasModifier("modifier_robin_yew_bow_attribute") then
		real_damage = real_damage + 250 + (caster:GetIntellect(true)*2.5)
	end
	
	local damageTable = {
		victim = target,
		attacker = self:GetCaster(),
		damage = real_damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self, --Optional.
	}
	ApplyDamage(damageTable)

	-- stun
	target:Interrupt()
	local modifier = self:RetATValue( extradata.modifier )
	if not modifier:IsNull() then
		modifier:Destroy()
	end
	
	if target:HasModifier("modifier_robin_poison_stack") then
		target:RemoveModifierByName("modifier_robin_poison_stack")
		self:PlayEffects( target )
	end
	
	local poison_targets = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, poison_detonation_radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	
		for k,poison_detonation_target in pairs(poison_targets) do
			if poison_detonation_target:IsMagicImmune() then
				return
			end
			
			if poison_detonation_target:HasModifier("modifier_robin_poison_stack") then
			
				local detonation_poison_stack = poison_detonation_target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				local detonation_damage = detonation_poison_stack  * damage_stack
				
				DoDamage(caster, poison_detonation_target, detonation_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				
				poison_detonation_target:RemoveModifierByName("modifier_robin_poison_stack")
				self:PlayEffects( poison_detonation_target )
			end
		end

	-- effects
	local sound_cast = "Hero_Sniper.AssassinateDamage"
	EmitSoundOn( sound_cast, target )
end

------------------------------------------------------------------------------
function robin_yew_bow:PlayEffects( target )
	-- Get Resources
	local particle_cast = "particles/custom/robin/robin_yew_bow_impact.vpcf"
	
	target:EmitSound("robin_yew_bow_poison")

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		target,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(0,0,0), -- unknown
		true -- unknown, true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )
end

--------------------------------------------------------------------------------
-- Helper: Ability Table (AT)
function robin_yew_bow:GetAT()
	if self.abilityTable==nil then
		self.abilityTable = {}
	end
	return self.abilityTable
end

function robin_yew_bow:GetATEmptyKey()
	local table = self:GetAT()
	local i = 1
	while table[i]~=nil do
		i = i+1
	end
	return i
end

function robin_yew_bow:AddATValue( value )
	local table = self:GetAT()
	local i = self:GetATEmptyKey()
	table[i] = value
	return i
end

function robin_yew_bow:RetATValue( key )
	local table = self:GetAT()
	local ret = table[key]
	table[key] = nil
	return ret
end