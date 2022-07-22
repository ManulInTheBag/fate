modifier_dagger_throw_crit = class({})

function modifier_dagger_throw_crit:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
			 --MODIFIER_EVENT_ON_ATTACK_LANDED
			  }
end

if IsServer() then
	function modifier_dagger_throw_crit:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end

		self:GetParent():RemoveModifierByName("modifier_dagger_throw_crit")
		args.target:EmitSound("Hero_TemplarAssassin.Meld.Attack")
	end
end

function modifier_dagger_throw_crit:GetModifierPreAttack_CriticalStrike()
	return 200
end

function modifier_dagger_throw_crit:IsHidden()
	return true 
end

function modifier_dagger_throw_crit:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end