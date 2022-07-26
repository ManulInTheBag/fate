modifier_enuma_elish_bandaid = class({})

function modifier_enuma_elish_bandaid:IsHidden()
	return true
end

function modifier_enuma_elish_bandaid:IsDebuff()
	return true
end

function modifier_enuma_elish_bandaid:RemoveOnDeath()
	return true
end

function modifier_enuma_elish_bandaid:IsPurgable()
	return false
end


modifier_enuma_model = class({})

function modifier_enuma_model:IsHidden() return true end
function modifier_enuma_model:DeclareFunctions()
  return { MODIFIER_PROPERTY_MODEL_CHANGE}
end

function modifier_enuma_model:GetModifierModelChange()
  return "models/updated_by_seva_and_hudozhestvenniy_film_spizdili/gilgamesh/gilgameshcausalunanimea.vmdl"
end