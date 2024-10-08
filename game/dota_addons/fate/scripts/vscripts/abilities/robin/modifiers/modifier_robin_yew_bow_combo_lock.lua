modifier_robin_yew_bow_combo_lock = class({})

-- Classification --
function modifier_robin_yew_bow_combo_lock:IsHidden()
	return true
end

function modifier_robin_yew_bow_combo_lock:IsDebuff()
	return true
end

function modifier_robin_yew_bow_combo_lock:IsStunDebuff()
	return false
end

function modifier_robin_yew_bow_combo_lock:IsPurgable()
	return true
end

function modifier_robin_yew_bow_combo_lock:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true }
end