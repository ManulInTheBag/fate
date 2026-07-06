gille_gigantic_horror_passive = class({})

LinkLuaModifier("modifier_gigantic_horror_passive", "abilities/gilles/units_abilities/gille_gigantic_horror_passive", LUA_MODIFIER_MOTION_NONE)

function gille_gigantic_horror_passive:GetIntrinsicModifierName()
	return "modifier_gigantic_horror_passive"
end

modifier_gigantic_horror_passive = class({})

function modifier_gigantic_horror_passive:IsHidden()
	return true
end

function modifier_gigantic_horror_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_gigantic_horror_passive:GetModifierHealthRegenPercentage()
	return self:GetAbility():GetSpecialValueFor("health_regen")
end

-- удары жирнее порога добивают хоррора ещё на 30% от их урона
function modifier_gigantic_horror_passive:OnTakeDamage(keys)
	if not IsServer() then return end
	local parent = self:GetParent()
	if keys.unit ~= parent then return end

	local damageTaken = keys.damage
	local threshold = self:GetAbility():GetSpecialValueFor("damage_threshold")
	local multiplier = 0.3
	if damageTaken > threshold then
		DoDamage(keys.attacker, parent, damageTaken * multiplier, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end
end

function modifier_gigantic_horror_passive:OnAttackStart(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	self:GetParent():EmitSound("Hero_Spectre.Attack")
end

function modifier_gigantic_horror_passive:OnAttackLanded(keys)
	if not IsServer() then return end
	if keys.attacker ~= self:GetParent() then return end
	self:GetParent():EmitSound("Hero_Centaur.HoofStomp")
end
