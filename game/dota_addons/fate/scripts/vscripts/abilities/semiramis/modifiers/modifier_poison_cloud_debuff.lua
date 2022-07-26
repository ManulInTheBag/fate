modifier_poison_cloud_debuff = class({})

if IsServer() then
	function modifier_poison_cloud_debuff:OnCreated(args)
		self:SetStackCount(args.Stacks or 1)
		self.ResistReduc = self:GetStackCount() * args.ResistReduc

		CustomNetTables:SetTableValue("sync","poison_cloud_resist_" .. self:GetParent():GetName(), { resist_reduc = self.ResistReduc})
	end

	function modifier_poison_cloud_debuff:OnRefresh(args)
		args.Stacks = self:GetStackCount()
		self:OnCreated(args)
	end
end

function modifier_poison_cloud_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end

function modifier_poison_cloud_debuff:GetModifierMagicalResistanceBonus()
	if IsServer() then
		return self.ResistReduc
	elseif IsClient() then
		local resist_reduc = CustomNetTables:GetTableValue("sync","poison_cloud_resist_" .. self:GetParent():GetName()).resist_reduc
        return resist_reduc 
	end
end

function modifier_poison_cloud_debuff:IsDebuff()
	return true 
end

function modifier_poison_cloud_debuff:RemoveOnDeath()
	return true
end