modifier_tiger_strike_slow = class({})

function modifier_tiger_strike_slow:OnCreated(keys)
	self.SlowPct = keys.SlowPct
end

function modifier_tiger_strike_slow:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then
        CustomNetTables:SetTableValue("sync","tiger_strike_slow", {slow = self.SlowPct})
    	return self.SlowPct
    elseif IsClient() then
        local tiger_strike_slow = CustomNetTables:GetTableValue("sync","tiger_strike_slow").slow
        return tiger_strike_slow 
    end
end

function modifier_tiger_strike_slow:DeclareFunctions()
	local funcs = {	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
	return funcs
end

function modifier_tiger_strike_slow:IsHidden()
	return false
end

function modifier_tiger_strike_slow:IsDebuff()
	return true
end

function modifier_tiger_strike_slow:RemoveOnDeath()
	return true
end

function modifier_tiger_strike_slow:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_tiger_strike_slow:GetTexture()
	return "custom/lishuwen_fierce_tiger_strike"
end
