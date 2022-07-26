modifier_hrunting_window = class({})

if IsServer() then
	function modifier_hrunting_window:OnCreated(args)
		local hero = self:GetParent()
		hero:SwapAbilities("emiya_clairvoyance", "emiya_hrunting", false, true) 
	end

	function modifier_hrunting_window:OnDestroy()	
		local hero = self:GetParent()
		hero:SwapAbilities("emiya_hrunting", "emiya_clairvoyance", false, true)
	end
end

function modifier_hrunting_window:IsHidden()
	return true 
end

function modifier_hrunting_window:RemoveOnDeath()
	return true
end