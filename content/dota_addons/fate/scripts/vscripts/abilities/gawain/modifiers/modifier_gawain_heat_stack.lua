modifier_gawain_heat_stack = class({})

if IsServer() then
	function modifier_gawain_heat_stack:OnCreated(args)
		self:SetStackCount(args.Stacks or 1)
	end

	function modifier_gawain_heat_stack:OnRefresh(args)
		args.Stacks = self:GetStackCount() + 1
		self:OnCreated(args)
	end
end

function modifier_gawain_heat_stack:IsHidden()
	return true
end

function modifier_gawain_heat_stack:IsPurgable()
	return false
end

function modifier_gawain_heat_stack:IsDebuff()
	return true
end

function modifier_gawain_heat_stack:RemoveOnDeath()
	return true
end

function modifier_gawain_heat_stack:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end