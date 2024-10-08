-----------------------------
--    Wolf's Bane    --
-----------------------------


--------------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------------
robin_tools_wolfs_bane = class({})

LinkLuaModifier( "modifier_robin_tools_wolfs_bane", "abilities/robin/modifiers/modifier_robin_tools_wolfs_bane", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_poison_stack", "abilities/robin/modifiers/modifier_robin_poison_stack", LUA_MODIFIER_MOTION_NONE )

function robin_tools_wolfs_bane:GetManaCost(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_robin_tools_attribute") then
		return 300
	else
		return 400
	end
end

function robin_tools_wolfs_bane:GetCooldown(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_robin_tools_attribute") then
		return 25
	else
		return 30
	end
end


--------------------------------------------------------------------------------
-- Custom KV
function robin_tools_wolfs_bane:GetAOERadius()
	return self:GetSpecialValueFor( "midair_explosion_radius" )
end


--------------------------------------------------------------------------------
-- Ability Start
function robin_tools_wolfs_bane:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- load data
	local projectile_name = "particles/custom/robin/robin_wolfs_bane_projectile.vpcf"
	local projectile_speed = self:GetSpecialValueFor( "movement_speed" )
	local projectile_vision = self:GetSpecialValueFor( "vision_range" )

	-- create projectile
	local info = {
		Target = target,
		Source = caster,
		Ability = self,	
		
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		bDodgeable = false,                           -- Optional
	
		bVisibleToEnemies = true,                         -- Optional
		bProvidesVision = true,                           -- Optional
		iVisionRadius = projectile_vision,                              -- Optional
		iVisionTeamNumber = caster:GetTeamNumber(),        -- Optional
	}
	ProjectileManager:CreateTrackingProjectile(info)

	-- Play effects
	local sound_cast = "Hero_Alchemist.UnstableConcoction.Throw"
	EmitSoundOn( sound_cast, caster )
	
	if not caster:HasModifier("modifier_robin_tools_attribute") then
		local ability = caster:FindAbilityByName("robin_tools")
		ability:CloseSpellbook(self:GetCooldown(self:GetLevel()))	
		ability:StartCooldown( self:GetCooldown(self:GetLevel()))
	end
end

--------------------------------------------------------------------------------
-- Projectile
function robin_tools_wolfs_bane:OnProjectileHit_ExtraData( target, location, ExtraData )
	if not target then return end

	-- check if the ability GOT TRIGGERED BY SOMETHING TRIVIAL
	local TRIGGERED = target:TriggerSpellAbsorb( self )

	-- calm down if you GOT TRIGGERED
	if TRIGGERED then return end
	
	local caster = self:GetCaster()
	
	caster:EmitSound("robin_wolfs_bane")
	
	if caster:HasModifier("modifier_robin_may_king_invis") then
		caster:RemoveModifierByName("modifier_robin_may_king_invis")
	end

	-- load data
	local max_stun = self:GetSpecialValueFor( "max_stun" )
	local max_damage = self:GetSpecialValueFor( "max_damage" )
	local radius = self:GetSpecialValueFor( "midair_explosion_radius" )
	
	target:EmitSound("robin_yew_bow_poison")

	-- calculate stun and damage
	local stun = max_stun
	local damage = max_damage
	
	local blastFx = ParticleManager:CreateParticle("particles/custom/robin/robin_wolfs_bane_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( blastFx, 0, target:GetAbsOrigin())
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( blastFx, false )
		ParticleManager:ReleaseParticleIndex( blastFx )
	end)
			
	ScreenShake(target:GetOrigin(), 1, 1.0, 2, 1000, 0, true)

	-- precache damage
	local damageTable = {
		-- victim = target,
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = DAMAGE_TYPE_PHYSICAL,
		ability = self, --Optional.
	}
	-- ApplyDamage(damageTable)

	-- find units in radius
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),	-- int, your team number
		target:GetOrigin(),	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO,	-- int, type filter
		DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO,	-- int, flag filter
		0,	-- int, order filter
		false	-- bool, can grow cache
	)
	
	

	for _,enemy in pairs(enemies) do
		-- damage
		damageTable.victim = enemy
		ApplyDamage( damageTable )

		-- debuff
		enemy:AddNewModifier(
			self:GetCaster(), -- player source
			self, -- ability source
			"modifier_robin_tools_wolfs_bane", -- modifier name
			{ duration = stun } -- kv
		)
		
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
				poison_stack_ability:SetStackCount(poison_stack + 20)
				poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 50 then
					poison_stack_ability:SetStackCount(50)
				end
		elseif caster:HasModifier("modifier_robin_yew_bow_attribute") and poison_stack < 50 and enemy:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack + 10)
			poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 50 then
					poison_stack_ability:SetStackCount(50)
				end
		elseif caster:HasModifier("modifier_robin_yew_bow_attribute") and poison_stack >= 50 and enemy:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack)
		elseif caster:HasModifier("modifier_robin_of_sherwood_attribute") and poison_stack < 30 and enemy:HasModifier("modifier_robin_poison_stack")  then
			poison_stack_ability:SetStackCount(poison_stack + 20)
			poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 30 then
					poison_stack_ability:SetStackCount(30)
				end
		elseif poison_stack < 30 and enemy:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack + 10)
			poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 30 then
					poison_stack_ability:SetStackCount(30)
				end
		elseif  poison_stack >= 30 and enemy:HasModifier("modifier_robin_poison_stack")  then
			poison_stack_ability:SetStackCount(poison_stack)
		end
	end
end