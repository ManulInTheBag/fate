modifier_amaterasu_heal = class({})

if IsServer() then 
	function modifier_amaterasu_heal:OnCreated(args)
		self.nTotalHeal = self:GetAbility():GetSpecialValueFor("heal_pct")
		self:StartIntervalThink(0.1)

		--print(self:GetParent():GetHealth(), "START")
	end

	function modifier_amaterasu_heal:OnIntervalThink()
		--local flAmount = self:GetAbility():GetSpecialValueFor("heal_pct") * 0.1-- * self:GetParent():GetMaxHealth() / 1000
		self:GetParent():Heal(self.nTotalHeal * 0.1, self:GetCaster())
	end
	function modifier_amaterasu_heal:OnDestroy()
		--print(self:GetParent():GetHealth(), "END")
	end
end

function modifier_amaterasu_heal:GetTexture()
	return "custom/tamamo_amaterasu"
end

function modifier_amaterasu_heal:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end