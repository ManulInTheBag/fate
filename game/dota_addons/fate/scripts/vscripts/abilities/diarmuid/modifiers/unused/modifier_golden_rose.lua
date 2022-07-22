modifier_golden_rose = class({})

function modifier_golden_rose:OnCreated(args)
	if IsServer() then
		self:StartIntervalThink(0.2)
	end
end

function modifier_golden_rose:OnIntervalThink()
	if IsServer() then
		local target = self:GetParent()
		local caster = self:GetCaster()
		local ability = self:GetAbility()		

		DoDamage(caster, target, 10, DAMAGE_TYPE_PURE, 0, ability, false)
	end
end

--[[function modifier_golden_rose:OnDestroy()
	--self:StartIntervalThink(-1)
end]]

function modifier_golden_rose:IsHidden()
	return false
end

function modifier_golden_rose:IsDebuff()
	return true
end

function modifier_golden_rose:RemoveOnDeath()
	return true
end

function modifier_golden_rose:IsPurgable()
	return false
end

function modifier_golden_rose:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_golden_rose:GetTexture()
	return "custom/diarmuid_attribute_golden_rose"
end
