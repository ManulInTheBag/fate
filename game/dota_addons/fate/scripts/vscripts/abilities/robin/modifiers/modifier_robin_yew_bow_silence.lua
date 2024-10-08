-----------------------------
--    Modifier: Yew Bow Silence    --
-----------------------------

modifier_robin_yew_bow_silence = class({})

-- Classification --
function modifier_robin_yew_bow_silence:IsHidden()
	return true
end

function modifier_robin_yew_bow_silence:IsDebuff()
	return true
end

function modifier_robin_yew_bow_silence:IsStunDebuff()
	return false
end

function modifier_robin_yew_bow_silence:IsPurgable()
	return true
end

function modifier_robin_yew_bow_silence:CheckState()
	return { [MODIFIER_STATE_SILENCED] = true }
end