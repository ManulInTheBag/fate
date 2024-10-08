modifier_robin_yew_bow_combo_window = class({})

if IsServer() then
	function modifier_robin_yew_bow_combo_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("robin_yew_bow", "robin_yew_tree_combo", false, true)
	end

	function modifier_robin_yew_bow_combo_window:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("robin_yew_bow", "robin_yew_tree_combo", true, false)
	end
end

function modifier_robin_yew_bow_combo_window:IsHidden()
	return true
end

function modifier_robin_yew_bow_combo_window:RemoveOnDeath()
	return true 
end