modifier_holy_mother_buff = class({})

function modifier_holy_mother_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_AGILITY_BONUS }
end

if IsServer() then 
	function modifier_holy_mother_buff:OnCreated(args)
		self.AgiPerStack = args.AgiPerStack
		self:SetStackCount((args.Stacks or 0) + 1) 

		CustomNetTables:SetTableValue("sync","jtr_holy_mother", { agi_per_stack = self.AgiPerStack })
	end

	function modifier_holy_mother_buff:OnRefresh(args)
		args.Stacks = self:GetStackCount()
		self:OnCreated(args)
	end

	function modifier_holy_mother_buff:ReduceStack()
		self:SetStackCount(math.max(0, self:GetStackCount() - 1))
	end
end

function modifier_holy_mother_buff:GetModifierBonusStats_Agility()
	local agi_per_stack = 0

	if IsServer() then
		agi_per_stack = self.AgiPerStack
	else
		agi_per_stack = CustomNetTables:GetTableValue("sync","jtr_holy_mother").agi_per_stack or 0        
	end
	
	return agi_per_stack * self:GetStackCount()
end


function modifier_holy_mother_buff:IsDebuff()
	return false 
end

function modifier_holy_mother_buff:RemoveOnDeath()
	return true 
end