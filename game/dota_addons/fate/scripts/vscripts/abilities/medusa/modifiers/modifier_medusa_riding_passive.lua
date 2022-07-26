modifier_medusa_riding_passive = class({})

function modifier_medusa_riding_passive:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_MAX,
			 MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MAX,
			 MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
			 MODIFIER_PROPERTY_MOVESPEED_LIMIT }	
end


function modifier_medusa_riding_passive:GetModifierMoveSpeed_Max()
	return 550
end	

function modifier_medusa_riding_passive:GetModifierMoveSpeed_Limit()
	return 550
end

function modifier_medusa_riding_passive:GetModifierIgnoreMovespeedLimit()
	return true
end

function modifier_medusa_riding_passive:GetModifierMoveSpeed_AbsoluteMax()
	return 550
end

function modifier_medusa_riding_passive:IsHidden()
	return true 
end

function modifier_medusa_riding_passive:IsPermanent()
	return true
end

function modifier_medusa_riding_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end