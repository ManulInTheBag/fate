modifier_artoria_improved_instinct = class({})

function modifier_artoria_improved_instinct:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_artoria_improved_instinct:OnCreated(args)
	if IsServer() then
	end
end

function modifier_artoria_improved_instinct:GetModifierMagicalResistanceBonus()
	return 20
end

function modifier_artoria_improved_instinct:IsHidden()
	return false 
end

function modifier_artoria_improved_instinct:RemoveOnDeath()
	return true
end