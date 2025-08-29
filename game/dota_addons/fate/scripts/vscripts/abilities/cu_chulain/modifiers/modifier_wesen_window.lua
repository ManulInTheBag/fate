modifier_wesen_window = class({})

if IsServer() then
	function modifier_wesen_window:OnCreated(args)
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(5):GetName() == "cu_chulain_gae_bolg_jump" then
			caster:SwapAbilities("cu_chulain_gae_bolg_jump", "cu_new_combo", false, true)
		end
	end

	function modifier_wesen_window:OnRefresh(args)
		--Dont do anything
	end

	function modifier_wesen_window:OnDestroy()	
		local caster = self:GetParent()	
		if caster:GetAbilityByIndex(5):GetName() == "cu_new_combo" then
			caster:SwapAbilities("cu_chulain_gae_bolg_jump", "cu_new_combo", true, false)
		end
	end
end

function modifier_wesen_window:IsHidden()
	return true
end

function modifier_wesen_window:RemoveOnDeath()
	return true 
end