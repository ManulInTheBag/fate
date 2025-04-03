modifier_rune_of_combat = class({})

LinkLuaModifier("modifier_rune_of_combat_hit", "abilities/cu_chulain/modifiers/modifier_rune_of_combat_hit", LUA_MODIFIER_MOTION_NONE)

function modifier_rune_of_combat:DeclareFunctions()
	return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
			 --MODIFIER_EVENT_ON_ATTACK_LANDED
			  }
end

if IsServer() then
	function modifier_rune_of_combat:OnCreated(args)
		self.BaseDamage = 25
		self.BonusAtkPct = args.BonusAtkPct
		self.StunDuration = args.StunDuration
		self.AttackSpeed = self:GetAbility():GetSpecialValueFor("bonus_attackspeed")
		self.attackCounter = 0
		self:SetStackCount(self.AttackSpeed)
		CustomNetTables:SetTableValue("sync","rune_of_ferocity", { attack_speed = self.AttackSpeed })
		CustomNetTables:SetTableValue("sync","rune_of_combat_damage", { atk_bonus = self.BaseDamage })
	end

	function modifier_rune_of_combat:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_rune_of_combat:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end
		self.attackCounter = self.attackCounter+1
		self.BaseDamage = self.BaseDamage + self.BonusAtkPct
		if self.BaseDamage > self:GetAbility():GetSpecialValueFor("bonus_atk_max") then
			self.BaseDamage = self:GetAbility():GetSpecialValueFor("bonus_atk_max")
		end
		CustomNetTables:SetTableValue("sync","rune_of_combat_damage", { atk_bonus = self.BaseDamage })
		if self.attackCounter < self:GetAbility():GetSpecialValueFor("bonus_attackspeed_attacks") then 
			self.AttackSpeed = math.max(self.AttackSpeed - self:GetAbility():GetSpecialValueFor("bonus_attackspeed_loss"), 0)

			self:SetStackCount(self.AttackSpeed)
			CustomNetTables:SetTableValue("sync","rune_of_ferocity", { attack_speed = self.AttackSpeed })
		else
			self:SetStackCount(0)
			CustomNetTables:SetTableValue("sync","rune_of_ferocity", { attack_speed = 0 })
		end
		local modifier = args.target:AddNewModifier(args.attacker, self:GetAbility(), "modifier_rune_of_combat_hit", { Duration = 3 })
		--[[
		if modifier then
			if modifier:GetStackCount() % 4 < 1 then 
				args.target:AddNewModifier(args.attacker, self:GetAbility(), "modifier_stunned", { Duration = 0.25})
			end
		end
		]]
	end
end
function modifier_rune_of_combat:GetModifierAttackSpeedBonus_Constant()
	if IsServer() then
		return self.AttackSpeed
	elseif IsClient() then
		local attack_speed = CustomNetTables:GetTableValue("sync","rune_of_ferocity").attack_speed
        return attack_speed 
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