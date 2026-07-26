modifier_arrow_rain_window = class({})

function modifier_arrow_rain_window:OnDestroy()
	if IsServer() then
		local hero = self:GetParent()
		if not IsNotNull(hero) then return end
		-- окно снимается и смертью: в этот момент слота 5 может уже не быть
		local hSlot5 = hero:GetAbilityByIndex(5)
		--if hero:HasModifier("modifier_unlimited_bladeworks") then
	if hSlot5 and hSlot5:GetName() =="emiya_combo" then
			hero:SwapAbilities("emiya_unlimited_bladeworks", "emiya_combo", true , false)
	end
		--end
	end
end

function modifier_arrow_rain_window:IsHidden()
	return true
end

function modifier_arrow_rain_window:RemoveOnDeath()
	return true 
end