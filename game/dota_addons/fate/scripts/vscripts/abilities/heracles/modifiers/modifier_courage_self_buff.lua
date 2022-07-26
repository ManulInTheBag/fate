modifier_courage_self_buff = class({})

if IsServer() then
	function modifier_courage_self_buff:OnCreated(args)	
		if args.Stacks > 0 then
			self:SetStackCount(args.Stacks)
		end

		self.Particle = ParticleManager:CreateParticle("particles/custom/berserker/courage/buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(self.Particle, 1, Vector(self:GetStackCount() + 1,1,1))
		ParticleManager:SetParticleControl(self.Particle, 3, Vector(400,1,1))	
	end

	function modifier_courage_self_buff:OnRefresh(args)
		if args.Stacks > 0 then
			self:SetStackCount(args.Stacks)
		end
		
		ParticleManager:SetParticleControl(self.Particle, 1, Vector(self:GetStackCount() + 1,1,1))
		ParticleManager:SetParticleControl(self.Particle, 3, Vector(400,1,1))
	end

	function modifier_courage_self_buff:OnDestroy()
		ParticleManager:DestroyParticle(self.Particle, false)
		ParticleManager:ReleaseParticleIndex(self.Particle)
	end
end

function modifier_courage_self_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			 --MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			 MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_courage_self_buff:GetModifierIncomingDamage_Percentage()
	return self:GetAbility():GetSpecialValueFor("self_damage_inc") * self:GetStackCount()
end

function modifier_courage_self_buff:GetModifierBonusStats_Strength()
	return (self:GetAbility():GetSpecialValueFor("self_str_inc")*self:GetStackCount() + self:GetAbility():GetSpecialValueFor("self_str_inc_base")*(self:GetParent().IsEternalRageAcquired and 1 or 0))
end

--[[function modifier_courage_self_buff:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("self_armor_reduc") * self:GetStackCount()
end]]

function modifier_courage_self_buff:GetModifierPreAttack_BonusDamage()
	return (self:GetAbility():GetSpecialValueFor("bonus_damage") * self:GetStackCount() + self:GetAbility():GetSpecialValueFor("self_damage_inc_base")*(self:GetParent().IsEternalRageAcquired and 1 or 0))
end

function modifier_courage_self_buff:GetModifierMoveSpeedBonus_Percentage()
	return (self:GetAbility():GetSpecialValueFor("bonus_ms") * self:GetStackCount() + self:GetAbility():GetSpecialValueFor("self_ms_inc_base")*(self:GetParent().IsEternalRageAcquired and 1 or 0))
end

function modifier_courage_self_buff:GetModifierAttackSpeedBonus_Constant()
	return (self:GetAbility():GetSpecialValueFor("bonus_as") * self:GetStackCount() + self:GetAbility():GetSpecialValueFor("self_as_inc_base")*(self:GetParent().IsEternalRageAcquired and 1 or 0))
end

function modifier_courage_self_buff:IsHidden()
	return false
end

function modifier_courage_self_buff:IsDebuff()
	return false
end

function modifier_courage_self_buff:RemoveOnDeath()
	return true
end

function modifier_courage_self_buff:GetAttributes()
  return MODIFIER_ATTRIBUTE_NONE
end

function modifier_courage_self_buff:GetTexture()
	return "custom/berserker_5th_courage"
end