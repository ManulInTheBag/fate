modifier_karna_combo_window = class({})

if IsServer() then
	function modifier_karna_combo_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("karna_vasavi_shakti", "karna_combo_vasavi", false, true)
	end

	function modifier_karna_combo_window:OnDestroy()
		local caster = self:GetParent()
		caster:SwapAbilities("karna_vasavi_shakti", "karna_combo_vasavi", true, false)
	end
end

function modifier_karna_combo_window:IsHidden()
	return true 
end