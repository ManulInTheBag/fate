modifier_mtr_night_checker = class({})
function modifier_mtr_night_checker:IsHidden()
	return true
end

function modifier_mtr_night_checker:IsDebuff()
	return false
end

function modifier_mtr_night_checker:RemoveOnDeath()
	return false
end

function modifier_mtr_night_checker:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_mtr_night_checker:OnCreated()
	self:StartIntervalThink(FrameTime())
end

function modifier_mtr_night_checker:OnIntervalThink()
	if IsServer() then
		if not GameRules:IsDaytime() and (self:GetParent():HasModifier("modifier_murderer_mist_in") or self:GetParent():HasModifier("modifier_whitechapel_murderer")) and self:GetParent():HasModifier("modifier_efficient_killer") then
			self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_mtr_night_checker_tick", {})
		else
			if self:GetParent():HasModifier("modifier_mtr_night_checker_tick") then
				self:GetParent():RemoveModifierByName("modifier_mtr_night_checker_tick")
			end
		end
	end
end