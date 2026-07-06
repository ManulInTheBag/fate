modifier_everdistant_utopia = class({})

function modifier_everdistant_utopia:DeclareFunctions()
	return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT }
end

if IsServer() then
	function modifier_everdistant_utopia:OnCreated(args)
		self.Regen = args.Regen
		CustomNetTables:SetTableValue("sync","everdistant_utopia", { health_regen = self.Regen })

		self:StartIntervalThink(0.033)
	end

	function modifier_everdistant_utopia:OnIntervalThink()
		ProjectileManager:ProjectileDodge(self:GetParent())
	end
end

function modifier_everdistant_utopia:GetModifierConstantHealthRegen()
	if IsServer() then
		return self.Regen
	elseif IsClient() then
		local health_regen = CustomNetTables:GetTableValue("sync","everdistant_utopia").health_regen
        return health_regen 
	end
end

function modifier_everdistant_utopia:IsHidden()
	return true 
end