modifier_true_assassin_selfmod = class({})
function modifier_true_assassin_selfmod:IsHidden() return false end
function modifier_true_assassin_selfmod:IsDebuff() return false end
--function modifier_true_assassin_selfmod:IsPurgable() return false end
--function modifier_true_assassin_selfmod:IsPurgeException() return false end
function modifier_true_assassin_selfmod:RemoveOnDeath() return false end
function modifier_true_assassin_selfmod:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end
function modifier_true_assassin_selfmod:DeclareFunctions()
	local func = {	MODIFIER_PROPERTY_STATS_AGILITY_BONUS,}
	return func
end
function modifier_true_assassin_selfmod:GetModifierBonusStats_Agility()
	if self:GetParent():PassivesDisabled() then
		return nil
	end
	if self:GetParent():HasModifier("modifier_selfmod_agility") then
		return self:GetAbility():GetSpecialValueFor("bonus_stats")*2*self:GetStackCount()
	end
	return self:GetAbility():GetSpecialValueFor("bonus_stats")*self:GetStackCount()
end
function modifier_true_assassin_selfmod:OnCreated()
	if IsServer() then
		if self:GetAbility().nKills ~= nil then
			self:SetStackCount(self:GetAbility().nKills)
		end
	end
end