modifier_la_pucelle_slow = class({})

function modifier_la_pucelle_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

if IsServer() then
	function modifier_la_pucelle_slow:OnCreated(args)
		self.SlowAmt = args.SlowAmt

		CustomNetTables:SetTableValue("sync","la_pucelle_slow", { slow = self.SlowAmt })
	end

	function modifier_la_pucelle_slow:OnRefresh(args)
		self:OnCreated(args)
	end
end

function modifier_la_pucelle_slow:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then
		return self.SlowAmt
	elseif IsClient() then
		local slow = CustomNetTables:GetTableValue("sync","la_pucelle_slow").slow
		return slow 
	end
end


function modifier_la_pucelle_slow:IsDebuff()
	return true 
end

function modifier_la_pucelle_slow:RemoveOnDeath()
	return true
end