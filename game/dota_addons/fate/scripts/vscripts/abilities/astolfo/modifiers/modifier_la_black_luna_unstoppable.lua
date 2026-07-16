modifier_la_black_luna_unstoppable = class({})

function modifier_la_black_luna_unstoppable:IsHidden() return true end
function modifier_la_black_luna_unstoppable:IsDebuff() return false end
function modifier_la_black_luna_unstoppable:IsPurgable() return false end
function modifier_la_black_luna_unstoppable:RemoveOnDeath() return true end

function modifier_la_black_luna_unstoppable:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end

function modifier_la_black_luna_unstoppable:CheckState()
	-- защита работает только пока на Астольфо висит эффект astolfo_casa_di_logistilla
	if not self:GetParent():HasModifier("modifier_casa_active_mr") then
		return {}
	end

	return { [MODIFIER_STATE_STUNNED] = false,
			 [MODIFIER_STATE_SILENCED] = false,
			 [MODIFIER_STATE_MUTED] = false }
end
