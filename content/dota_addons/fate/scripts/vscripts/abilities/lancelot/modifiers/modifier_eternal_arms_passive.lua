modifier_eternal_arms_passive = class({})

LinkLuaModifier("modifier_eam_crit_passive", "abilities/lancelot/modifiers/modifier_eam_crit_passive", LUA_MODIFIER_MOTION_NONE)

function modifier_eternal_arms_passive:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_START }
end

if IsServer() then
	function modifier_eternal_arms_passive:OnAttackStart(args)
		if args.attacker ~= self:GetParent() then return end

		local crit_chance = self:GetAbility():GetSpecialValueFor("crit_chance")

		if math.random(1, 100) <= crit_chance then
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_eam_crit_passive", { Duration = 2 })
		end
	end
end

function modifier_eternal_arms_passive:IsHidden()
	return true
end

function modifier_eternal_arms_passive:IsPermanent()
	return true
end

function modifier_eternal_arms_passive:RemoveOnDeath()
	return false
end

function modifier_eternal_arms_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end