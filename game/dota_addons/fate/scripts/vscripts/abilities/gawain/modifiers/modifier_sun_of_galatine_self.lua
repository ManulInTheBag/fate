modifier_sun_of_galatine_self = class({})

function modifier_sun_of_galatine_self:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			 MODIFIER_PROPERTY_STATS_INTELLECT_BONUS }
end

-----------------------------------------------------------------------------------

function modifier_sun_of_galatine_self:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_sun_of_galatine_self:IsPurgable()
    return false
end

function modifier_sun_of_galatine_self:IsDebuff()
    return false
end

function modifier_sun_of_galatine_self:OnCreated()
	local str = math.floor(self:GetParent():GetStrength()+0.5)*3
	local agi = math.floor(self:GetParent():GetAgility()+0.5)*3
	local int = math.floor(self:GetParent():GetIntellect()+0.5)*3
end

function modifier_sun_of_galatine_self:GetModifierBonusStats_Strength()
	return 99
end

function modifier_sun_of_galatine_self:GetModifierBonusStats_Agility()
	return 99
end

function modifier_sun_of_galatine_self:GetModifierBonusStats_Intellect()
	return 99
end

function modifier_sun_of_galatine_self:RemoveOnDeath()
    return true
end

function modifier_sun_of_galatine_self:GetTexture()
    return "custom/gawain_galatine_combo"
end

-----------------------------------------------------------------------------------
