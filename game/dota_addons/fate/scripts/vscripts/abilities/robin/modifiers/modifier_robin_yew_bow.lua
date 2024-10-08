-----------------------------
--    Modifier: Robin Yew Bow    --
-----------------------------

modifier_robin_yew_bow = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_robin_yew_bow:IsHidden()
	return false
end

function modifier_robin_yew_bow:IsDebuff()
	return true
end

function modifier_robin_yew_bow:IsPurgable()
	return false
end

function modifier_robin_yew_bow:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_robin_yew_bow:OnCreated( kv )
	if IsServer() then
		self:PlayEffects()
	end
end

function modifier_robin_yew_bow:OnRefresh( kv )
	
end

function modifier_robin_yew_bow:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_robin_yew_bow:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}

	return funcs
end
function modifier_robin_yew_bow:GetModifierProvidesFOWVision()
	return true
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_robin_yew_bow:CheckState()
	local state = {
		[MODIFIER_STATE_INVISIBLE] = false,
		[MODIFIER_STATE_PROVIDES_VISION] = true,
	}

	return state
end

--------------------------------------------------------------------------------
-- Graphics & Animations
-- function modifier_robin_yew_bow:GetEffectName()
-- 	return "particles/string/here.vpcf"
-- end

-- function modifier_robin_yew_bow:GetEffectAttachType()
-- 	return PATTACH_ABSORIGIN_FOLLOW
-- end

function modifier_robin_yew_bow:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/custom/robin/robin_crosshair_lockon.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticleForTeam( particle_cast, PATTACH_OVERHEAD_FOLLOW, self:GetParent(), self:GetCaster():GetTeamNumber() )

	-- buff particle
	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		true
	)
end