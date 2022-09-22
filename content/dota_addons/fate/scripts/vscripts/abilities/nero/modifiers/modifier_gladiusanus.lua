modifier_gladiusanus = class({})

function modifier_gladiusanus:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED,
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_gladiusanus:OnCreated(args)
	if IsServer() then
		self.StunDuration = args.StunDuration
		self.Damage = args.Damage
		self.BonusDamage = args.BonusDamage
		self.AttackSpeed = 1
		self:SetStackCount(0)

		CustomNetTables:SetTableValue("sync","gladiusanus_stats", {attack_speed = self.AttackSpeed})
	end
end

function modifier_gladiusanus:OnRefresh(args)
	if IsServer() then
		self:OnCreated(args)		
	end
end

function modifier_gladiusanus:GetModifierAttackSpeedBonus_Constant()
	if IsServer() then
		return self.AttackSpeed or 0
    elseif IsClient() then
        local attack_speed = CustomNetTables:GetTableValue("sync","gladiusanus_stats").attack_speed or 0
        return attack_speed 
    end
end

function modifier_gladiusanus:OnAttackLanded(args)
	if IsServer() then
		if args.attacker ~= self:GetParent() or not args.target:IsHero() then return end
        
		self:SetStackCount((self:GetStackCount() or 0) + 1)
		if self:GetParent():HasModifier("modifier_ptb_attribute") then
			self.AttackSpeed = self:GetStackCount() * 0

			CustomNetTables:SetTableValue("sync","gladiusanus_stats", {attack_speed = self.AttackSpeed})			
		end

		--if self:GetStackCount() % 5 == 0 then
			local caster = self:GetCaster()
			local target = args.target
			local ability = self:GetAbility()
			self.Damage1 = 0
			if self:GetParent():HasModifier("modifier_rosa_buffer") then
				self.Damage1 = self.BonusDamage*self:GetStackCount()
		    end
		    if self:GetParent():HasModifier("modifier_tres_fontaine_nero") then
		    	self.Damage1 = self.Damage*self:GetStackCount()
		    end


		--	local aoeTargets = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		--	caster:EmitSound("Hero_Clinkz.DeathPact")

		--	self.Damage = self.Damage + self.BonusDamage

		DoDamage(caster, target, self.Damage1, DAMAGE_TYPE_MAGICAL, 0, ability, false)	    		
	    --    end
		 if self:GetStackCount() % 4 == 0 then
		 	self.Damage1 = self.Damage/2*self:GetStackCount()
	        if not target:IsMagicImmune() then
	        	--giveUnitDataDrivenModifier(caster, target, "silenced", 0.5)
	 	    end

	        local flameFx = ParticleManager:CreateParticle("particles/units/heroes/hero_lion/lion_spell_finger_of_death_fire.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(flameFx, 2, target:GetAbsOrigin())

			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf", PATTACH_ABSORIGIN, target)
			ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin()) 
			ParticleManager:SetParticleControl(particle, 1, Vector(350, 350, 350)) 
			ParticleManager:SetParticleControl(particle, 3, Vector(350, 350, 350)) 

			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( flameFx, false )
				ParticleManager:ReleaseParticleIndex( flameFx )
				ParticleManager:DestroyParticle( particle, false )
				ParticleManager:ReleaseParticleIndex( particle )
			end)
			DoDamage(caster, target, self.Damage1, DAMAGE_TYPE_MAGICAL, 0, ability, false)
		end
	end
end

function modifier_gladiusanus:IsHidden()
	return false
end

function modifier_gladiusanus:IsDebuff()
	return false
end

function modifier_gladiusanus:RemoveOnDeath()
	return true
end

function modifier_gladiusanus:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_gladiusanus:GetTexture()
	return "custom/nero_gladiusanus_blauserum"
end