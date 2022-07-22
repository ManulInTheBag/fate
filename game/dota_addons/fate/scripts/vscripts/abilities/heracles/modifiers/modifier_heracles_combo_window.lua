modifier_heracles_combo_window = class({})

if IsServer() then 
	function modifier_heracles_combo_window:OnCreated(args)
		local caster = self:GetParent()
		caster:SwapAbilities("berserker_5th_madmans_roar", "heracles_berserk", true, false)
	end

	function modifier_heracles_combo_window:OnDestroy()
		local caster = self:GetParent()
		caster:SwapAbilities("berserker_5th_madmans_roar", "heracles_berserk", false, true)
	end
end


function modifier_heracles_combo_window:IsHidden()
	return true
end

function modifier_heracles_combo_window:RemoveOnDeath()
	return true 
end