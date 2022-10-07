LinkLuaModifier("modifier_ryougi_backflip", "abilities/ryougi/ryougi_backflip", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ryougi_backflip_2", "abilities/ryougi/ryougi_backflip", LUA_MODIFIER_MOTION_NONE)

ryougi_backflip = class({})

function ryougi_backflip:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_ryougi_backflip_2", {duration = 0.11})
	StartAnimation(caster, {duration=1.20, activity=ACT_DOTA_CAST_ABILITY_4, rate=1})
	Timers:CreateTimer(0.1, function()
		if caster:IsStunned() then return end

		ProjectileManager:ProjectileDodge(caster)
		--local target = self:GetCursorPosition()

		local origin = caster:GetAbsOrigin()
		local direction = -1*caster:GetForwardVector()
		local range = self:GetSpecialValueFor("range")

		--[[if (Vector(target.x, target.y, 0) == Vector(origin.x, origin.y, 0)) then
			direction = caster:GetForwardVector()
		end]]

		caster:AddNewModifier(caster, self, "modifier_ryougi_backflip", {duration = 0.7})
		Timers:CreateTimer(0, function()
			if not caster:IsAlive() then
				return
			end
			if not caster:HasModifier("modifier_ryougi_backflip") then
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
				return
			end

			local origin_t = caster:GetAbsOrigin()
			--caster:SetForwardVector(direction)
			caster:SetAbsOrigin(GetGroundPosition(origin_t + direction*range/0.7*0.033, caster))
			return 0.033
		end)
	end)
end

modifier_ryougi_backflip = class({})

function modifier_ryougi_backflip:CheckState()
	return { [MODIFIER_STATE_INVULNERABLE] = true,
			 [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			 [MODIFIER_STATE_UNSELECTABLE] = true,
			 [MODIFIER_STATE_STUNNED] = true}
end

function modifier_ryougi_backflip:IsHidden() return true end

modifier_ryougi_backflip_2 = class({})

function modifier_ryougi_backflip_2:CheckState()
	return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_DISARMED] = true,
			 [MODIFIER_STATE_SILENCED] = true,
			 [MODIFIER_STATE_MUTED] = true,
			 [MODIFIER_STATE_ROOTED] = true}
end

function modifier_ryougi_backflip_2:IsHidden() return true end

function modifier_ryougi_backflip_2:DeclareFunctions()
	return { MODIFIER_PROPERTY_DISABLE_TURNING }
end

function modifier_ryougi_backflip_2:GetModifierDisableTurning()
	return 1
end