-----------------------------
--    It's a Trap    --
-----------------------------

robin_tools_its_a_trap = class({})

LinkLuaModifier( "modifier_robin_tools_its_a_trap", "abilities/robin/modifiers/modifier_robin_tools_its_a_trap", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_robin_poison_stack", "abilities/robin/modifiers/modifier_robin_poison_stack", LUA_MODIFIER_MOTION_NONE )

function robin_tools_its_a_trap:GetManaCost(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_robin_tools_attribute") then
		return 100
	else
		return 200
	end
end

function robin_tools_its_a_trap:GetCooldown(iLevel)
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_robin_tools_attribute") then
		return 10
	else
		return 15
	end
end

--------------------------------------------------------------------------------
-- Ability Start
function robin_tools_its_a_trap:OnSpellStart()
	local net_range = self:GetSpecialValueFor( "net_range" )
	
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	if caster:HasModifier("modifier_robin_may_king_invis") then
		caster:RemoveModifierByName("modifier_robin_may_king_invis")
	end

	-- load data
	local projectile_speed = self:GetSpecialValueFor( "net_speed" )
	
	StartAnimation(caster, {duration=1.00, activity=ACT_DOTA_CAST_ABILITY_5, rate=1.0})

	-- create projectile
	local projectile_name = "particles/custom/robin/robin_trap_projectile.vpcf"
	local info = {
		Target = target,
		Source = caster,
		Ability = self,	
		
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		bDodgeable = true,                           -- Optional
		ExtraData = {
			fake = 0,
		}
	}
	ProjectileManager:CreateTrackingProjectile(info)

	-- play effects
	local sound_cast = "Hero_NagaSiren.Ensnare.Cast"
	EmitSoundOn( sound_cast, caster )
end

--------------------------------------------------------------------------------
-- Projectile
function robin_tools_its_a_trap:OnProjectileHit_ExtraData( target, location, data )
	if not target then return end
	if data.fake==1 then return end

	if target:IsMagicImmune() then return end

	-- cancel if linken
	if target:TriggerSpellAbsorb( self ) then return end
	
	local caster = self:GetCaster()

	-- load data
	local duration = self:GetSpecialValueFor( "duration" )
	
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
			poison_stack_ability:SetStackCount(poison_stack + 8)
			poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 50 then
					poison_stack_ability:SetStackCount(50)
				end
		elseif caster:HasModifier("modifier_robin_yew_bow_attribute") and poison_stack < 50 and target:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack + 4)
			poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 50 then
					poison_stack_ability:SetStackCount(50)
				end
		elseif caster:HasModifier("modifier_robin_yew_bow_attribute") and poison_stack >= 50 and target:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack)
		elseif caster:HasModifier("modifier_robin_of_sherwood_attribute") and  poison_stack < 30 and target:HasModifier("modifier_robin_poison_stack")  then
			poison_stack_ability:SetStackCount(poison_stack + 8)
			poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 30 then
					poison_stack_ability:SetStackCount(30)
				end
		elseif poison_stack < 30 and target:HasModifier("modifier_robin_poison_stack") then
			poison_stack_ability:SetStackCount(poison_stack + 4)
			poison_stack = target:GetModifierStackCount("modifier_robin_poison_stack", caster)
				if poison_stack >= 30 then
					poison_stack_ability:SetStackCount(30)
				end
		elseif  poison_stack >= 30 and target:HasModifier("modifier_robin_poison_stack")  then
			poison_stack_ability:SetStackCount(poison_stack)
		end

	-- ensnare
	target:AddNewModifier(
		self:GetCaster(), -- player source
		self, -- ability source
		"modifier_robin_tools_its_a_trap", -- modifier name
		{ duration = duration } -- kv
	)

	-- play effects
	local sound_cast = "Hero_NagaSiren.Ensnare.Target"
	EmitSoundOn( sound_cast, target )
	
	if not caster:HasModifier("modifier_robin_tools_attribute") then
		local ability = caster:FindAbilityByName("robin_tools")
		ability:CloseSpellbook(self:GetCooldown(self:GetLevel()))		
		ability:StartCooldown( self:GetCooldown(self:GetLevel()))
	end
end