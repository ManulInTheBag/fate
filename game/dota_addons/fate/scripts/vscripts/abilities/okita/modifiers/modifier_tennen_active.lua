modifier_tennen_active = class({})

function modifier_tennen_active:OnCreated()
	self.bFocusing = false
	if self:GetParent().IsCoatOfOathsAcquired then
		self:StartIntervalThink(FrameTime())
	end
	self.fx = ParticleManager:CreateParticle("particles/okita/okita_windrun.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(self.fx, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.fx, 3, self:GetParent():GetAbsOrigin())
end

function modifier_tennen_active:OnIntervalThink()
	if self:GetParent():AttackReady() and not self:GetParent():IsStunned() and self.target and not self.target:IsNull() and self.target:IsAlive() and (self.target:GetAbsOrigin() - self:GetParent():GetAbsOrigin()):Length2D() <= (self:GetParent():Script_GetAttackRange()+75) and self.bFocusing then
		--self:GetParent():SetForwardVector((self.target:GetAbsOrigin() - self:GetParent():GetAbsOrigin()):Normalized())
		self:GetParent():StartGesture(ACT_DOTA_ATTACK)
		self:GetParent():PerformAttack(self.target, true, true, false, true, true, false, false)
	end
	ProjectileManager:ProjectileDodge(self:GetParent())
end

function modifier_tennen_active:IsDebuff() return false end

function modifier_tennen_active:IsHidden() return false end

function modifier_tennen_active:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			--MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_ORDER,}
end

function modifier_tennen_active:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return nil end
	self.target = args.target
	self.bFocusing = true
end

function modifier_tennen_active:OnOrder(keys)
	if keys.unit == self:GetParent() then
		if keys.order_type == DOTA_UNIT_ORDER_STOP or keys.order_type == DOTA_UNIT_ORDER_CONTINUE or not self:GetParent():AttackReady() then
			self.bFocusing	= false
		else
			self.bFocusing	= true
		end
	end
end

function modifier_tennen_active:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("dmg_bonus")
end

function modifier_tennen_active:OnDestroy()
	ParticleManager:DestroyParticle(self.fx, false)
end
function modifier_tennen_active:OnRefresh()
	self:OnDestroy()
	self:OnCreated()
end