modifier_health_lock = class({})

if IsServer() then
	function modifier_health_lock:OnCreated(args)	
		self.LockedHealth = self:GetParent():GetHealth()
		self:StartIntervalThink(0.033)			
	end

	function modifier_health_lock:OnRefresh(args)
		self:OnCreated(args)		
	end

	function modifier_health_lock:OnIntervalThink()		
		local target = self:GetParent()
		local current_health = target:GetHealth()

		if current_health > self.LockedHealth then
			target:SetHealth(self.LockedHealth)
		else
			self.LockedHealth = current_health
		end
	end
end

function modifier_health_lock:RemoveOnDeath()
	return true
end

function modifier_health_lock:IsPermanent()
	return false 
end

function modifier_health_lock:IsDebuff()
	return true
end

--[[
-- Particle name
function modifier_health_lock:GetEffectName()
	return ""
end

--Attach type
function modifier_health_lock:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

--Buff icon image
function modifier_health_lock:GetTexture()
	return ""
end
]]