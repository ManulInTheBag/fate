modifier_amaterasu_heal = class({})

if IsServer() then 
	function modifier_amaterasu_heal:OnCreated(args)
		self:StartIntervalThink(0.1)
	end

	function modifier_amaterasu_heal:OnIntervalThink()
		local flAmount = self:GetAbility():GetSpecialValueFor("heal_pct") * self:GetParent():GetMaxHealth() / 1000
		self:GetParent():Heal(flAmount, self:GetCaster())
	end
end

function modifier_amaterasu_heal:GetTexture()
	return "custom/tamamo_amaterasu"
end

function modifier_amaterasu_heal:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end