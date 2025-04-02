modifier_protection_from_arrows_active = class({})

if IsServer() then
	function modifier_protection_from_arrows_active:OnCreated(args)
		self:StartIntervalThink(0.033)
		self:GetParent():EmitSound("cu_chulain_protection_start")
	end

	function modifier_protection_from_arrows_active:OnIntervalThink()
		local caster = self:GetParent()

		ProjectileManager:ProjectileDodge(caster)
	end

	function modifier_protection_from_arrows_active:OnDestroy()
		self:GetParent():EmitSound("cu_chulain_protection_end")
	
	end
end


function modifier_protection_from_arrows_active:GetEffectName()
	return "particles/items4_fx/cyclonic_barrier.vpcf"
end

function modifier_protection_from_arrows_active:GetEffectAttachType()
	return PATTACH_CUSTOMORIGIN_FOLLOW
end