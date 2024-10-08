-----------------------------
--    Modifier: Faceless King    --
-----------------------------

modifier_robin_faceless_king = class({})

LinkLuaModifier("modifier_robin_faceless_king_active", "abilities/robin/modifiers/modifier_robin_faceless_king_active", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_robin_may_king_invis", "abilities/robin/modifiers/modifier_robin_may_king_invis", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_robin_faceless_king_debuff", "abilities/robin/modifiers/modifier_robin_faceless_king_debuff", LUA_MODIFIER_MOTION_NONE)

function modifier_robin_faceless_king:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

if IsServer() then
	function modifier_robin_faceless_king:OnTakeDamage(args)
		if args.unit ~= self:GetParent() then return end
		local ability = self:GetAbility()
		local caster = self:GetParent()

		if args.damage < 1000
			and caster:GetHealth() <= 0 
			and not caster:HasModifier("modifier_robin_faceless_king_cooldown") 
			and IsRevivePossible(caster)
			then

			caster:SetHealth(1000)
			
			local radius = 800
			
			self:PlayEffects( radius )
			
			caster:EmitSound("robin_attacked_1")
			
			
			 
			faceless_king_duration = ability:GetSpecialValueFor("faceless_king_duration")
			
			may_king_ability = caster:FindAbilityByName("robin_may_king")
			
			StartAnimation(caster, {duration=1.00, activity=ACT_DOTA_CAST_ABILITY_2_ES_ROLL, rate=1.0})
			
			HardCleanse(caster)
			caster:EmitSound("")
			caster:AddNewModifier(caster, ability, "modifier_robin_faceless_king_active", { Duration = 0 })
			caster:AddNewModifier(caster, may_king_ability, "modifier_robin_may_king_invis", {fadeDelay = may_king_ability:GetSpecialValueFor("fade_delay"),
													    		duration = may_king_ability:GetSpecialValueFor("duration")

	})
			local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 700, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
			for i=1, #units do
				print(units[i]:GetUnitName())
				units[i]:AddNewModifier(caster, ability, "modifier_robin_faceless_king_debuff", { Duration = faceless_king_duration })
			end 
		end
	end
end

function modifier_robin_faceless_king:PlayEffects( radius )
	local particle_cast = "particles/custom/robin/robin_dust.vpcf"
	local sound_cast = "Hero_Puck.Waning_Rift"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
	ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( radius, radius, radius ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOnLocationWithCaster( self:GetCaster():GetOrigin(), sound_cast, self:GetCaster() )
end

function modifier_robin_faceless_king:IsHidden()
	return false
end