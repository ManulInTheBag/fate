modifier_rune_of_ferocity = class({})
modifier_rune_of_ferocity_progress = class({})

function modifier_rune_of_ferocity:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 --MODIFIER_EVENT_ON_ATTACK_LANDED
			  }
end

if IsServer() then
	function modifier_rune_of_ferocity:OnCreated(args)
		self.AttackSpeed = 600

		self:SetStackCount(self.AttackSpeed)
		CustomNetTables:SetTableValue("sync","rune_of_ferocity", { attack_speed = self.AttackSpeed })
	end

	function modifier_rune_of_ferocity:OnIntervalThink()
		self.AttackSpeed = 600

		self:SetStackCount(self.AttackSpeed)
		CustomNetTables:SetTableValue("sync","rune_of_ferocity", { attack_speed = self.AttackSpeed })

		self:StartIntervalThink(-1)

		local progress = self:GetParent():FindModifierByName("modifier_rune_of_ferocity_progress")
		if progress then
			progress:SetStackCount(100)
			progress:StartIntervalThink(-1)
		end
	end

	function modifier_rune_of_ferocity:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() or self:GetParent():HasModifier("modifier_relentless_spear") then return end
		local ability = self:GetAbility()

		self.AttackSpeed = math.max(self.AttackSpeed - ability:GetSpecialValueFor("attack_speed_loss"), 0)

		self:SetStackCount(self.AttackSpeed)
		CustomNetTables:SetTableValue("sync","rune_of_ferocity", { attack_speed = self.AttackSpeed })

		self:StartIntervalThink(4)

		local progress = self:GetParent():FindModifierByName("modifier_rune_of_ferocity_progress")
		if progress then
			progress.TotalDuration = 4
			progress.DurationLeft = 4
			progress:StartIntervalThink(0.05)
		end
	end
end

function modifier_rune_of_ferocity:GetModifierAttackSpeedBonus_Constant()
	if IsServer() then
		return self.AttackSpeed
	elseif IsClient() then
		local magic_resist = CustomNetTables:GetTableValue("sync","rune_of_ferocity").magic_resist
        return magic_resist 
	end
end

function modifier_rune_of_ferocity:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end


if IsServer() then
	function modifier_rune_of_ferocity_progress:OnCreated(args)
		self:SetStackCount(100)
	end

	function modifier_rune_of_ferocity_progress:OnIntervalThink()
		if self.DurationLeft == nil or self.DurationLeft == 0 then 
			self:SetStackCount(100)
			self:StartIntervalThink(-1) 
			return
		else
			self.DurationLeft = self.DurationLeft - 0.05
			self:SetStackCount(100 * (1 - self.DurationLeft / self.TotalDuration ))
		end
	end
end

function modifier_rune_of_ferocity_progress:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_rune_of_ferocity_progress:IsHidden()
    return true
end

function modifier_rune_of_ferocity_progress:IsDebuff()
    return false
end

function modifier_rune_of_ferocity_progress:RemoveOnDeath()
    return false
end
