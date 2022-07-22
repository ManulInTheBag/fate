modifier_breaker_gorgon = class({})

LinkLuaModifier("modifier_breaker_gorgon_frozen", "abilities/medusa/modifiers/modifier_breaker_gorgon_frozen", LUA_MODIFIER_MOTION_NONE)

function modifier_breaker_gorgon:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			 MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE }
end
if IsServer() then
	function modifier_breaker_gorgon:OnCreated(args)	
		self:SetStackCount(1)
		self.SlowPerc = args.SlowPerc
		self.TurnRateSlow = args.TurnRateSlow
		self.ExtraSlow = args.ExtraSlow
		self:StartIntervalThink(0.1)
	end

	function modifier_breaker_gorgon:OnIntervalThink()
		local hero = self:GetParent()
		local caster = self:GetCaster()

		if IsFacingUnit(hero, caster, 60) or IsFacingUnit(caster, hero, 60) then
			self:SetStackCount(math.min(20, self:GetStackCount() + 1))
			self.SlowPerc = self.SlowPerc + self.ExtraSlow
		end

		if self:GetStackCount() >= 20 then
			hero:AddNewModifier(caster, self:GetAbility(), "modifier_breaker_gorgon_frozen", { Duration = 2})
			self:Destroy()
		end
	end
end

function modifier_breaker_gorgon:GetEffectName()
	return "particles/custom/rider/rider_breaker_gorgon_debuff.vpcf"
end

function modifier_breaker_gorgon:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_breaker_gorgon:IsHidden()
	return false
end

function modifier_breaker_gorgon:IsDebuff()
	return true
end

function modifier_breaker_gorgon:RemoveOnDeath()
	return true
end

function modifier_breaker_gorgon:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_breaker_gorgon:GetTexture()
	return "custom/rider_5th_breaker_gorgon"
end