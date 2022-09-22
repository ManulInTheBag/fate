modifier_overedge_charge = class({})

function modifier_overedge_charge:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 --MODIFIER_EVENT_ON_ATTACK_LANDED
			  }
end

function modifier_overedge_charge:OnCreated(args)
	if IsServer() then
		self:SetStackCount(math.min(args.Charges or 1, 4))
		self.ChargeAttackSpeed = args.ChargeAttackSpeed * self:GetStackCount()
		self.OnHitDamage = args.OnHitDamage

		CustomNetTables:SetTableValue("sync","overedge_stats", { attack_speed = self.ChargeAttackSpeed })
	end
end

function modifier_overedge_charge:OnRefresh(args)
	if IsServer() then
		args.Charges = self:GetStackCount() + 1
		self:OnCreated(args)
	end
end

function modifier_overedge_charge:OnAttackLanded(args)
	if IsServer() then
		if args.attacker ~= self:GetParent() then return end

		local chance = RandomInt(1, 100)

		if chance < 30 then
			local caster = self:GetParent()
			local ability = self:GetAbility()
			local target = args.target

			args.target:EmitSound("Hero_TrollWarlord.BerserkersRage.Stun")

			DoDamage(caster, target, self.OnHitDamage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
		end
	end
end

function modifier_overedge_charge:GetModifierAttackSpeedBonus_Constant()
	if IsServer() then
		return self.ChargeAttackSpeed
	elseif IsClient() then
		local attack_speed = CustomNetTables:GetTableValue("sync","overedge_stats").attack_speed
        return attack_speed 
	end
end

function modifier_overedge_charge:IsHidden()
	return false
end

function modifier_overedge_charge:IsDebuff()
	return false
end

function modifier_overedge_charge:RemoveOnDeath()
	return true
end

function modifier_overedge_charge:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_overedge_charge:GetTexture()
	return "custom/archer_5th_kanshou_bakuya"
end