modifier_heracles_berserk = class({})

if IsServer() then
	function modifier_heracles_berserk:OnCreated(args)
		self.LockedHealth = args.LockedHealth
		self.BonusAttSpd = (1.2 - self:GetParent():GetHealth()/self:GetParent():GetMaxHealth())*self:GetAbility():GetSpecialValueFor("bns_att_spd")
		self.BonusDamage = (1.2 - self:GetParent():GetHealth()/self:GetParent():GetMaxHealth())*100
		self.BonusMs = (1.2 - self:GetParent():GetHealth()/self:GetParent():GetMaxHealth())*100
		--self:GetParent():SetRenderColor(255, 127, 127)
		self:StartIntervalThink(0.033)
		self.dt = 0
		
		CustomNetTables:SetTableValue("sync","herc_berserk_stats", { bonus_attspd = self.BonusAttSpd,
																	 bonus_damage = self.BonusDamage,
																	 bonus_ms = self.BonusMs })
	end

	function modifier_heracles_berserk:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_heracles_berserk:OnDestroy()
		--self:GetParent():SetRenderColor(255, 255, 255)
	end

	function modifier_heracles_berserk:OnIntervalThink()
		local parent = self:GetParent()

		--parent:RemoveModifierByName("modifier_zabaniya_curse")

		self.dt = self.dt + 0.033
		if self.dt >= 0.5 then
			self.dt = 0
			HardCleanse(self:GetParent())
		end

		if parent:HasModifier("modifier_gae_buidhe") then
			local stacks = parent:GetModifierStackCount("modifier_gae_buidhe", self:GetAbility())
			if parent:GetMaxHealth() - (stacks * 10) < self.LockedHealth then
				self.LockedHealth = parent:GetMaxHealth() - (stacks * 10) 
			end
		end

		parent:SetHealth(self.LockedHealth)
	end

	function modifier_heracles_berserk:OnTakeDamage(args)
		local caster = self:GetParent()
    	if IsServer() then
        	if args.unit ~= self:GetParent() then return end

        	caster.BerserkDamageTaken = caster.BerserkDamageTaken + args.damage
    	end
	end


	--[[function modifier_heracles_berserk:OnTakeDamage(args)
		if args.unit ~= self:GetParent() then return end

		if args.damage < self.LockedHealth and self:GetParent():GetHealth() <= 0 then
			self:GetParent():SetHealth(1)
		end

		self:GetParent().BerserkDamageTaken = args.damage + (self:GetParent().BerserkDamageTaken or 0)
		self.BonusDamage = self.BonusDamage + args.damage * 0.1
		CustomNetTables:SetTableValue("sync","herc_berserk_stats", { bonus_attspd = self.BonusAttSpd,
																	 bonus_damage = self.BonusDamage })
	end]]
end

function modifier_heracles_berserk:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_TAKEDAMAGE,
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 --MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			 MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
			 MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_heracles_berserk:GetModifierBaseDamageOutgoing_Percentage()
	local bonus_damage = 0

	if IsServer() then
		bonus_damage = self.BonusDamage or 0
	else
		bonus_damage = CustomNetTables:GetTableValue("sync","herc_berserk_stats").bonus_damage
	end

	return bonus_damage
end

function modifier_heracles_berserk:GetModifierAttackSpeedBonus_Constant()
	local bonus_attspd = 0

	if IsServer() then
		bonus_attspd = self.BonusAttSpd or 0
	else
		bonus_attspd = CustomNetTables:GetTableValue("sync","herc_berserk_stats").bonus_attspd
	end

	return bonus_attspd
end

function modifier_heracles_berserk:GetModifierMoveSpeedBonus_Percentage()
	local bonus_ms = 0

	if IsServer() then
		bonus_ms = self.BonusMs or 0
	else
		bonus_ms = CustomNetTables:GetTableValue("sync","herc_berserk_stats").bonus_ms
	end

	return bonus_ms
end

function modifier_heracles_berserk:RemoveOnDeath()
	return true 
end

function modifier_heracles_berserk:GetTexture()
	return "custom/berserker_5th_berserk"
end

function modifier_heracles_berserk:GetEffectName()
	return "particles/custom/berserker/berserk/buff.vpcf"
end

function modifier_heracles_berserk:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_heracles_berserk:GetStatusEffectName()
	return "particles/custom/berserker/berserk/berserk_status_fx.vpcf"
end

function modifier_heracles_berserk:StatusEffectPriority()
    return 1000
end