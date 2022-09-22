modifier_eternal_flame_shred = class({})

function modifier_eternal_flame_shred:DeclareFunctions()
	local func = { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
	return func
end

function modifier_eternal_flame_shred:OnCreated(args)
	if IsServer() then
		self:SetStackCount(math.min(args.Stacks or 1, 10))

		local hero_armor = self:GetParent():GetPhysicalArmorValue(false) + ((self.Reduction or 0) * -1)
		self.Reduction = (0.1 * self:GetStackCount()) * hero_armor * -1

		CustomNetTables:SetTableValue("sync","eternal_flame_shred", { armor_shred = self.Reduction })
	end
end

function modifier_eternal_flame_shred:OnRefresh(args)
	if IsServer() then
		args.Stacks = self:GetStackCount() + 1
		self:OnCreated(args)
	end
end

function modifier_eternal_flame_shred:GetModifierPhysicalArmorBonus() 
    if IsServer() then
		return self.Reduction
	elseif IsClient() then
		local armor_shred = CustomNetTables:GetTableValue("sync","eternal_flame_shred").armor_shred
        return armor_shred 
	end
end

function modifier_eternal_flame_shred:IsDebuff()
    return true
end

function modifier_eternal_flame_shred:RemoveOnDeath()
    return true
end

function modifier_eternal_flame_shred:IsHidden()
    return false
end