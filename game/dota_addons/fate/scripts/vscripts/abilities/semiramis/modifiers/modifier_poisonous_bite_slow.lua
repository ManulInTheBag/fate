modifier_poisonous_bite_slow = class({})

if IsServer() then
	function modifier_poisonous_bite_slow:OnCreated(args)
		self.Slow = args.Slow
		self.SlowInc = args.SlowInc
		CustomNetTables:SetTableValue("sync","semiramis_poisonous_bite", { slow_pct = self.Slow })

		self:StartIntervalThink(0.25)
	end

	function modifier_poisonous_bite_slow:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_poisonous_bite_slow:OnIntervalThink()
		self.Slow = self.Slow + self.SlowInc
		CustomNetTables:SetTableValue("sync","semiramis_poisonous_bite", { slow_pct = self.Slow })
	end
end

function modifier_poisonous_bite_slow:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then		
		return self.Slow
	elseif IsClient() then
		local slow_pct = CustomNetTables:GetTableValue("sync","semiramis_poisonous_bite").slow_pct
		return slow_pct
	end
end

function modifier_poisonous_bite_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_poisonous_bite_slow:IsDebuff()
	return true
end

function modifier_poisonous_bite_slow:RemoveOnDeath()
	return true
end