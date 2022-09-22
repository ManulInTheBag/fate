modifier_squidlord_death_checker = class({})
modifier_squidlord_alive = class({})

if IsServer() then 
	function modifier_squidlord_death_checker:OnDestroy()
		self:GetCaster():RemoveModifierByName("modifier_squidlord_alive")
	end
end

function modifier_squidlord_death_checker:IsHidden()
	return true
end

function modifier_squidlord_alive:IsHidden()
	return true
end

function modifier_squidlord_alive:IsPermanent()
	return false
end

function modifier_squidlord_alive:RemoveOnDeath()
	return true
end

function modifier_squidlord_alive:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end