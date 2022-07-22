modifier_selfmod_agility = class({})

function modifier_selfmod_agility:OnCreated(args)
	if IsServer() then
		self.AttackBonus = self:GetAbility():GetSpecialValueFor("heal_amount")
		CustomNetTables:SetTableValue("sync","self_mod_damage", { atk_bonus = self.AttackBonus })
	end
	self.bFocusing = false
	--[[self.fx = ParticleManager:CreateParticle("particles/okita/okita_windrun.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(self.fx, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.fx, 3, self:GetParent():GetAbsOrigin())]]
	if self:GetParent().DesertNomadAcquired then
		--self:StartIntervalThink(FrameTime())
	end
end

function modifier_selfmod_agility:OnRefresh()
	self:OnCreated()
end

function modifier_selfmod_agility:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			--MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_ORDER,}
end

function modifier_selfmod_agility:GetModifierPreAttack_BonusDamage()
	if IsServer() then
		return self.AttackBonus
	elseif IsClient() then
		local atk_bonus = CustomNetTables:GetTableValue("sync","self_mod_damage").atk_bonus
        return atk_bonus 
	end
end

function modifier_selfmod_agility:IsHidden()
	return false
end

function modifier_selfmod_agility:IsDebuff()
	return false
end

function modifier_selfmod_agility:RemoveOnDeath()
	return true
end

function modifier_selfmod_agility:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_selfmod_agility:GetTexture()
	return "custom/true_assassin_attribute_weakening_venom"
end

function modifier_selfmod_agility:OnIntervalThink()
	if self:GetParent():AttackReady() and not self:GetParent():IsStunned() and self.target and not self.target:IsNull() and self.target:IsAlive() and (self.target:GetAbsOrigin() - self:GetParent():GetAbsOrigin()):Length2D() <= (self:GetParent():Script_GetAttackRange()+75) and self.bFocusing then
		--self:GetParent():SetForwardVector((self.target:GetAbsOrigin() - self:GetParent():GetAbsOrigin()):Normalized())
		self:GetParent():StartGesture(ACT_DOTA_ATTACK)
		self:GetParent():PerformAttack(self.target, true, true, false, true, true, false, false)
	end
end

function modifier_selfmod_agility:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return nil end
	self.target = args.target
	self.bFocusing = true
end

function modifier_selfmod_agility:OnOrder(keys)
	if keys.unit == self:GetParent() then
		if keys.order_type == DOTA_UNIT_ORDER_STOP or keys.order_type == DOTA_UNIT_ORDER_CONTINUE or not self:GetParent():AttackReady() then
			self.bFocusing	= false
		else
			self.bFocusing	= true
		end
	end
end