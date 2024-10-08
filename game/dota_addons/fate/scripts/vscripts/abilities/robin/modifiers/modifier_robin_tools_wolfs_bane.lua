-----------------------------
--    Modifier: Wolf's Bane Stun    --
-----------------------------

modifier_robin_tools_wolfs_bane = class({})

-- Classification --
function modifier_robin_tools_wolfs_bane:IsHidden()
	return true
end

function modifier_robin_tools_wolfs_bane:IsDebuff()
	return true
end

function modifier_robin_tools_wolfs_bane:IsPurgable()
	return true
end

function modifier_robin_tools_wolfs_bane:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVISIBLE] = false,
	}

	return state
end