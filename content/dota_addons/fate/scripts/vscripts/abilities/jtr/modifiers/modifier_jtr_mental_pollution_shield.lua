modifier_jtr_mental_pollution_shield = class({})

if IsServer() then 
	function modifier_jtr_mental_pollution_shield:OnDestroy()		
		local thinker = self:GetParent():FindModifierByName("modifier_jtr_mental_pollution")

		print("something")
		if thinker then 
			print("found the buff")
			thinker:BeginCooldown()
		end
	end
end

function modifier_jtr_mental_pollution_shield:IsHidden() return false end

function modifier_jtr_mental_pollution_shield:IsDebuff() return false end

function modifier_jtr_mental_pollution_shield:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end