modifier_protection_from_arrows_active = class({})

if IsServer() then
	function modifier_protection_from_arrows_active:OnCreated(args)
		self:StartIntervalThink(0.033)
	end

	function modifier_protection_from_arrows_active:OnIntervalThink()
		local caster = self:GetParent()

		ProjectileManager:ProjectileDodge(caster)
	end
end