modifier_rune_of_combat = class({})

LinkLuaModifier("modifier_rune_of_combat_hit", "abilities/cu_chulain/modifiers/modifier_rune_of_combat_hit", LUA_MODIFIER_MOTION_NONE)

function modifier_rune_of_combat:DeclareFunctions()
	return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
			 --MODIFIER_EVENT_ON_ATTACK_LANDED
			  }
end

if IsServer() then
	function modifier_rune_of_combat:OnCreated(args)
		self.BaseDamage = 25
		self.BonusAtkPct = args.BonusAtkPct
		self.StunDuration = args.StunDuration

		CustomNetTables:SetTableValue("sync","rune_of_combat_damage", { atk_bonus = self.BaseDamage })
	end

	function modifier_rune_of_combat:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_rune_of_combat:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end

		self.BaseDamage = self.BaseDamage + self.BonusAtkPct

		CustomNetTables:SetTableValue("sync","rune_of_combat_damage", { atk_bonus = self.BaseDamage })

		local modifier = args.target:AddNewModifier(args.attacker, self:GetAbility(), "modifier_rune_of_combat_hit", { Duration = 3 })

		if modifier then
			if modifier:GetStackCount() % 4 < 1 then 
				args.target:AddNewModifier(args.attacker, self:GetAbility(), "modifier_stunned", { Duration = 0.25})
			end
		end
	end
end

function modifier_rune_of_combat:GetModifierBaseDamageOutgoing_Percentage()
	if IsServer() then
		return self.BaseDamage
	elseif IsClient() then
        local atk_bonus = CustomNetTables:GetTableValue("sync","rune_of_combat_damage").atk_bonus
        return atk_bonus 
	end
end

function modifier_rune_of_combat:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end