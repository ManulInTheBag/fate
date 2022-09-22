modifier_windblade_hit_marker = class({})

if IsServer() then 
	function modifier_windblade_hit_marker:OnCreated(args)
		self:SetStackCount(args.Stacks or 1)
	end

	function modifier_windblade_hit_marker:OnRefresh(args)
		self:SetStackCount(self:GetStackCount() + 1)
	end
end

function modifier_windblade_hit_marker:IsHidden()
	return true
end

function modifier_windblade_hit_marker:RemoveOnDeath()
	return true
end