modifier_winner_inertia = class({})

if IsServer() then
	function modifier_winner_inertia:OnCreated(args)
		self.Particle = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(self.Particle, 0, self:GetParent():GetOrigin())
	end

	function modifier_winner_inertia:OnDestroy()
		ParticleManager:DestroyParticle(self.Particle, false)
		ParticleManager:ReleaseParticleIndex(self.Particle)
	end
end


function modifier_winner_inertia:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_winner_inertia:GetModifierMoveSpeedBonus_Percentage()
    return 35
end

function modifier_winner_inertia:IsHidden()
    return true 
end