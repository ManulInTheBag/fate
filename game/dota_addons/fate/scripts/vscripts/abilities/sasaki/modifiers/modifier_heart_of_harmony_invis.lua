modifier_heart_of_harmony_invis = class({})

-----------------------------------------------------------------------------------
if IsServer() then
	function modifier_heart_of_harmony_invis:OnAttackLanded(args)
		if args.attacker == self:GetParent() then self:Destroy() end
	end

	function modifier_heart_of_harmony_invis:OnAbilityFullyCast(args)
		if args.unit == self:GetParent() then self:Destroy() end
	end

	function modifier_heart_of_harmony_invis:DeclareFunctions()
		return { --MODIFIER_EVENT_ON_ATTACK_LANDED,
				 MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
	end
end

function modifier_heart_of_harmony_invis:CheckState()
	return { [MODIFIER_STATE_INVISIBLE] = true,
             [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end

function modifier_heart_of_harmony_invis:GetEffectName()
    return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_heart_of_harmony_invis:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_heart_of_harmony_invis:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_heart_of_harmony_invis:IsHidden()
    return true
end
