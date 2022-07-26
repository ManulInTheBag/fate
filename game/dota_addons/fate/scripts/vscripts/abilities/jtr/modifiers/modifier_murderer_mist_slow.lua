modifier_murderer_mist_slow = class({})

if IsServer() then
	function modifier_murderer_mist_slow:OnCreated(args)	
		self.SlowPct = self:GetAbility():GetSpecialValueFor("slow_pct")
		CustomNetTables:SetTableValue("sync","jtr_backstab_slow", {slow = self.SlowPct})
	end

	function modifier_murderer_mist_slow:OnRefresh(args)
		self:OnCreated(args)
	end
end

function modifier_murderer_mist_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_murderer_mist_slow:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then        
    	return self.SlowPct
    elseif IsClient() then
        local slow = CustomNetTables:GetTableValue("sync","jtr_backstab_slow").slow
        return slow 
    end
end

function modifier_murderer_mist_slow:GetAttributes()
  return MODIFIER_ATTRIBUTE_NONE
end

function modifier_murderer_mist_slow:IsDebuff()
	return true 
end

function modifier_murderer_mist_slow:RemoveOnDeath()
	return true 
end

function modifier_murderer_mist_slow:IsHidden()
	return false
end