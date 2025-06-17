modifier_scathach_gait_three_window = class({})

if IsServer() then
	function modifier_scathach_gait_three_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("scathach_gait_one", "scathach_gait_three", false, true)
	end

	function modifier_scathach_gait_three_window:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("scathach_gait_one", "scathach_gait_three", true, false)
	end
end

function modifier_scathach_gait_three_window:IsHidden()
	return true
end

function modifier_scathach_gait_three_window:RemoveOnDeath()
	return true 
end