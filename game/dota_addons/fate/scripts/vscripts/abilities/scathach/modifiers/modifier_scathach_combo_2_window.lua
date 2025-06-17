modifier_scathach_combo_2_window = class({})

if IsServer() then
	function modifier_scathach_combo_2_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("scathach_gae_bolg_jump", "scathach_red_creed_combo", false, true)
	end

	function modifier_scathach_combo_2_window:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("scathach_gae_bolg_jump", "scathach_red_creed_combo", true, false)
	end
end

function modifier_scathach_combo_2_window:IsHidden()
	return true
end

function modifier_scathach_combo_2_window:RemoveOnDeath()
	return true 
end