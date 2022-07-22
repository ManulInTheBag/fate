modifier_jeanne_divine_symbol = class({})

LinkLuaModifier("modifier_jeanne_vision", "abilities/jeanne/modifiers/modifier_jeanne_vision", LUA_MODIFIER_MOTION_NONE)

function modifier_jeanne_divine_symbol:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED
	 }
end

if IsServer() then
	function modifier_jeanne_divine_symbol:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end

		local hTarget = args.target
		local hAttacker = args.attacker
		local fDamage = hAttacker:GetIntellect() + 25

		DoDamage(hAttacker, hTarget, fDamage, DAMAGE_TYPE_PURE, 0, self:GetAbility(), false)
	end
end

function modifier_jeanne_divine_symbol:IsDebuff()
	return false
end

function modifier_jeanne_divine_symbol:IsAura()
	return true 
end

function modifier_jeanne_divine_symbol:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_jeanne_divine_symbol:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

function modifier_jeanne_divine_symbol:GetAuraRadius()
	if self:GetParent():HasModifier("modifier_murderer_mist_in") then
		return 350
	end
	return 750
end

function modifier_jeanne_divine_symbol:GetModifierAura()
	return "modifier_jeanne_vision"
end

function modifier_jeanne_divine_symbol:GetTexture()
	return "custom/jeanne_attribute_divine_symbol"
end