modifier_whitechapel_murderer_ally = class({})

if IsServer() then
	function modifier_whitechapel_murderer_ally:OnCreated(args)
		self.OriginalVision = self:GetParent():GetDayTimeVisionRange()

		if self:GetParent():HasModifier("modifier_murderer_mist") then
			self.modifier = self:GetParent():FindModifierByName("modifier_murderer_mist")
			self.OriginalVision = self.modifier.base_range_day
		end

		self.vision_range = math.min(self.OriginalVision, 600)

		self:GetParent():SetDayTimeVisionRange(self.vision_range)
		self:GetParent():SetNightTimeVisionRange(self.vision_range)
		--self:StartIntervalThink(0.49)
	end
	function modifier_whitechapel_murderer_ally:OnRefresh()
	end

	--[[function modifier_whitechapel_murderer_ally:OnIntervalThink()
		self:GetParent():SetDayTimeVisionRange(self.vision_range)
		self:GetParent():SetNightTimeVisionRange(self.vision_range)
	end]]

	function modifier_whitechapel_murderer_ally:OnDestroy()
		self:GetParent():SetDayTimeVisionRange(self.OriginalVision)		
		self:GetParent():SetNightTimeVisionRange(self.OriginalVision)
	end
end

function modifier_whitechapel_murderer_ally:GetTexture()
	return "custom/jtr/whitechapel_murderer"
end