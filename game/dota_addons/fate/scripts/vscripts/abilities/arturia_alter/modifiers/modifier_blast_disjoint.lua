modifier_blast_disjoint = class({})

if IsServer() then
	function modifier_blast_disjoint:OnCreated(args)
		self:StartIntervalThink(0.1)
	end

	function modifier_blast_disjoint:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_blast_disjoint:OnIntervalThink()
		local caster = self:GetParent()

		ProjectileManager:ProjectileDodge(caster)
	end
end

function modifier_blast_disjoint:IsHidden()
	return true 
end

function modifier_blast_disjoint:RemoveOnDeath()
	return true
end

function modifier_blast_disjoint:GetAttributes()
	return MODIFIER_ATTRIBUTE_NONE
end