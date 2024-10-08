-----------------------------
--    Modifier: Pitfall    --
-----------------------------

modifier_robin_tools_pitfall = class({})


LinkLuaModifier( "modifier_robin_tools_pitfall_debuff", "abilities/robin/modifiers/modifier_robin_tools_pitfall_debuff", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_poison_stack", "abilities/robin/modifiers/modifier_robin_poison_stack", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Classifications
function modifier_robin_tools_pitfall:IsHidden()
	return false
end

function modifier_robin_tools_pitfall:IsDebuff()
	return false
end

function modifier_robin_tools_pitfall:IsStunDebuff()
	return false
end

function modifier_robin_tools_pitfall:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_robin_tools_pitfall:OnCreated( kv )
	if not IsServer() then return end
	-- references
	self.radius = kv.radius
	self.root = kv.root
	self.damage = kv.damage
	local delay = kv.delay

	-- start delay
	self:StartIntervalThink( delay )

	-- play effects
	self:PlayEffects()
end

function modifier_robin_tools_pitfall:OnRefresh( kv )
	
end

function modifier_robin_tools_pitfall:OnRemoved()
end

function modifier_robin_tools_pitfall:OnDestroy()
	if not IsServer() then return end
	-- stop loop sound
	local sound_loop = "Hero_DarkWillow.BrambleLoop"
	StopSoundOn( sound_loop, self:GetParent() )

	-- play stopping sound
	local sound_stop = "Hero_DarkWillow.Bramble.Destroy"
	EmitSoundOn( sound_stop, self:GetParent() )

	UTIL_Remove( self:GetParent() )
end

--------------------------------------------------------------------------------
-- Interval Effects
function modifier_robin_tools_pitfall:OnIntervalThink()
	if not self.delay then
		self.delay = true

		-- start search interval
		local interval = 0.03
		self:StartIntervalThink( interval )
		return
	end

	-- find enemies
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		self:GetParent():GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		self.radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	local target = nil
	for _,enemy in pairs(enemies) do
		-- find the first occurence
		target = enemy
		break
	end
	if not target then return end
	
	local caster = self:GetCaster()
	
	local yew_bow_ability = caster:FindAbilityByName("robin_yew_bow")
	
	if not target:HasModifier("modifier_robin_poison_stack") then
		target:AddNewModifier(caster, yew_bow_ability, "modifier_robin_poison_stack", { Duration = 15 })
		local poison_stack_ability = target:FindModifierByNameAndCaster( "modifier_robin_poison_stack", caster )
		poison_stack_ability:SetStackCount(1)
	else
		target:AddNewModifier(caster, yew_bow_ability, "modifier_robin_poison_stack", { Duration = 15 })
	end
	
	local poison_stack_ability = target:FindModifierByNameAndCaster( "modifier_robin_poison_stack", caster )
	local poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)

	if caster:HasModifier("modifier_robin_yew_bow_attribute") and caster:HasModifier("modifier_robin_of_sherwood_attribute") and poison_stack < 50 and target:HasModifier("modifier_robin_poison_stack") then
		poison_stack_ability:SetStackCount(poison_stack + 4)
		poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
		if poison_stack >= 50 then
			poison_stack_ability:SetStackCount(50)
		end
	elseif caster:HasModifier("modifier_robin_yew_bow_attribute") and poison_stack < 50 and target:HasModifier("modifier_robin_poison_stack") then
		poison_stack_ability:SetStackCount(poison_stack + 2)
		poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
			if poison_stack >= 50 then
					poison_stack_ability:SetStackCount(50)
			end
	elseif caster:HasModifier("modifier_robin_yew_bow_attribute") and poison_stack >= 50 and target:HasModifier("modifier_robin_poison_stack") then
		poison_stack_ability:SetStackCount(poison_stack)
	elseif  caster:HasModifier("modifier_robin_of_sherwood_attribute") and poison_stack < 30 and target:HasModifier("modifier_robin_poison_stack")  then
		poison_stack_ability:SetStackCount(poison_stack + 4)
	elseif poison_stack < 30 and target:HasModifier("modifier_robin_poison_stack") then
		poison_stack_ability:SetStackCount(poison_stack + 2)
		poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
			if poison_stack >= 30 then
				poison_stack_ability:SetStackCount(30)
			end
	elseif  poison_stack >= 30 and target:HasModifier("modifier_robin_poison_stack")  then
		poison_stack_ability:SetStackCount(poison_stack)
	end
	
	-- root target
	target:AddNewModifier(
		self:GetCaster(), -- player source
		self:GetAbility(), -- ability source
		"modifier_robin_tools_pitfall_debuff", -- modifier name
		{
			duration = self.root,
			damage = self.damage,
		} -- kv
	)

	self:Destroy()
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_robin_tools_pitfall:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/custom/robin/robin_pitfall_wraith.vpcf"
	local sound_cast = "Hero_DarkWillow.Bramble.Spawn"
	local sound_loop = "Hero_DarkWillow.BrambleLoop"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetParent():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, self.radius, self.radius ) )

	-- buff particle
	self:AddParticle(
		effect_cast,
		false, -- bDestroyImmediately
		false, -- bStatusEffect
		-1, -- iPriority
		false, -- bHeroEffect
		false -- bOverheadEffect
	)

	-- Create Sound
	EmitSoundOn( sound_cast, self:GetParent() )
	EmitSoundOn( sound_loop, self:GetParent() )
end