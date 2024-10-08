-----------------------------
--    Modifier: It's a Trap    --
-----------------------------

modifier_robin_tools_its_a_trap = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_robin_tools_its_a_trap:IsHidden()
	return false
end

function modifier_robin_tools_its_a_trap:IsDebuff()
	return true
end

function modifier_robin_tools_its_a_trap:IsStunDebuff()
	return false
end

function modifier_robin_tools_its_a_trap:IsPurgable()
	return true
end

function modifier_robin_tools_its_a_trap:GetPriority()
	return MODIFIER_PRIORITY_HIGH
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_robin_tools_its_a_trap:OnCreated( kv )

end

function modifier_robin_tools_its_a_trap:OnRefresh( kv )
	
end

function modifier_robin_tools_its_a_trap:OnRemoved()
end

function modifier_robin_tools_its_a_trap:OnDestroy()
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_robin_tools_its_a_trap:CheckState()
	local state = {
		[MODIFIER_STATE_INVISIBLE] = false,
		[MODIFIER_STATE_ROOTED] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_robin_tools_its_a_trap:GetEffectName()
	return "particles/custom/robin/robin_trap_debuff.vpcf"
end

function modifier_robin_tools_its_a_trap:GetTexture()
    return "custom/robin/robin_tools_its_a_trap"
end

function modifier_robin_tools_its_a_trap:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end