modifier_breaker_gorgon_frozen = class({})

function modifier_breaker_gorgon_frozen:CheckState()
	return { [MODIFIER_STATE_FROZEN] = true,
			 [MODIFIER_STATE_STUNNED] = true }
end

function modifier_breaker_gorgon_frozen:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			 MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			 --MODIFIER_EVENT_ON_ATTACK_LANDED
			  }
end

function modifier_breaker_gorgon_frozen:GetModifierMagicalResistanceBonus()
	return -25
end

function modifier_breaker_gorgon_frozen:GetModifierPhysicalArmorBonus()
	return 100
end

function modifier_breaker_gorgon_frozen:OnAttackLanded(args)
	if IsServer() then
		if args.attacker:GetName() == "npc_dota_hero_templar_assassin" and args.target == self:GetParent() then

			DoDamage(args.attacker, args.target, 100, DAMAGE_TYPE_PURE, 0, self:GetAbility(), false)
		end
	end
end

function modifier_breaker_gorgon_frozen:IsHidden()
	return false
end

function modifier_breaker_gorgon_frozen:IsDebuff()
	return true
end

function modifier_breaker_gorgon_frozen:RemoveOnDeath()
	return true
end

function modifier_breaker_gorgon_frozen:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_breaker_gorgon_frozen:GetTexture()
	return "custom/rider_5th_breaker_gorgon"
end