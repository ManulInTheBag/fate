modifier_scathach_gait_two_window = class({})

if IsServer() then
	function modifier_scathach_gait_two_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("scathach_gait_one", "scathach_gait_two", false, true)
	end

	function modifier_scathach_gait_two_window:OnDestroy()	
		local caster = self:GetParent()	
		caster:SwapAbilities("scathach_gait_one", "scathach_gait_two", true, false)
	end
end

function modifier_scathach_gait_two_window:IsHidden()
	return true
end

function modifier_scathach_gait_two_window:RemoveOnDeath()
	return true 
end