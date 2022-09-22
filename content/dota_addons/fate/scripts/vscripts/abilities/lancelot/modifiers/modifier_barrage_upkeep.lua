modifier_barrage_upkeep = class({})

if IsServer() then
	function modifier_barrage_upkeep:OnCreated(args)
		self:SetStackCount(math.min(args.Charges or 1, 4))		

	end

	function modifier_barrage_upkeep:OnRefresh(args)		
		args.Charges = self:GetStackCount() + 1
		self:OnCreated(args)
	end
end

function modifier_barrage_upkeep:IsHidden()
	return true
end

function modifier_barrage_upkeep:RemoveOnDeath()
	return true
end