modifier_murderer_mist = class({})

function modifier_murderer_mist:IsHidden()
	return true
end

function modifier_murderer_mist:IsDebuff()
	return false
end

function modifier_murderer_mist:GetModifierAttribute()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

if IsServer() then
	function modifier_murderer_mist:OnCreated(args)
		self.parent = self:GetParent()
		self.base_range_day = self.parent:GetDayTimeVisionRange()
		self.base_range_night = self.parent:GetNightTimeVisionRange()
		if self.parent:HasModifier("modifier_whitechapel_murderer_ally") then
			self.base_range_day = self.parent:FindModifierByName("modifier_whitechapel_murderer_ally").OriginalVision
			self.base_range_night = self.parent:FindModifierByName("modifier_whitechapel_murderer_ally").OriginalVision
		end
		if self.parent:HasModifier("modifier_whitechapel_murderer_enemy") then
			self.base_range_day = self.parent:FindModifierByName("modifier_whitechapel_murderer_enemy").OriginalVision
			self.base_range_night = self.parent:FindModifierByName("modifier_whitechapel_murderer_enemy").OriginalVision
		end
		self.range_day = math.min(0, self.base_range_day)
		self.range_night = math.min(0, self.base_range_night)

		self.parent:SetDayTimeVisionRange(self.range_day)
		self.parent:SetNightTimeVisionRange(self.range_night)
	end

	function modifier_murderer_mist:OnRefresh(args)
		self.parent = self:GetParent()
		if not self.parent:HasModifier("modifier_whitechapel_murderer_ally") or self.parent:HasModifier("modifier_whitechapel_murderer_enemy") then
			self.range_day = math.min(0, self.base_range_day)
			self.range_night = math.min(0, self.base_range_night)

			self.parent:SetDayTimeVisionRange(self.range_day)
			self.parent:SetNightTimeVisionRange(self.range_night)
		end
	end

	function modifier_murderer_mist:OnDestroy()
		if not self.parent:HasModifier("modifier_whitechapel_murderer_ally") or self.parent:HasModifier("modifier_whitechapel_murderer_enemy") then
			self.parent:SetDayTimeVisionRange(self.base_range_day)
			self.parent:SetNightTimeVisionRange(self.base_range_night)
		end
	end
end