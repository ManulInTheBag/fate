-----------------------------
--    Multishot    --
-----------------------------

robin_multishot = class({})

LinkLuaModifier( "modifier_robin_multishot", "abilities/robin/modifiers/modifier_robin_multishot", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_poison_stack", "abilities/robin/modifiers/modifier_robin_poison_stack", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)

function robin_multishot:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_robin_independent_action_attribute") then
		cooldown = cooldown - 2
	end

	return cooldown
end

--------------------------------------------------------------------------------
-- Ability Start
robin_multishot.targets = {}
function robin_multishot:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	
	local enemy = PickRandomEnemy(caster)
	
    if enemy then
        caster:AddNewModifier(enemy, nil, "modifier_vision_provider", { Duration = 0.7 })
    end

	-- load data
	local duration = self:GetChannelTime()

	self.targets = {}

	-- add modifier
	self.modifier = caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_robin_multishot", -- modifier name
		{
			duration = duration,
			x = point.x,
			y = point.y,
			z = point.z,
		} -- kv
	)
	
	if caster:HasModifier("modifier_robin_may_king_invis") then
		caster:RemoveModifierByName("modifier_robin_may_king_invis")
	end

end
--------------------------------------------------------------------------------
-- Projectile
function robin_multishot:OnProjectileHit_ExtraData( target, location, data )
	if not target then return end

	self.targets[ target ] = data.wave
	
	local caster = self:GetCaster()

	-- get value
	local damage = self:GetSpecialValueFor( "arrow_damage" )
	local damage_pct = self:GetSpecialValueFor( "arrow_damage_pct" )

	-- check frost arrow ability
	local ability = self:GetCaster():FindAbilityByName( "robin_yew_bow" )

	-- damage
	local damageTable = {
		victim = target,
		attacker = self:GetCaster(),
		damage = damage + (self:GetCaster():GetIntellect(true) * damage_pct/100),
		damage_type = DAMAGE_TYPE_PHYSICAL,
		ability = self, --Optional.
		-- damage_flags = DOTA_DAMAGE_FLAG_NONE, --Optional.
	}
	ApplyDamage(damageTable)
	
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
		elseif caster:HasModifier("modifier_robin_of_sherwood_attribute") and poison_stack < 30 and target:HasModifier("modifier_robin_poison_stack")  then
			poison_stack_ability:SetStackCount(poison_stack + 4)
			poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 30 then
					poison_stack_ability:SetStackCount(30)
				end
		elseif poison_stack < 30 and target:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack + 2)
			poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 30 then
					poison_stack_ability:SetStackCount(30)
				end
		elseif  poison_stack >= 30 and target:HasModifier("modifier_robin_poison_stack")  then
			poison_stack_ability:SetStackCount(poison_stack)
		end

	-- play effects
	local sound_cast = "Hero_DrowRanger.ProjectileImpact"
	EmitSoundOn( sound_cast, target )

	return true
end

--------------------------------------------------------------------------------
-- Ability Channeling
function robin_multishot:OnChannelFinish( bInterrupted )
	-- destroy modifier
	if not self.modifier:IsNull() then self.modifier:Destroy() end
end