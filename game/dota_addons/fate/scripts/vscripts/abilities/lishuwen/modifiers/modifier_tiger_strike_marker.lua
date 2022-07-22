modifier_tiger_strike_marker = class({})

function modifier_tiger_strike_marker:OnCreated(table)
	
end

function modifier_tiger_strike_marker:IsPurgable()
	return false
end

function modifier_tiger_strike_marker:IsHidden()
	return false
end

function modifier_tiger_strike_marker:IsDebuff()
	return true
end

function modifier_tiger_strike_marker:RemoveOnDeath()
	return true
end

function modifier_tiger_strike_marker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_tiger_strike_marker:GetTexture()
	return "custom/lishuwen_fierce_tiger_strike"
end

function modifier_tiger_strike_marker:GetEffectName()
	return "particles/econ/items/juggernaut/jugg_arcana/juggernaut_arcana_v2_crit_tgt.vpcf"
end

function modifier_tiger_strike_marker:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

--[[function modifier_tiger_strike_marker:GetEffectName()
	return "particles/units/heroes/hero_spectre/spectre_ambient.vpcf"
end

function modifier_tiger_strike_marker:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end]]