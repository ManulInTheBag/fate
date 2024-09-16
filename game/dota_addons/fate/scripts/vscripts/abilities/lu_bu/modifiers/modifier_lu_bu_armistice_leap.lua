--------------------------------------------------------------------------------
-- This still needs a LOT of ironing out (w.r.t proper vertical orientation and proper movement interrupt logic), but at its core it's passable
modifier_lu_bu_armistice_leap	= class({})

function modifier_lu_bu_armistice_leap:IsHidden()	return true end

function modifier_lu_bu_armistice_leap:OnCreated( params )
	if not IsServer() then return end

	destination	= Vector(params.x, params.y, params.z)
	vector			= (destination - self:GetParent():GetAbsOrigin())
	direction		= vector:Normalized()
	speed			= vector:Length2D() / self:GetDuration()

	if self:ApplyVerticalMotionController() == false then 
		self:Destroy()
	end
	if self:ApplyHorizontalMotionController() == false then 
		self:Destroy()
	end
	
	interval	= FrameTime()
	
	self:StartIntervalThink(interval)
end

function modifier_lu_bu_armistice_leap:OnIntervalThink()
	local z_axis = (-1) * self:GetElapsedTime() * (self:GetElapsedTime() - self:GetDuration()) * 562 * 5
	
	-- self:GetParent():SetOrigin( GetGroundPosition(self:GetParent():GetOrigin(), nil) + Vector(0, 0, z_axis) )

	-- -- Okay so IDK how to check if Earthshaker is stunned to interrupt this, without catching the stun that this modifier itself provides...
	-- if self:GetParent():IsStunned() or self:GetParent():IsRooted() then
		-- aftershock_interrupt = true
		-- self:Destroy()
		-- return
	-- end

	self:GetParent():SetOrigin( (self:GetParent():GetOrigin() * Vector(1, 1, 0)) + (((direction * speed * interval) * Vector(1, 1, 0)) + (Vector(0, 0, GetGroundHeight(self:GetParent():GetOrigin(), nil)) + Vector(0, 0, z_axis) )))
end

function modifier_lu_bu_armistice_leap:OnDestroy( kv )
	if not IsServer() then return end
	
	self:GetParent():InterruptMotionControllers( true )
	
	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_lu_bu_armistice", {duration = self:GetAbility():GetDuration()})
end

function modifier_lu_bu_armistice_leap:UpdateHorizontalMotion( me, dt )
	-- self:GetParent():SetOrigin( self:GetParent():GetOrigin() + (direction * speed * dt) )
end

function modifier_lu_bu_armistice_leap:OnHorizontalMotionInterrupted()
	if IsServer() and self:GetRemainingTime() > 0 then
		aftershock_interrupt = true
	end
end

function modifier_lu_bu_armistice_leap:OnVerticalMotionInterrupted()
	if IsServer() then
		aftershock_interrupt = true
		self:Destroy()
	end
end

-- "The leap duration is always the same, so the speed adapts based on the targeted distance. The leap height is always 562 range."
-- I'm forgetting all my parabola math, but multiplying height by 4 here sets it as the max height at mid-point; there's obviously a formula for this
function modifier_lu_bu_armistice_leap:UpdateVerticalMotion( me, dt )
	-- local z_axis = (-1) * self:GetElapsedTime() * (self:GetElapsedTime() - self:GetDuration()) * 562 * 4
	
	-- self:GetParent():SetOrigin( GetGroundPosition(self:GetParent():GetOrigin(), nil) + Vector(0, 0, z_axis) )
end

function modifier_lu_bu_armistice_leap:OnVerticalMotionInterrupted()
	-- if IsServer() then
		-- self:Destroy()
	-- end
end

function modifier_lu_bu_armistice_leap:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
	}

	return funcs
end

-- add "ultimate_scepter" + "enchant_totem_leap_from_battle"
function modifier_lu_bu_armistice_leap:GetActivityTranslationModifiers()
	return "ultimate_scepter"
end

function modifier_lu_bu_armistice_leap:GetOverrideAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end

function modifier_lu_bu_armistice_leap:GetEffectName()
	return "particles/units/heroes/hero_tiny/tiny_toss_blur.vpcf"
end

function modifier_lu_bu_armistice_leap:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true
	}
end