LinkLuaModifier("modifier_pepeg_divinity", "abilities/heracles/pepeg_divinity", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pepeg_regen", "abilities/heracles/pepeg_divinity", LUA_MODIFIER_MOTION_NONE)

pepeg_divinity = class({})

function pepeg_divinity:GetIntrinsicModifierName()
	return "modifier_pepeg_divinity"
end

modifier_pepeg_divinity = class({})

function modifier_pepeg_divinity:IsHidden() return true end
function modifier_pepeg_divinity:IsDebuff() return false end
function modifier_pepeg_divinity:RemoveOnDeath() return false end
function modifier_pepeg_divinity:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_pepeg_divinity:DeclareFunctions()
	local func =	{MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
					MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
					MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT}
	return func
end

function modifier_pepeg_divinity:GetModifierPhysical_ConstantBlock()
	return self:GetAbility():GetSpecialValueFor("physical_block")
end

function modifier_pepeg_divinity:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_pepeg_divinity:OnCreated()
	if IsServer() then
		self.stack_count = 0
		self.ability = self:GetAbility()
	end
end

function modifier_pepeg_divinity:OnTakeDamage(args)
	if IsServer() then
		if not self:GetParent().IsReincarnationAcquired then return end
		if args.unit ~= self:GetParent() then return end

		local duration = self.ability:GetSpecialValueFor("duration")

		local delta = args.damage/duration*self.ability:GetSpecialValueFor("regen_percent")/100

		self.stack_count = self.stack_count + delta
		self:SetStackCount(self.stack_count)
		print (self.stack_count)
		Timers:CreateTimer(duration, function()
			self.stack_count = self.stack_count - delta
			self:SetStackCount(self.stack_count)
		end)
	end
end

function modifier_pepeg_divinity:GetModifierConstantHealthRegen()
	return self:GetParent():GetModifierStackCount("modifier_pepeg_divinity", self:GetParent())
end