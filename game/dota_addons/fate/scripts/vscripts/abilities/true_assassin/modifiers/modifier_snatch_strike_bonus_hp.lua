modifier_snatch_strike_bonus_hp = class({})

function modifier_snatch_strike_bonus_hp:DeclareFunctions()
	return { MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS }
end

function modifier_snatch_strike_bonus_hp:OnCreated(args)
	if IsServer() then
		self.BonusHealth = args.BonusHealth
		CustomNetTables:SetTableValue("sync","snatch_strike_buff", { hp_bonus = args.BonusHealth })
	end
end

function modifier_snatch_strike_bonus_hp:GetModifierExtraHealthBonus()
	if IsServer() then       
        return self.BonusHealth
    elseif IsClient() then
        local hp_bonus = CustomNetTables:GetTableValue("sync","snatch_strike_buff").hp_bonus
        return hp_bonus 
    end
end

function modifier_snatch_strike_bonus_hp:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_snatch_strike_bonus_hp:IsPurgable()
    return false
end

function modifier_snatch_strike_bonus_hp:IsDebuff()
    return false
end

function modifier_snatch_strike_bonus_hp:RemoveOnDeath()
    return true
end

function modifier_snatch_strike_bonus_hp:GetTexture()
    return "custom/true_assassin_snatch_strike"
end