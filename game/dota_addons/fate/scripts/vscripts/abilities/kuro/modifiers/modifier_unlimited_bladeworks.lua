modifier_unlimited_bladeworks = class({})

function modifier_unlimited_bladeworks:OnDestroy()
	if IsServer() then
		local ability = self:GetAbility()
		self:GetParent().IsUBWActive = false

		ability:EndUBW()
	end
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