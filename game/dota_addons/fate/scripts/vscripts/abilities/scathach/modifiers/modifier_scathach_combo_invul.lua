modifier_scathach_combo_invul = class({})

if IsServer() then
	function modifier_scathach_combo_invul:OnCreated()
		local parent = self:GetParent()
	end
end

function modifier_scathach_combo_invul:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_scathach_combo_invul:CheckState()
	local state = {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
	return state
end

function modifier_scathach_combo_invul:IsHidden()
  return true
end

function modifier_scathach_combo_invul:IsDebuff()
  return false
end

function modifier_scathach_combo_invul:RemoveOnDeath()
  return true
end
