-----------------------------
--    Mysterious Substance    --
-----------------------------

robin_tools_mysterious_substance = class({})

LinkLuaModifier( "modifier_robin_tools_mysterious_substance_debuff", "abilities/robin/modifiers/modifier_robin_tools_mysterious_substance_debuff", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_poison_stack", "abilities/robin/modifiers/modifier_robin_poison_stack", LUA_MODIFIER_MOTION_NONE )

function robin_tools_mysterious_substance:GetManaCost(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_robin_tools_attribute") then
		return 100
	else
		return 200
	end
end

function robin_tools_mysterious_substance:GetCooldown(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_robin_tools_attribute") then
		return 10
	else
		return 15
	end
end

--------------------------------------------------------------------------------
-- Ability Start
function robin_tools_mysterious_substance:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()

	-- load data
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("mute_duration")
	local damage = self:GetSpecialValueFor("damage")
	
	local targetPoint = self:GetCursorPosition()
	
	if caster:HasModifier("modifier_robin_may_king_invis") then
		caster:RemoveModifierByName("modifier_robin_may_king_invis")
	end
	
	caster:EmitSound("robin_smoke")

	-- logic
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),	-- int, your team number
		targetPoint,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		0,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)

	-- precache damage
	local damageTable = {
		-- victim = target,
		attacker = caster,
		damage = damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self, --Optional.
		damage_flags = DOTA_DAMAGE_FLAG_NONE, --Optional.
	}
	for _,enemy in pairs(enemies) do
		-- damage
		damageTable.victim = enemy
		ApplyDamage(damageTable)
		
		local yew_bow_ability = caster:FindAbilityByName("robin_yew_bow")
	
		if not enemy:HasModifier("modifier_robin_poison_stack") then
			enemy:AddNewModifier(caster, yew_bow_ability, "modifier_robin_poison_stack", { Duration = 15 })
			local poison_stack_ability = enemy:FindModifierByNameAndCaster( "modifier_robin_poison_stack", caster )
			poison_stack_ability:SetStackCount(1)
		else
			enemy:AddNewModifier(caster, yew_bow_ability, "modifier_robin_poison_stack", { Duration = 15 })
		end
	
		local poison_stack_ability = enemy:FindModifierByNameAndCaster( "modifier_robin_poison_stack", caster )
		local poison_stack = enemy:GetModifierStackCount("modifier_robin_poison_stack", caster)
	
		if caster:HasModifier("modifier_robin_yew_bow_attribute") and caster:HasModifier("modifier_robin_of_sherwood_attribute") and poison_stack < 50 and enemy:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack + 8)
			poison_stack = enemy:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 50 then
					poison_stack_ability:SetStackCount(50)
				end
		elseif caster:HasModifier("modifier_robin_yew_bow_attribute") and poison_stack < 50 and enemy:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack + 4)
			poison_stack = enemy:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 50 then
					poison_stack_ability:SetStackCount(50)
				end
		elseif caster:HasModifier("modifier_robin_yew_bow_attribute") and poison_stack >= 50 and enemy:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack)
		elseif  caster:HasModifier("modifier_robin_of_sherwood_attribute") and poison_stack < 30 and enemy:HasModifier("modifier_robin_poison_stack")  then
			poison_stack_ability:SetStackCount(poison_stack + 8)
			poison_stack = enemy:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 30 then
					poison_stack_ability:SetStackCount(30)
				end
		elseif poison_stack < 30 and enemy:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack + 4)
			poison_stack = enemy:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 30 then
					poison_stack_ability:SetStackCount(30)
				end
		elseif  poison_stack >= 30 and enemy:HasModifier("modifier_robin_poison_stack")  then
			poison_stack_ability:SetStackCount(poison_stack)
		end

		-- silence
		enemy:AddNewModifier(
			caster, -- player source
			self, -- ability source
			"modifier_robin_tools_mysterious_substance_debuff", -- modifier name
			{ duration = duration } -- kv
		)
	end

	self:PlayEffects( radius, targetPoint )
	
	if not caster:HasModifier("modifier_robin_tools_attribute") then
		local ability = caster:FindAbilityByName("robin_tools")
		ability:CloseSpellbook(self:GetCooldown(self:GetLevel()))	
		ability:StartCooldown( self:GetCooldown(self:GetLevel()))
	end
end

function robin_tools_mysterious_substance:PlayEffects( radius, targetPoint )
	local particle_cast = "particles/custom/robin/robin_dust.vpcf"
	local sound_cast = "Hero_Puck.Waning_Rift"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, targetPoint )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end