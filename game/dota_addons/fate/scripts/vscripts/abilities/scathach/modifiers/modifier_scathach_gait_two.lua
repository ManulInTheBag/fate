modifier_scathach_gait_two = class({})
--------------------------------------------------------------------------------
-- Classifications
function modifier_scathach_gait_two:IsHidden()
	return true
end

function modifier_scathach_gait_two:IsDebuff()
	return false
end

function modifier_scathach_gait_two:IsPurgable()
	return false
end
--------------------------------------------------------------------------------
-- Initializations
function modifier_scathach_gait_two:OnCreated( kv )
end

function modifier_scathach_gait_two:OnRefresh( kv )
end

function modifier_scathach_gait_two:OnDestroy( kv )
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_scathach_gait_two:CheckState()
	local state = {
		--[MODIFIER_STATE_ROOTED] = false, 
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		--[MODIFIER_STATE_MUTED] = false,
	}
	return state
end