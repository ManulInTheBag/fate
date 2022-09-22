modifier_double_edge = class({})

function modifier_double_edge:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			 MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			 MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
			 MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE }
end

if IsServer() then
	function modifier_double_edge:OnCreated(args)
		self.parent = self:GetParent()
		self.MaxAttackSpeed = args.MaxAttackSpeed
		self.MaxMovespeed = args.MaxMovespeed
		self.MaxDamageAmp = args.MaxDamageAmp
		self.BaseAttackSpeed = args.BaseAttackSpeed
		self.BaseMovementSpeed = args.BaseMovementSpeed
		self.BaseDamageAmp = args.BaseDamageAmp
		self.BaseDamageAmpSelf = args.BaseDamageAmpSelf
		self.AttackSpeed = self.parent:GetAttackSpeed()*(self.BaseAttackSpeed+(self.MaxAttackSpeed-self.BaseAttackSpeed)*(self.parent:GetMaxHealth()-self.parent:GetHealth())/(self.parent:GetMaxHealth()))
		self.Movespeed = (self.BaseMovementSpeed +(self.MaxMovespeed-self.BaseMovementSpeed)*(self.parent:GetMaxHealth()-self.parent:GetHealth())/(self.parent:GetMaxHealth()))
		self.DamageAmp = (self.BaseDamageAmp + (self.MaxDamageAmp-self.BaseDamageAmp)*(self.parent:GetMaxHealth()-self.parent:GetHealth())/(self.parent:GetMaxHealth()))

		CustomNetTables:SetTableValue("sync","double_edge", { attack_speed = self.AttackSpeed,
															  movespeed = self.Movespeed,
															  damage_amp = self.DamageAmp })

		self:StartIntervalThink(FrameTime())
	end

	function modifier_double_edge:OnRefresh(args)
		self:OnCreated(args)
	end

	function modifier_double_edge:OnIntervalThink()
		self.AttackSpeed = self.parent:GetAttackSpeed()*(self.BaseAttackSpeed+(self.MaxAttackSpeed-self.BaseAttackSpeed)*(self.parent:GetMaxHealth()-self.parent:GetHealth())/(self.parent:GetMaxHealth()))
		self.Movespeed = (self.BaseMovementSpeed +(self.MaxMovespeed-self.BaseMovementSpeed)*(self.parent:GetMaxHealth()-self.parent:GetHealth())/(self.parent:GetMaxHealth()))
		self.DamageAmp = (self.BaseDamageAmp + (self.MaxDamageAmp-self.BaseDamageAmp)*(self.parent:GetMaxHealth()-self.parent:GetHealth())/(self.parent:GetMaxHealth()))

		CustomNetTables:SetTableValue("sync","double_edge", { attack_speed = self.AttackSpeed,
															  movespeed = self.Movespeed,
															  damage_amp = self.DamageAmp })
	end
end

function modifier_double_edge:GetModifierAttackSpeedBonus_Constant()
	if IsServer() then
		return self.AttackSpeed
	elseif IsClient() then
		local attack_speed = CustomNetTables:GetTableValue("sync","double_edge").attack_speed
		return attack_speed 
	end
end

function modifier_double_edge:GetModifierMoveSpeedBonus_Percentage()
	if IsServer() then
		return self.Movespeed
	elseif IsClient() then
		local movespeed = CustomNetTables:GetTableValue("sync","double_edge").movespeed
		return movespeed 
	end
end

function modifier_double_edge:GetModifierBaseAttack_BonusDamage()
	if IsServer() then
		return self.DamageAmp
	elseif IsClient() then
		local damage_amp = CustomNetTables:GetTableValue("sync","double_edge").damage_amp
		return damage_amp 
	end
end

function modifier_double_edge:GetModifierIncomingDamage_Percentage()
	return BaseDamageAmpSelf;
end
function modifier_double_edge:GetTexture()
	return "custom/lancelot_double_edge"
end

function modifier_double_edge:GetEffectName()
	return "particles/items2_fx/satanic_buff.vpcf"
end

function modifier_double_edge:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end