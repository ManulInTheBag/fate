modifier_artoria_ultimate_excalibur_sound = class({})

function modifier_artoria_ultimate_excalibur_sound:OnDestroy()
	if IsServer() then
		StopGlobalSound("artoria_ultimate_excalibur")
	end
end

function modifier_artoria_ultimate_excalibur_sound:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_artoria_ultimate_excalibur_sound:IsPurgable()
    return true
end

function modifier_artoria_ultimate_excalibur_sound:IsDebuff()
    return false
end

function modifier_artoria_ultimate_excalibur_sound:RemoveOnDeath()
    return true
end