modifier_tamamo_combo_window = class({})

if IsServer() then
	function modifier_tamamo_combo_window:OnCreated(args)
		local hero = self:GetParent()
		hero:SwapAbilities("tamamo_amaterasu", "tamamo_combo", false, true) 
	end

	function modifier_tamamo_combo_window:OnRefresh(args)
	end

	function modifier_tamamo_combo_window:OnDestroy()	
		local hero = self:GetParent()
		hero:SwapAbilities("tamamo_amaterasu", "tamamo_combo", true, false) 
	end
end

function modifier_tamamo_combo_window:IsHidden()
	return true 
end

function modifier_tamamo_combo_window:RemoveOnDeath()
	return true
end