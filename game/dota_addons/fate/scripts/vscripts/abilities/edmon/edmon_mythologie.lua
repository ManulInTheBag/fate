LinkLuaModifier("modifier_edmon_mythologie", "abilities/edmon/edmon_mythologie", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_edmon_beam_stacks", "abilities/edmon/edmon_mythologie", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_edmon_melee_stacks", "abilities/edmon/edmon_mythologie", LUA_MODIFIER_MOTION_NONE)


edmon_mythologie = class({})

function edmon_mythologie:GetIntrinsicModifierName()
	return "modifier_edmon_mythologie"
end

modifier_edmon_mythologie = class({})

function modifier_edmon_mythologie:OnCreated()
	self.form = "range"
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.beam_abil = self.parent:FindAbilityByName("edmon_beam")
	self.seq = 1
end

function modifier_edmon_mythologie:IsHidden() return true end
function modifier_edmon_mythologie:IsDebuff() return false end
function modifier_edmon_mythologie:RemoveOnDeath() return false end
function modifier_edmon_mythologie:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end
function modifier_edmon_mythologie:DeclareFunctions()
	local func = {	MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
					MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
					MODIFIER_PROPERTY_IGNORE_ATTACKSPEED_LIMIT,
					MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
				}
	return func
end
function modifier_edmon_mythologie:GetModifierAttackSpeed_Limit()
	if self.form then
		if self.form == "melee" then
			if self:GetParent():HasModifier("modifier_edmon_melee_stacks") then
				return 1
			end
		end
	end
	return 0
end
function modifier_edmon_mythologie:GetModifierAttackSpeedBonus_Constant()
	if self.form then
		if self.form == "melee" then
			if self:GetParent():HasModifier("modifier_edmon_melee_stacks") then
				return 1100
			end
		end
	end
	return 0
end
function modifier_edmon_mythologie:GetModifierBaseAttackTimeConstant()
	if self.form then
		if self.form == "melee" then
			if self:GetParent():HasModifier("modifier_edmon_melee_stacks") then
				return 0.9
			end
			return 0.9
		end
		if self.form == "range" then
			return 1.1
		end
	end
	return 1.1
end
function modifier_edmon_mythologie:GetActivityTranslationModifiers()
	return (self.form..self.seq)
end
function modifier_edmon_mythologie:OnAttackStart(args)
	if not (args.attacker == self.parent) then return end

	local or1 = args.target:GetAbsOrigin()
	local or2 = self.parent:GetAbsOrigin()
	or1.z = 0
	or2.z = 0

	if (or1 - or2):Length2D() > 250 then
		self.form = "range"
	else
		self.form = "melee"
	end

	if self.seq == 1 then
		self.seq = 2
	else
		self.seq = 1
	end
end
function modifier_edmon_mythologie:OnAttackLanded(args)
	if args.attacker ~= self.parent then return end

	if self.form == "range" then
		local or1 = args.target:GetAbsOrigin()
		local or2 = self.parent:GetAbsOrigin()
		local height = or1.z - or2.z

		or1.z = 0
		or2.z = 0

		local range = (or1 - or2):Length2D()
		local dir = (or1 - or2):Normalized()

		self.parent:SetForwardVector(dir)

		local part1 = self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack"..self.seq)) + self.parent:GetForwardVector()*range + Vector(0, 0, height)
		local part9 = self.parent:GetAttachmentOrigin(self.parent:ScriptLookupAttachment("attach_attack"..self.seq)) + self.parent:GetForwardVector()*25

		local modifier = self.parent:AddNewModifier(self.parent, self.ability, "modifier_edmon_melee_stacks", {duration = 5})
		if modifier:GetStackCount() < 6 then
			modifier:IncrementStackCount()
		end

		self.beam_abil:MiniDarkBeam(part1, part9, true, false, false, self.seq)
	else
		local modifier = self.parent:FindModifierByName("modifier_edmon_melee_stacks")
		local isfast = "common"
		if modifier then
			isfast = "fast"
			if modifier:GetStackCount() > 1 then
				modifier:SetStackCount(modifier:GetStackCount() - 1)
			else
				self.parent:RemoveModifierByName("modifier_edmon_melee_stacks")
			end
		else
			local modifier2 = self.parent:AddNewModifier(self.parent, self.ability, "modifier_edmon_beam_stacks", {duration = 5})
			if modifier2:GetStackCount() < 6 then
				modifier2:IncrementStackCount()
			end
		end
		self.beam_abil:MiniDarkBeam(args.target, isfast, true, true, false, self.seq)
	end
end

modifier_edmon_melee_stacks = class({})

function modifier_edmon_melee_stacks:IsDebuff() return false end
function modifier_edmon_melee_stacks:IsHidden() return false end

modifier_edmon_beam_stacks = class({})

function modifier_edmon_beam_stacks:IsDebuff() return false end
function modifier_edmon_beam_stacks:IsHidden() return false end