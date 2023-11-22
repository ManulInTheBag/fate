modifier_lu_bu_armistice_movement = modifier_lu_bu_armistice_movement or class({})

function modifier_lu_bu_armistice_movement:IsHidden() return true end
function modifier_lu_bu_armistice_movement:IsPurgable() return false end
function modifier_lu_bu_armistice_movement:IsDebuff() return false end
function modifier_lu_bu_armistice_movement:IgnoreTenacity() return true end
function modifier_lu_bu_armistice_movement:IsMotionController() return true end
function modifier_lu_bu_armistice_movement:GetMotionControllerPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM end
function modifier_lu_bu_armistice_movement:RemoveOnDeath() return false end

--------------------------------------------------------------------------------

function modifier_lu_bu_armistice_movement:OnCreated()
	-- Ability properties
	caster = self:GetCaster()
	ability = self:GetAbility()

	-- Ability specials
	scepter_height = ability:GetSpecialValueFor("scepter_height")

	if IsServer() then
		blur_effect = ParticleManager:CreateParticle( self:GetParent().enchant_totem_leap_blur_pfx or "particles/units/heroes/hero_earthshaker/earthshaker_totem_leap_blur.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )

		-- Variables
		time_elapsed = 0
		leap_z = 0

		Timers:CreateTimer(FrameTime(), function()
			jump_time = ability:GetSpecialValueFor("duration")
			direction = (target_point - caster:GetAbsOrigin()):Normalized()
			local distance = (caster:GetAbsOrigin() - target_point):Length2D()
			jump_speed = distance / jump_time
			self:StartIntervalThink(FrameTime())
		end)
	end
end

function modifier_lu_bu_armistice_movement:OnIntervalThink()
	if IsServer() then
		-- Check for motion controllers
		if not self:CheckMotionControllers() then
			self:Destroy()
			return nil
		end

		-- Horizontal motion
		self:HorizontalMotion(self:GetParent(), FrameTime())

		-- Vertical motion
		self:VerticalMotion(self:GetParent(), FrameTime())
	end
end

function modifier_lu_bu_armistice_movement:EnchantTotemLand()
	if IsServer() then
		-- If the enchant_totem was already completed, do nothing
		if enchant_totem_land_commenced then
			return nil
		end

		if blur_effect then
			ParticleManager:DestroyParticle(blur_effect, false)
			ParticleManager:ReleaseParticleIndex(blur_effect)
		end

		-- Mark enchant_totem as completed
		enchant_totem_land_commenced = true

		self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_lu_bu_armistice", {duration = self:GetAbility():GetDuration()})
		EmitSoundOn("Hero_EarthShaker.Totem", self:GetParent())

		self:GetParent():SetUnitOnClearGround()
		ResolveNPCPositions(self:GetParent():GetAbsOrigin(), 150)

--		Timers:CreateTimer(FrameTime(), function()
--			ResolveNPCPositions(self:GetParent():GetAbsOrigin(), 150)
--		end)
	end
end

function modifier_lu_bu_armistice_movement:OnDestroy()
	if IsServer() then
		self:GetParent():SetUnitOnClearGround()
	end
end

--------------------------------------------------------------------------------

function modifier_lu_bu_armistice_movement:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
	}

	return funcs
end

-- add "ultimate_scepter" + "enchant_totem_leap_from_battle"
function modifier_lu_bu_armistice_movement:GetActivityTranslationModifiers()
	return "ultimate_scepter"
end

function modifier_lu_bu_armistice_movement:GetOverrideAnimation()
	return ACT_DOTA_OVERRIDE_ABILITY_2
end

function modifier_lu_bu_armistice_movement:GetEffectName()
	return "particles/units/heroes/hero_tiny/tiny_toss_blur.vpcf"
end

function modifier_lu_bu_armistice_movement:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

--------------------------------------------------------------------------------

function modifier_lu_bu_armistice_movement:HorizontalMotion( me, dt )
	if IsServer() then
		-- Check if we're still jumping
		time_elapsed = time_elapsed + dt
		if time_elapsed < jump_time then

			-- Go forward
			local new_location = caster:GetAbsOrigin() + direction * jump_speed * dt
			caster:SetAbsOrigin(new_location)
		else
			self:Destroy()
		end
	end
end

function modifier_lu_bu_armistice_movement:VerticalMotion( me, dt )
	if IsServer() then
		-- Check if we're still jumping
		if time_elapsed < jump_time then

			-- Check if we should be going up or down
			if time_elapsed <= jump_time / 2 then
				-- Going up
				leap_z = leap_z + 60

				caster:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(), caster) + Vector(0,0,leap_z))
			else
				-- Going down
				leap_z = leap_z - 60
				if leap_z > 0 then
					caster:SetAbsOrigin(GetGroundPosition(caster:GetAbsOrigin(), caster) + Vector(0,0,leap_z))
				end
			end
		end
	end
end