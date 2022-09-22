modifier_durandal_armor_shred = class({})

function modifier_durandal_armor_shred:DeclareFunctions()
	local func = { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}

	return func
end

function modifier_durandal_armor_shred:GetModifierPhysicalArmorBonus() 
    local ability = self:GetAbility()
    local pct_armor_reduction = ability:GetSpecialValueFor("armor_shred_pct")
    local hero_armor = self:GetParent():GetPhysicalArmorValue(false)
    local stacks = self:GetStackCount()    

    return (pct_armor_reduction / 100 * stacks) * hero_armor
end

-----------------------------------------------------------------------------------
function modifier_durandal_armor_shred:GetEffectName()
    return "particles/items_fx/diffusal_slow.vpcf"
end

function modifier_durandal_armor_shred:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_durandal_armor_shred:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_durandal_armor_shred:IsPurgable()
    return false
end

function modifier_durandal_armor_shred:IsDebuff()
    return true
end

function modifier_durandal_armor_shred:RemoveOnDeath()
    return true
end

function modifier_durandal_armor_shred:GetTexture()
    return "custom/lancelot_durandal" 
end
-----------------------------------------------------------------------------------
