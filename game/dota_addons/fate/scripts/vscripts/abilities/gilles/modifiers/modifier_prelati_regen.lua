modifier_prelati_regen = class({})

if IsServer() then
	function modifier_prelati_regen:OnCreated(args)
		self:StartIntervalThink(0.1)
	end

	function modifier_prelati_regen:OnIntervalThink()
		if self:GetParent():HasModifier("modifier_prelati_regen_block") or not self:GetParent():IsAlive() then
			return
		end

		local regen_pct = self:GetAbility():GetSpecialValueFor("regen_pct")
		local max_mana = self:GetParent():GetMaxMana()

		self:GetParent():GiveMana(max_mana * regen_pct / 1000)
	end
end

function modifier_prelati_regen:IsHidden()
	return true 
end

function modifier_prelati_regen:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end