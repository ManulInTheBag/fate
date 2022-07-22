modifier_whitechapel_window = class({})

if IsServer() then
	function modifier_whitechapel_window:OnCreated(args)
		local hero = self:GetParent()
		hero:SwapAbilities("jtr_murderer_mist", "jtr_whitechapel_murderer", false, true) 
	end

	function modifier_whitechapel_window:OnRefresh(args)
	end

	function modifier_whitechapel_window:OnDestroy()	
		local hero = self:GetParent()

		hero:SwapAbilities("jtr_murderer_mist", "jtr_whitechapel_murderer", true, false) 
	end
end

function modifier_whitechapel_window:IsHidden()
	return true 
end

function modifier_whitechapel_window:RemoveOnDeath()
	return true
end