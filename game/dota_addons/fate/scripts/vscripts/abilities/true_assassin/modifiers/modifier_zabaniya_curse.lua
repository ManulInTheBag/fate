modifier_zabaniya_curse = class({})

if IsServer() then
	function modifier_zabaniya_curse:OnCreated(args)	
		self.LockedHealth = self:GetParent():GetHealth()
		self:StartIntervalThink(0.033)			
	end

	function modifier_zabaniya_curse:OnRefresh(args)
		self:OnCreated(args)		
	end

	function modifier_zabaniya_curse:OnIntervalThink()		
		local target = self:GetParent()
		local current_health = target:GetHealth()

		if current_health > self.LockedHealth then
			target:SetHealth(self.LockedHealth)
		else
			self.LockedHealth = current_health
		end
	end
end

function modifier_zabaniya_curse:GetTexture()
	return "custom/true_assassin_zabaniya"
end

function modifier_zabaniya_curse:RemoveOnDeath()
	return true
end

function modifier_zabaniya_curse:IsPermanent()
	return false 
end

function modifier_zabaniya_curse:IsDebuff()
	return true
end

function modifier_zabaniya_curse:GetEffectName()
	return "particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_trail_circle.vpcf"
end

function modifier_zabaniya_curse:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end