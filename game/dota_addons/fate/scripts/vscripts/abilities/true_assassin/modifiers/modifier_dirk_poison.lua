modifier_dirk_poison = class({})

LinkLuaModifier("modifier_weakening_venom", "abilities/true_assassin/modifiers/modifier_weakening_venom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dirk_poison_slow", "abilities/true_assassin/modifiers/modifier_dirk_poison_slow", LUA_MODIFIER_MOTION_NONE)

function modifier_dirk_poison:OnCreated(table)
	if IsServer() then
		self.PoisonDamage = table.PoisonDamage * 0.5
		self.PoisonSlow	= table.PoisonSlow

		local target = self:GetParent()
		if not IsImmuneToSlow(target) then
			target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_dirk_poison_slow", { Duration = self:GetDuration() })
		end

		self:StartIntervalThink(0.5)
	end
end

function modifier_dirk_poison:OnRefresh(table)
	self:OnCreated(table)
end

function modifier_dirk_poison:OnIntervalThink()
	local target = self:GetParent()
	local caster = self:GetCaster()
	local stacks = 0
	local stacksDirk = target:GetModifierStackCount("modifier_dirk_poison_slow", self:GetAbility())
	if target:HasModifier("modifier_weakening_venom")  then
		stacks = target:GetModifierStackCount("modifier_weakening_venom", self:GetAbility()) 
	end
	local total_stacks = stacks + stacksDirk
	DoDamage(caster, target, self.PoisonDamage * total_stacks, DAMAGE_TYPE_PHYSICAL, 0, self:GetAbility(), false) 
end

function modifier_dirk_poison:GetAttributes()
  return MODIFIER_ATTRIBUTE_NONE
end

function modifier_dirk_poison:IsDebuff()
	return true 
end

function modifier_dirk_poison:IsHidden()
	return true 
end


function modifier_dirk_poison:RemoveOnDeath()
	return true 
end

function modifier_dirk_poison:GetEffectName()
	return "particles/units/heroes/hero_dazzle/dazzle_poison_debuff.vpcf"
end

function modifier_dirk_poison:GetTexture()
    return "custom/true_assassin_dirk"
end

function modifier_dirk_poison:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
