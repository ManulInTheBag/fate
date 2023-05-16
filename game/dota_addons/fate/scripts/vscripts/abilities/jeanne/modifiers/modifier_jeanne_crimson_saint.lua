modifier_jeanne_crimson_saint = class({})

if IsServer() then
	function modifier_jeanne_crimson_saint:OnCreated(args)
		local caster = self:GetParent()
		self.ability = self:GetAbility()
		caster:SwapAbilities("jeanne_luminosite_eternelle", "jeanne_crimson_saint_la_pucelle", false, true)
		
		self.burn_damage = self.ability:GetSpecialValueFor("burn_damage")
		self.burn_radius = self.ability:GetSpecialValueFor("burn_radius")

		self.self_damage = self.ability:GetSpecialValueFor("self_damage")/100
		
		self.LockedHealth = self:GetParent():GetHealth()

		self.think = 0
		self.interval = 0.1
		
		local la_pucelle = caster:FindAbilityByName("jeanne_crimson_saint_la_pucelle")
		la_pucelle:StartCooldown(4)
		
		self:StartIntervalThink(FrameTime())
	end

	function modifier_jeanne_crimson_saint:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("jeanne_luminosite_eternelle", "jeanne_crimson_saint_la_pucelle", true, false)
			
		if caster:IsAlive() then
			caster:Execute(self, caster, { bExecution = true })
		end
	end

	function modifier_jeanne_crimson_saint:OnIntervalThink()
		local caster = self:GetCaster()
		local max_hp = caster:GetMaxHealth()
		local self_damage = max_hp * self.self_damage * FrameTime()
		local ability = caster:FindAbilityByName("jeanne_crimson_saint")
		
		local current_hp = caster:GetHealth()
		
		if current_hp < self.LockedHealth then
			self.LockedHealth = current_hp
		end
		self.LockedHealth = self.LockedHealth - self_damage
		if self.LockedHealth <= 1 then
			self:Destroy()
			return
		end
		caster:SetHealth(self.LockedHealth)

		self.think = self.think + FrameTime()
		if self.think >= self.interval then
			self.think = 0
			if caster ~= nil then
				local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, self.burn_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
				for k,v in pairs(targets) do						
				    DoDamage(caster, v, self.burn_damage * self.interval, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
				end
			end
		end
	end

	function modifier_jeanne_crimson_saint:OnAttackLanded(args)
		local caster = self:GetParent()
		local target = args.target

		if caster ~= args.attacker then return end
		
		local direction = caster:GetForwardVector()
		local target_max_hp = target:GetMaxHealth()
			
			-- Create Particle
		local particle_cast = "particles/jeanne/jeanne_heat_wave.vpcf"
		
		local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, self:GetCaster() )
		ParticleManager:SetParticleControl( effect_cast, 0, self:GetCaster():GetOrigin() )
		ParticleManager:SetParticleControlForward( effect_cast, 0, direction )
		ParticleManager:ReleaseParticleIndex( effect_cast )

		 DoDamage(caster, target, target_max_hp * self:GetAbility():GetSpecialValueFor("attack_damage")/100, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end
end

function modifier_jeanne_crimson_saint:DeclareFunctions()
	local Funcs = {	
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}

	return Funcs
end

function modifier_jeanne_crimson_saint:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attack_speed_bonus")
end

function modifier_jeanne_crimson_saint:IsHidden()
	return false
end

function modifier_jeanne_crimson_saint:RemoveOnDeath()
	return true 
end

function modifier_jeanne_crimson_saint:GetEffectName()
	return "particles/jeanne/jeanne_la_pucelle_aura.vpcf"
end