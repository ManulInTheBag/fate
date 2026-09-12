modifier_protection_from_arrows_active = class({})

if IsServer() then
	function modifier_protection_from_arrows_active:OnCreated(args)
		self:StartIntervalThink(0.033)
		-- silent = 1: without start/end sounds (Rasputin's Dash applies this same
		-- modifier for projectile dodging and already has a sound of its own)
		self.silent = args and args.silent == 1
		if not self.silent then
			self:GetParent():EmitSound("cu_chulain_protection_start")
		end
	end

	function modifier_protection_from_arrows_active:OnIntervalThink()
		local caster = self:GetParent()

		ProjectileManager:ProjectileDodge(caster)
	end

	function modifier_protection_from_arrows_active:OnDestroy()
		if self.silent then return end
		self:GetParent():EmitSound("cu_chulain_protection_end")
	
	end
end


function modifier_protection_from_arrows_active:GetEffectName()
	return "particles/items4_fx/cyclonic_barrier.vpcf"
end

function modifier_protection_from_arrows_active:GetEffectAttachType()
	return PATTACH_CUSTOMORIGIN_FOLLOW
end