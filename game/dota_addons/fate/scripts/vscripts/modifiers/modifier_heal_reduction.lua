modifier_heal_reduction_tier_1 = class({})


function modifier_heal_reduction_tier_1:IsDebuff() return true end
function modifier_heal_reduction_tier_1:IsHidden() return false end

function modifier_heal_reduction_tier_1:RemoveOnDeath()
	return true
end

function modifier_heal_reduction_tier_1:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
end

function modifier_heal_reduction_tier_1:GetModifierHealAmplify_PercentageTarget()
    if self:GetParent():HasModifier("modifier_heal_reduction_tier_2") or self:GetParent():HasModifier("modifier_heal_reduction_tier_3") or self:GetParent():HasModifier("modifier_heal_reduction_tier_4") or self:GetParent():HasModifier("modifier_heal_reduction_tier_3_uncleansable")  then
        return 0
    else
	    return -20
    end
end

function modifier_heal_reduction_tier_1:GetModifierHPRegenAmplify_Percentage()
	if self:GetParent():HasModifier("modifier_heal_reduction_tier_2") or self:GetParent():HasModifier("modifier_heal_reduction_tier_3") or self:GetParent():HasModifier("modifier_heal_reduction_tier_4") or self:GetParent():HasModifier("modifier_heal_reduction_tier_3_uncleansable")  then
        return 0
    else
	    return -20
    end
end


function modifier_heal_reduction_tier_1:GetEffectName()
	return "particles/healres/hpbar_healres.vpcf"
end

function modifier_heal_reduction_tier_1:GetEffectAttachType()
	return PATTACH_HEALTHBAR 
end
function modifier_heal_reduction_tier_1:HeroEffectPriority()
	return MODIFIER_PRIORITY_NORMAL    
end

modifier_heal_reduction_tier_2 = class({})


function modifier_heal_reduction_tier_2:IsDebuff() return true end
function modifier_heal_reduction_tier_2:IsHidden() return false end

function modifier_heal_reduction_tier_2:RemoveOnDeath()
	return true
end

function modifier_heal_reduction_tier_2:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
end

function modifier_heal_reduction_tier_2:GetModifierHealAmplify_PercentageTarget()
	 if  self:GetParent():HasModifier("modifier_heal_reduction_tier_3") or self:GetParent():HasModifier("modifier_heal_reduction_tier_4") or self:GetParent():HasModifier("modifier_heal_reduction_tier_3_uncleansable")  then
        return 0
    else
	    return -40
    end
end

function modifier_heal_reduction_tier_2:GetModifierHPRegenAmplify_Percentage()
	if  self:GetParent():HasModifier("modifier_heal_reduction_tier_3") or self:GetParent():HasModifier("modifier_heal_reduction_tier_4") or self:GetParent():HasModifier("modifier_heal_reduction_tier_3_uncleansable")  then
        return 0
    else
	    return -40
    end
end

function modifier_heal_reduction_tier_2:GetEffectName()
	return "particles/healres/hpbar_healres_t2.vpcf"
end

function modifier_heal_reduction_tier_2:GetEffectAttachType()
	return PATTACH_HEALTHBAR 
end
function modifier_heal_reduction_tier_2:HeroEffectPriority()
	return MODIFIER_PRIORITY_HIGH   
end

modifier_heal_reduction_tier_3 = class({})


function modifier_heal_reduction_tier_3:IsDebuff() return true end
function modifier_heal_reduction_tier_3:IsHidden() return false end

function modifier_heal_reduction_tier_3:RemoveOnDeath()
	return true
end

function modifier_heal_reduction_tier_3:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
end

function modifier_heal_reduction_tier_3:GetModifierHealAmplify_PercentageTarget()
	if   self:GetParent():HasModifier("modifier_heal_reduction_tier_4") or self:GetParent():HasModifier("modifier_heal_reduction_tier_3_uncleansable")  then
        return 0
    else
	    return -60
    end
end

function modifier_heal_reduction_tier_3:GetModifierHPRegenAmplify_Percentage()
	if   self:GetParent():HasModifier("modifier_heal_reduction_tier_4") or self:GetParent():HasModifier("modifier_heal_reduction_tier_3_uncleansable")  then
        return 0
    else
	    return -60
    end
end
function modifier_heal_reduction_tier_3:HeroEffectPriority()
	return MODIFIER_PRIORITY_ULTRA  
end
function modifier_heal_reduction_tier_3:GetEffectName()
	return "particles/healres/hpbar_healres_t3.vpcf"
end

function modifier_heal_reduction_tier_3:GetEffectAttachType()
	return PATTACH_HEALTHBAR 
end

modifier_heal_reduction_tier_3_uncleansable = class({})


function modifier_heal_reduction_tier_3_uncleansable:IsDebuff() return true end
function modifier_heal_reduction_tier_3_uncleansable:IsHidden() return false end

function modifier_heal_reduction_tier_3_uncleansable:RemoveOnDeath()
	return true
end

function modifier_heal_reduction_tier_3_uncleansable:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
end

function modifier_heal_reduction_tier_3_uncleansable:GetModifierHealAmplify_PercentageTarget()
	if   self:GetParent():HasModifier("modifier_heal_reduction_tier_4") then
        return 0
    else
	    return -60
    end
end

function modifier_heal_reduction_tier_3_uncleansable:GetModifierHPRegenAmplify_Percentage()
	if   self:GetParent():HasModifier("modifier_heal_reduction_tier_4") then
        return 0
    else
	    return -60
    end
end
function modifier_heal_reduction_tier_3_uncleansable:HeroEffectPriority()
	return MODIFIER_PRIORITY_ULTRA  
end
function modifier_heal_reduction_tier_3_uncleansable:GetEffectName()
	return "particles/healres/hpbar_healres_t3_uncleansable.vpcf"
end

function modifier_heal_reduction_tier_3_uncleansable:GetEffectAttachType()
	return PATTACH_HEALTHBAR 
end

modifier_heal_reduction_tier_4 = class({})


function modifier_heal_reduction_tier_4:IsDebuff() return true end
function modifier_heal_reduction_tier_4:IsHidden() return false end

function modifier_heal_reduction_tier_4:RemoveOnDeath()
	return true
end

function modifier_heal_reduction_tier_4:HeroEffectPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA 
end

function modifier_heal_reduction_tier_4:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
end

function modifier_heal_reduction_tier_4:GetModifierHealAmplify_PercentageTarget()
	return -80
end

function modifier_heal_reduction_tier_4:GetModifierHPRegenAmplify_Percentage()
	return -80
end

function modifier_heal_reduction_tier_4:GetEffectName()
	return "particles/healres/hpbar_healres_t4.vpcf"
end

function modifier_heal_reduction_tier_4:GetEffectAttachType()
	return PATTACH_HEALTHBAR 
end
