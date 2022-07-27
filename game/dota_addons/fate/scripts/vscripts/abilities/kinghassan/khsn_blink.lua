LinkLuaModifier("modifier_khsn_blink_slow", "abilities/kinghassan/khsn_blink", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_blink_checker", "abilities/kinghassan/khsn_blink", LUA_MODIFIER_MOTION_NONE)

khsn_blink = class({})

function khsn_blink:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("duration")

	local position = target:GetAbsOrigin() - target:GetForwardVector()*150

	if IsSpellBlocked(target) then return end

	local slashFx = ParticleManager:CreateParticle("particles/kinghassan/khsn_trail_scepter.vpcf", PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( slashFx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl( slashFx, 1, position)

	local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))
    ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))

	FindClearSpaceForUnit(caster, position, true)
	caster:FaceTowards(target:GetAbsOrigin())
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		target:AddNewModifier(caster, self, "modifier_khsn_blink_slow", {duration = duration})
		if caster.BoundaryAcquired then
			target:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.2})
		end
		caster:AddNewModifier(caster, self, "modifier_khsn_blink_checker", {duration = duration})
		caster:PerformAttack( target, true, true, true, true, false, false, false )
	end
end

modifier_khsn_blink_slow = class({})

function modifier_khsn_blink_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
				--MODIFIER_PROPERTY_DISABLE_TURNING
				}
end

function modifier_khsn_blink_slow:IsHidden() return false end
function modifier_khsn_blink_slow:RemoveOnDeath() return true end
function modifier_khsn_blink_slow:IsDebuff() return true end

function modifier_khsn_blink_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("ms_slow")
end

--[[function modifier_khsn_blink_slow:GetModifierDisableTurning()
	return 1
end]]

function modifier_khsn_blink_slow:GetModifierTurnRate_Percentage()
	return -1*self:GetAbility():GetSpecialValueFor("turn_rate")
end

modifier_khsn_blink_checker = class({})

function modifier_khsn_blink_checker:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE}
end

function modifier_khsn_blink_checker:IsHidden() return false end
function modifier_khsn_blink_checker:IsDebuff() return false end

function modifier_khsn_blink_checker:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("dmg_bonus")
end

function modifier_khsn_blink_checker:GetModifierAttackSpeedBonus_Constant()
	return (self:GetParent().BoundaryAcquired and self:GetAbility():GetSpecialValueFor("attr_as") or 0)
end