lu_bu_relentless_assault_one = class({})
LinkLuaModifier( "modifier_lu_bu_relentless_assault_one", "abilities/lu_bu/modifiers/modifier_lu_bu_relentless_assault_one", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function lu_bu_relentless_assault_one:OnSpellStart()
	-- get references
	local slow_radius = self:GetSpecialValueFor("shock_radius")
	local slow_duration = self:GetSpecialValueFor("duration")
	local ability_damage = self:GetAbilityDamage()
	
	local caster = self:GetCaster()
	local cast_point = caster:GetAbsOrigin() + caster:GetForwardVector()*200

	-- get list of affected enemies
	local enemies = FindUnitsInRadius (
		self:GetCaster():GetTeamNumber(),
		cast_point,
		nil,
		slow_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)
	
	local blastFx = ParticleManager:CreateParticle("particles/custom/lu_bu/lu_bu_armistice_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( blastFx, 0, cast_point)
	caster:EmitSound("relentless_assault_one")
	caster:EmitSound("lu_bu_relentless_assault")
		
	ScreenShake(caster:GetOrigin(), 5, 0.5, 2, 20000, 0, true)

	-- Do for each affected enemies
	for _,enemy in pairs(enemies) do
		-- Apply damage
		local damage = {
			victim = enemy,
			attacker = self:GetCaster(),
			damage = self:GetSpecialValueFor("damage"),
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = self
		}
		ApplyDamage( damage )

		-- Add slow modifier
		enemy:AddNewModifier(
			self:GetCaster(),
			self,
			"modifier_lu_bu_relentless_assault_one",
			{ duration = slow_duration }
		)
		
		local blastFx = ParticleManager:CreateParticle("particles/custom/lu_bu/lu_bu_small_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl( blastFx, 0, cast_point)
		
		ScreenShake(caster:GetOrigin(), 5, 0.5, 2, 20000, 0, true)
	end

	-- Play effects
	self:PlayEffects()
	
	caster:RemoveModifierByName("modifier_assault_skillswap_1")
	caster:RemoveModifierByName("modifier_relentless_assault_blocker")
	
	local relentless_assault = caster:FindModifierByName("modifier_lu_bu_relentless_assault")
	relentless_assault:SetStackCount(1)
end

function lu_bu_relentless_assault_one:PlayEffects()
	-- get resources
	local sound_cast = "Hero_Ursa.Earthshock"
	local particle_cast = "particles/units/heroes/hero_ursa/ursa_earthshock.vpcf"
	local caster = self:GetCaster()
	-- get data
	local slow_radius = self:GetSpecialValueFor("shock_radius")
	local cast_point = caster:GetAbsOrigin() + caster:GetForwardVector()*200
	-- play particles
	-- local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, cast_point )
	ParticleManager:SetParticleControlForward( effect_cast, 0, self:GetCaster():GetForwardVector() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector(slow_radius/2, slow_radius/2, slow_radius/2) )
	ParticleManager:ReleaseParticleIndex( effect_cast )
	
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( effect_cast, false )
		ParticleManager:ReleaseParticleIndex( effect_cast )
	end)

	-- play sounds
	EmitSoundOn( sound_cast, self:GetCaster() )
end