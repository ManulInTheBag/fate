modifier_minds_eye_vision = class({})

function modifier_minds_eye_vision:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }
 
    return funcs
end

function modifier_minds_eye_vision:OnCreated()
	if IsClient() then
		self.OverheadFx = ParticleManager:CreateParticle( "particles/zlodemon/zlodemon_overhead_eye.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControl( self.OverheadFx , 1, Vector( 1,0.1,0.1 ) )
		ParticleManager:SetParticleControl( self.OverheadFx , 2, Vector( 100,0,0 ) )
	end
end

function modifier_minds_eye_vision:OnDestroy()
    if type(self.OverheadFx) == "number" then
            ParticleManager:DestroyParticle(self.OverheadFx, true)
            ParticleManager:ReleaseParticleIndex(self.OverheadFx)
    end
end

function modifier_minds_eye_vision:GetModifierProvidesFOWVision()
	if CanBeDetected(self:GetParent()) then
		return 1
	end
	return 0
end

function modifier_minds_eye_vision:IsHidden()
	return false
end

function modifier_minds_eye_vision:IsDebuff()
    return true
end

function modifier_minds_eye_vision:RemoveOnDeath()
    return true
end