modifier_a_scroll = class({})

function modifier_a_scroll:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, 
			 MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end

function modifier_a_scroll:OnCreated(args)
	self.MagicResistance = args.MagicResistance
	self.Armor = args.Armor

	if IsServer() then
		CustomNetTables:SetTableValue("sync","a_scroll_buff" .. self:GetParent():GetName(), { magic_resist = self.MagicResistance,
																armor = self.Armor })
	end
end

function modifier_a_scroll:OnRefresh(args)
	self:OnCreated(args)
end

function modifier_a_scroll:GetModifierMagicalResistanceBonus()
	if IsServer() then        
    	return self.MagicResistance
    elseif IsClient() then
        local magic_resist = CustomNetTables:GetTableValue("sync","a_scroll_buff" .. self:GetParent():GetName()).magic_resist
        return magic_resist 
    end
end

function modifier_a_scroll:GetModifierPhysicalArmorBonus()
	if IsServer() then        
    	return self.Armor
    elseif IsClient() then
        local armor = CustomNetTables:GetTableValue("sync","a_scroll_buff" .. self:GetParent():GetName()).armor
        return armor 
    end
end

function modifier_a_scroll:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_a_scroll:IsDebuff()
	return false 
end

function modifier_a_scroll:RemoveOnDeath()
	return true 
end

function modifier_a_scroll:GetEffectName()
	return "particles/units/heroes/hero_oracle/oracle_fatesedict.vpcf"
end

function modifier_a_scroll:GetTexture()
    return "custom/a_scroll"
end

function modifier_a_scroll:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end