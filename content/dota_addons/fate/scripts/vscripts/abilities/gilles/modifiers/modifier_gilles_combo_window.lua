modifier_gilles_combo_window = class({})

if IsServer() then
	function modifier_gilles_combo_window:OnCreated(args)
		self:GetParent():SwapAbilities("gilles_abyssal_contract", "gille_larret_de_mort", false, true) 
	end

	function modifier_gilles_combo_window:OnRefresh(args)
	end

	function modifier_gilles_combo_window:OnDestroy()
		self:GetParent():SwapAbilities("gille_larret_de_mort", "gilles_abyssal_contract", false, true)
	end
end

function modifier_gilles_combo_window:IsHidden()
	return true 
end

function modifier_gilles_combo_window:RemoveOnDeath()
	return true
end