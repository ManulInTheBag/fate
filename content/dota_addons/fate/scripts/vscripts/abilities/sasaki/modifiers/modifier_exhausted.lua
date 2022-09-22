modifier_exhausted = class({})

function modifier_exhausted:DeclareFunctions()
	return { MODIFIER_PROPERTY_MANA_REGEN_CONSTANT }
end

function modifier_exhausted:OnCreated(args)
	if IsServer() then
		local caster = self:GetParent()

		caster:SetMana(0)
	end
end

function modifier_exhausted:OnRefresh(args)
	self:OnCreated(args)
end

function modifier_exhausted:GetModifierConstantManaRegen()
	return -69
end

function modifier_exhausted:IsHidden()
	return false
end

function modifier_exhausted:IsDebuff()
	return true
end

function modifier_exhausted:RemoveOnDeath()
	return true
end

function modifier_exhausted:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_exhausted:GetTexture()
	return "custom/false_assassin_minds_eye"
end