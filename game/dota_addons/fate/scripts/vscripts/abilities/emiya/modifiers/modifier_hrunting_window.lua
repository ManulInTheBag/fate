modifier_hrunting_window = class({})

if IsServer() then
	function modifier_hrunting_window:OnCreated(args)
		local hero = self:GetParent()

		--[[local tStandardAbilities = {
	        "emiya_kanshou_byakuya",
	        "emiya_broken_phantasm",
	        "emiya_crane_wings",
	        "emiya_rho_aias",
	        "emiya_hrunting",
	        "emiya_unlimited_bladeworks",
	        "attribute_bonus_custom"
	    }

	    UpdateAbilityLayout(caster, tUBWAbilities)]]
		hero:SwapAbilities("emiya_clairvoyance", "emiya_hrunting_2", false, true) 
	end

	function modifier_hrunting_window:OnRefresh(args)
	end

	function modifier_hrunting_window:OnDestroy()	
		local hero = self:GetParent()
		local ubw = hero:FindAbilityByName("emiya_unlimited_bladeworks")

		ubw:SwitchAbilities(hero:HasModifier("modifier_unlimited_bladeworks"))


		--hero:SwapAbilities("emiya_hrunting", "emiya_clairvoyance", false, true)
	end
end

function modifier_hrunting_window:IsHidden()
	return true 
end

function modifier_hrunting_window:RemoveOnDeath()
	return true
end