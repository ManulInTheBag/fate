modifier_unlimited_bladeworks = class({})

function modifier_unlimited_bladeworks:OnDestroy()
	if IsServer() then
		local ability = self:GetAbility()
		if not self:GetParent().IsUBWActive then return end
		self:GetParent().IsUBWActive = false

		ability:EndUBW()
	end
end

function modifier_unlimited_bladeworks:OnCreated()
	if IsServer() then
		self:GetParent():Heal(self:GetAbility():GetSpecialValueFor("bonus_health") + (self:GetParent():HasModifier("modifier_shroud_of_martin") and self:GetParent():GetIntellect()*0 or 0), self:GetParent())
	end
end

function modifier_unlimited_bladeworks:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, 
			 MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			 MODIFIER_PROPERTY_HEALTH_BONUS}
end

function modifier_unlimited_bladeworks:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_unlimited_bladeworks:IsPurgable()
    return true
end

function modifier_unlimited_bladeworks:IsDebuff()
    return false
end

function modifier_unlimited_bladeworks:RemoveOnDeath()
    return true
end

function modifier_unlimited_bladeworks:GetTexture()
    return "custom/archer_5th_ubw"
end

function modifier_unlimited_bladeworks:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_health") + (self:GetParent():HasModifier("modifier_shroud_of_martin") and self:GetParent():GetIntellect()*0 or 0)
end

function modifier_unlimited_bladeworks:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_unlimited_bladeworks:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_mr")
end