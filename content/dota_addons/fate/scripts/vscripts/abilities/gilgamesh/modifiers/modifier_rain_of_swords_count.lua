modifier_rain_of_swords_count = class({})

if IsServer() then 
	function modifier_rain_of_swords_count:OnCreated(args)
		self:SetStackCount(args.Stacks or 1)
	end

	function modifier_rain_of_swords_count:OnRefresh(args)
		self:SetStackCount(math.min(self:GetStackCount() + 1, 5))
	end
end

function modifier_rain_of_swords_count:IsHidden()
	return false
end

function modifier_rain_of_swords_count:RemoveOnDeath()
	return true
end