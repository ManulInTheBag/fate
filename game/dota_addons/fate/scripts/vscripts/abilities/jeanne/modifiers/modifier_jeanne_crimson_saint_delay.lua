modifier_jeanne_crimson_saint_delay = class({})

if IsServer() then
	function modifier_jeanne_crimson_saint_delay:OnCreated()
		local parent = self:GetParent()
	end
end

function modifier_jeanne_crimson_saint_delay:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_jeanne_crimson_saint_delay:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
	}
	return state
end

function modifier_jeanne_crimson_saint_delay:IsHidden()
  return true
end

function modifier_jeanne_crimson_saint_delay:IsDebuff()
  return false
end

function modifier_jeanne_crimson_saint_delay:RemoveOnDeath()
  return true
end
