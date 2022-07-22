modifier_eam_crit_passive = class({})

function modifier_eam_crit_passive:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
			 --MODIFIER_EVENT_ON_ATTACK_LANDED
			  }
end

if IsServer() then
	function modifier_eam_crit_passive:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end

		self:GetParent():RemoveModifierByName("modifier_eam_crit_passive")
		args.target:EmitSound("DOTA_Item.Daedelus.Crit")
	end
end

function modifier_eam_crit_passive:GetModifierPreAttack_CriticalStrike()
	return 200
end

function modifier_eam_crit_passive:IsHidden()
	return true 
end

function modifier_eam_crit_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end