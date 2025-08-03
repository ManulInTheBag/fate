scathach_gait_two = class({})
LinkLuaModifier( "modifier_scathach_gait_two", "abilities/scathach/modifiers/modifier_scathach_gait_two", LUA_MODIFIER_MOTION_NONE )

LinkLuaModifier( "modifier_scathach_gait_three_window", "abilities/scathach/modifiers/modifier_scathach_gait_three_window", LUA_MODIFIER_MOTION_BOTH )
LinkLuaModifier("modifier_stachach_gae_bolg_curse", "abilities/scathach/scathach_gae_bolg.lua", LUA_MODIFIER_MOTION_NONE)
--------------------------------------------------------------------------------
-- Ability Start
function scathach_gait_two:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	
	local origin = caster:GetAbsOrigin()

	-- load data
	local duration = self:GetSpecialValueFor("duration")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local armor_reduction_duration = self:GetSpecialValueFor("armor_reduction_duration")
	local damage = self:GetSpecialValueFor("damage")
	local damage_big = self:GetSpecialValueFor("damage_big")
	local radius = self:GetSpecialValueFor("radius")
	
	if caster:HasModifier("modifier_scathach_primeval_rune_attribute") then
		damage = damage + 125
		damage_big = damage_big + 125
	end
	
	StartAnimation(caster, {duration = 2.5, activity=ACT_DOTA_CAST_ABILITY_3, rate = 1.0})
	
	caster:EmitSound("scathach_gait_2")

	-- Add modifier
	caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_scathach_gait_two", -- modifier name
		{ duration = duration } -- kv
	)
	
	Timers:CreateTimer(0.40, function()
		if caster:IsAlive() then
			self:PlayEffects1( caught, origin:Normalized() )
			caster:EmitSound("scathach_gait_attack_1")
			
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		
			for k,spin_target_1 in pairs(targets) do
			
				DoDamage(caster, spin_target_1, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				spin_target_1:AddNewModifier(caster, self, "modifier_stachach_gae_bolg_curse", {duration = 10})
				--spin_target_1:AddNewModifier(caster, self, "modifier_scathach_gait_two_armor_reduction_1", { Duration = armor_reduction_duration })
				
				-- if spin_target_1:GetMaxMana() > 0 then
				-- 	spin_target_1:Script_ReduceMana(50, nil)
				-- end
			end
			ScreenShake(caster:GetOrigin(), 1, 0.5, 2, 3000, 0, true)
		end
	end)
	
	Timers:CreateTimer(0.78, function()
		if caster:IsAlive() then
			self:PlayEffects2( caught, origin:Normalized() )
			caster:EmitSound("scathach_gait_attack_2")
			
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		
			for k,spin_target_2 in pairs(targets) do
			
				DoDamage(caster, spin_target_2, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				spin_target_2:AddNewModifier(caster, self, "modifier_stachach_gae_bolg_curse", {duration = 10})
				-- spin_target_2:AddNewModifier(caster, self, "modifier_scathach_gait_two_armor_reduction_2", { Duration = armor_reduction_duration })
				
				-- if spin_target_2:GetMaxMana() > 0 then
				-- 	spin_target_2:Script_ReduceMana(50, nil)
				-- end
			end
			ScreenShake(caster:GetOrigin(), 1, 0.5, 2, 3000, 0, true)
		end
	end)
	
	Timers:CreateTimer(1.17, function()
		if caster:IsAlive() then
			self:PlayEffects2( caught, origin:Normalized() )
			caster:EmitSound("scathach_gait_attack_3")
			
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		
			for k,spin_target_3 in pairs(targets) do
			
				DoDamage(caster, spin_target_3, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				spin_target_3:AddNewModifier(caster, self, "modifier_stachach_gae_bolg_curse", {duration = 10})
				-- spin_target_3:AddNewModifier(caster, self, "modifier_scathach_gait_two_armor_reduction_3", { Duration = armor_reduction_duration })
				
				-- if spin_target_3:GetMaxMana() > 0 then
				-- 	spin_target_3:Script_ReduceMana(50, nil)
				-- end
			end
			ScreenShake(caster:GetOrigin(), 1, 0.5, 2, 3000, 0, true)
		end
	end)
	
	Timers:CreateTimer(1.56, function()
		if caster:IsAlive() then
			self:PlayEffects1( caught, origin:Normalized() )
			caster:EmitSound("scathach_gait_attack_1")
			
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		
			for k,spin_target_4 in pairs(targets) do
			
				DoDamage(caster, spin_target_4, damage_big, DAMAGE_TYPE_MAGICAL, 0, self, false)
				spin_target_4:AddNewModifier(caster, self, "modifier_stachach_gae_bolg_curse", {duration = 10})
				spin_target_4:AddNewModifier(caster, self, "modifier_stunned", {Duration =stun_duration})

				-- spin_target_4:AddNewModifier(caster, self, "modifier_scathach_gait_two_armor_reduction_4", { Duration = armor_reduction_duration })
				
				-- if spin_target_4:GetMaxMana() > 0 then
				-- 	spin_target_4:Script_ReduceMana(50, nil)
				-- end
			end
			ScreenShake(caster:GetOrigin(), 3, 0.5, 2, 4000, 0, true)
		end
	end)

	caster:RemoveModifierByName("modifier_scathach_gait_two_window")
	
	Timers:CreateTimer(0.1, function()
		caster:AddNewModifier(caster, self, "modifier_scathach_gait_three_window", { Duration = 4 })
	end)
end

function scathach_gait_two:PlayEffects1( caught, direction )
	-- Get Resources
	local particle_cast = "particles/custom/scathach/gait_two_circle_swing_left.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( effect_cast, false )
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end)

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end

function scathach_gait_two:PlayEffects2( caught, direction )
	-- Get Resources
	local particle_cast = "particles/custom/scathach/gait_two_circle_swing.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( effect_cast, false )
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end)

	-- Create Sound
	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end