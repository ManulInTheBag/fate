gilles_combo_activator = class({})


function gilles_combo_activator:OnSpellStart()
	local caster = self:GetCaster()
		if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if  caster:FindAbilityByName("gilles_combo_new"):IsCooldownReady() and caster:FindAbilityByName("gilles_abyssal_contract"):IsCooldownReady() then
			if(caster:GetAbilityByIndex(5):GetName() == "gilles_abyssal_contract") then
				caster:SwapAbilities("gilles_combo_new", "gilles_abyssal_contract", true, false)
			end
		end
		Timers:CreateTimer(3, function()
			if(caster:GetAbilityByIndex(5):GetName() == "gilles_combo_new") then
				caster:SwapAbilities("gilles_combo_new", "gilles_abyssal_contract", false, true)
			end
		
		end)
	end
end
