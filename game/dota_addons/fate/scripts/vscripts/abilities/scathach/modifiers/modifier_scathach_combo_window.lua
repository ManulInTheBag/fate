modifier_scathach_combo_window = class({})

if IsServer() then
	function modifier_scathach_combo_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("scathach_wisdom_of_dun_scaith", "scathach_combo_gate_of_sky", false, true)
	end

	function modifier_scathach_combo_window:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("scathach_wisdom_of_dun_scaith", "scathach_combo_gate_of_sky", true, false)
	end
end

function modifier_scathach_combo_window:IsHidden()
	return true
end

function modifier_scathach_combo_window:RemoveOnDeath()
	return true 
end