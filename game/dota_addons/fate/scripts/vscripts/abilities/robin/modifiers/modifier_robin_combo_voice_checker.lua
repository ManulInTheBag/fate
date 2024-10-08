modifier_robin_combo_voice_checker = class({})

function modifier_robin_combo_voice_checker:OnCreated(args)
end

function modifier_robin_combo_voice_checker:OnRefresh(args)
end

function modifier_robin_combo_voice_checker:OnUnitMoved()	
end


function modifier_robin_combo_voice_checker:OnDestroy()	
	StopGlobalSound("robin_yew_bow_combo")
end

function modifier_robin_combo_voice_checker:IsHidden()
	return true
end

function modifier_robin_combo_voice_checker:IsDebuff()
	return false
end

function modifier_robin_combo_voice_checker:RemoveOnDeath()
	return true
end

function modifier_robin_combo_voice_checker:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_robin_combo_voice_checker:GetTexture()
	return "custom/nero_aestus_domus_aurea"
end