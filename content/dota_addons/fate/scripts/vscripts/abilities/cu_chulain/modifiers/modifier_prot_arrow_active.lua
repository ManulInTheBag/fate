modifier_prot_arrow_active = class({})

function modifier_prot_arrow_active:OnCreated(args)
	if IsServer() then
		self:StartIntervalThink(0.1)
	end
end

function modifier_prot_arrow_active:OnIntervalThink()
	local caster = self:GetParent()

	ProjectileManager:ProjectileDodge(caster)
end