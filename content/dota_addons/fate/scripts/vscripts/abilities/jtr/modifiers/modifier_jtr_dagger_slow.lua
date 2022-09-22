modifier_jtr_dagger_slow = class({})

if IsServer() then
	function modifier_jtr_dagger_slow:OnCreated(args)
	
		self.SlowPct = args.SlowPct
		CustomNetTables:SetTableValue("sync","jtr_dagger_slow", { slow = self.SlowPct})
	end

	function modifier_jtr_dagger_slow:OnRefresh(args)
		self:OnCreated(args)
	end
end


function modifier_jtr_dagger_slow:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then        
    	return self.SlowPct
    elseif IsClient() then
        local slow = CustomNetTables:GetTableValue("sync","jtr_dagger_slow").slow
        return slow 
    end
end

function modifier_jtr_dagger_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_jtr_dagger_slow:GetAttributes()
  return MODIFIER_ATTRIBUTE_NONE
end

function modifier_jtr_dagger_slow:IsDebuff()
	return true 
end

function modifier_jtr_dagger_slow:RemoveOnDeath()
	return true 
end

function modifier_jtr_dagger_slow:GetTexture()
    return "custom/jtr/dagger_throw"
end

function modifier_jtr_dagger_slow:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end