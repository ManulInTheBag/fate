LinkLuaModifier("modifier_arcueid_regen", "abilities/arcueid/arcueid_regen", LUA_MODIFIER_MOTION_NONE)

arcueid_regen = class({})

function arcueid_regen:GetIntrinsicModifierName()
	return "modifier_arcueid_regen"
end

modifier_arcueid_regen = class({})

function modifier_arcueid_regen:IsHidden() return true end
function modifier_arcueid_regen:IsDebuff() return false end
--function modifier_true_assassin_selfmod:IsPurgable() return false end
--function modifier_true_assassin_selfmod:IsPurgeException() return false end
function modifier_arcueid_regen:RemoveOnDeath() return false end
function modifier_arcueid_regen:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end
function modifier_arcueid_regen:DeclareFunctions()
	local func = {	MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
				}
	return func
end

function modifier_arcueid_regen:OnCreated()
	if IsServer() then
		self.stack_count = 0
		self.ability = self:GetAbility()
	end
end

function modifier_arcueid_regen:OnTakeDamage(args)
	if IsServer() then
		if args.unit ~= self:GetParent() then return end

		local duration = self.ability:GetSpecialValueFor("duration")

		local delta = args.damage/duration*self.ability:GetSpecialValueFor("regen_percent")/100

		self.stack_count = self.stack_count + delta
		self:SetStackCount(self.stack_count)
		Timers:CreateTimer(duration, function()
			self.stack_count = self.stack_count - delta
			self:SetStackCount(self.stack_count)
		end)
	end
end

function modifier_arcueid_regen:GetModifierConstantHealthRegen()
	return self:GetParent():GetModifierStackCount("modifier_arcueid_regen", self:GetParent())
end