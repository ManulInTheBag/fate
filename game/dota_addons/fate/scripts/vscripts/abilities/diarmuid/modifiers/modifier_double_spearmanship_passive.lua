modifier_double_spearmanship_passive = class({})

function modifier_double_spearmanship_passive:OnCreated(args)
	if IsServer() then
		self.DoubleAttackChance = args.DoubleAttackChance
		self.ProcReady = true
		--self:StartIntervalThink(0.1)
	end
end

function modifier_double_spearmanship_passive:OnRefresh(args)
	self:OnCreated(args)
end

function modifier_double_spearmanship_passive:OnAttackLanded(args)
	if IsServer() then
		if args.attacker ~= self:GetParent() then
			return
		else
			self:GetParent():EmitSound("Hero_PhantomLancer.Attack")
		end

		if not (self:GetParent():HasModifier("modifier_rampant_warrior") or self:GetParent():HasModifier("modifier_double_spearmanship_active")) then 
			local proc = RandomInt(1, 100)
			local target = args.target
			local caster = self:GetParent()

			if proc < self.DoubleAttackChance and self.ProcReady then
				self.ProcReady = false
				self:StartIntervalThink(0.1)
				caster:PerformAttack(target, true, true, true, true, false, false, false)
			end
		end
	end
end

function modifier_double_spearmanship_passive:OnIntervalThink()
	self.ProcReady = true
	self:StartIntervalThink(-1)
	--print("passive double attack cooldown")
end

function modifier_double_spearmanship_passive:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED
	 }
end

function modifier_double_spearmanship_passive:IsHidden()
	return true 
end

function modifier_double_spearmanship_passive:RemoveOnDeath()
	return false
end

function modifier_double_spearmanship_passive:IsDebuff()
	return false 
end

function modifier_double_spearmanship_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end