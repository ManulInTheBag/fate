modifier_ganryu_armor_shred = class({})

function modifier_ganryu_armor_shred:DeclareFunctions()
	local func = { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
	return func
end

function modifier_ganryu_armor_shred:OnCreated(args)
	if IsServer() then
		self:SetStackCount(args.Stacks or 1)

		local hero_armor = self:GetParent():GetPhysicalArmorValue(false) + ((self.Reduction or 0) * -1)
		self.Reduction = (0.27 * self:GetStackCount()) * hero_armor * -1

		CustomNetTables:SetTableValue("sync","ganryu_armor_shred", { armor_shred = self.Reduction })
	end
end

function modifier_ganryu_armor_shred:OnRefresh(args)
	if IsServer() then
		args.Stacks = self:GetStackCount() + 1
		self:OnCreated(args)
	end
end

function modifier_ganryu_armor_shred:GetModifierPhysicalArmorBonus() 
    if IsServer() then
		return self.Reduction
	elseif IsClient() then
		local armor_shred = CustomNetTables:GetTableValue("sync","ganryu_armor_shred").armor_shred
        return armor_shred 
	end
end

function modifier_ganryu_armor_shred:IsDebuff()
    return true
end

function modifier_ganryu_armor_shred:RemoveOnDeath()
    return true
end

function modifier_ganryu_armor_shred:IsHidden()
    return true
end
-----------------------------------------------------------------------------------
