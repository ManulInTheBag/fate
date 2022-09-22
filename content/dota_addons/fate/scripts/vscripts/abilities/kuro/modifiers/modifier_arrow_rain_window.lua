modifier_arrow_rain_window = class({})

function modifier_arrow_rain_window:OnDestroy()
	if IsServer() then
		local hero = self:GetParent()
		if hero:HasModifier("modifier_unlimited_bladeworks") then
			hero:SwapAbilities("emiya_gae_bolg", "emiya_arrow_rain", true, false)
		end
	end
end

function modifier_arrow_rain_window:IsHidden()
	return true
end

function modifier_arrow_rain_window:RemoveOnDeath()
	return true 
end