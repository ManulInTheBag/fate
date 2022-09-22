modifier_barrage_debuff = class({})

if IsServer() then
	function modifier_barrage_debuff:OnCreated(args)
		self:SetStackCount(math.min(args.Charges or 1, 10))		

	end

	function modifier_barrage_debuff:OnRefresh(args)		
		args.Charges = self:GetStackCount() + 1
		self:OnCreated(args)
	end
end

function modifier_barrage_debuff:IsHidden()
	return true
end

function modifier_barrage_debuff:RemoveOnDeath()
	return true
end