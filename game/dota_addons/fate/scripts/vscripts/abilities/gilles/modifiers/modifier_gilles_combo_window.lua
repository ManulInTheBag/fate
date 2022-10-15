modifier_gilles_combo_window = class({})

if IsServer() then
	function modifier_gilles_combo_window:OnCreated(args)
		self.caster = self:GetParent() 
		if(self.caster:GetAbilityByIndex(5):GetName() == "gilles_abyssal_contract") then
			self.caster:SwapAbilities("gille_larret_de_mort", "gilles_abyssal_contract", true, false)
		end
	end

	function modifier_gilles_combo_window:OnRefresh(args)
	end

	function modifier_gilles_combo_window:OnDestroy()
		if(self.caster:GetAbilityByIndex(5):GetName() == "gille_larret_de_mort") then
			self.caster:SwapAbilities("gille_larret_de_mort", "gilles_abyssal_contract", false, true)
		end
	end
end

function modifier_gilles_combo_window:IsHidden()
	return true 
end

function modifier_gilles_combo_window:RemoveOnDeath()
	return true
end