modifier_dirk_poison = class({})

LinkLuaModifier("modifier_weakening_venom", "abilities/true_assassin/modifiers/modifier_weakening_venom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dirk_poison_slow", "abilities/true_assassin/modifiers/modifier_dirk_poison_slow", LUA_MODIFIER_MOTION_NONE)

function modifier_dirk_poison:DeclareFunctions()
	local func = { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
	return func
end

function modifier_dirk_poison:OnCreated(table)
	if IsServer() then
		self.PoisonDamage = table.PoisonDamage * 0.5
		self.PoisonSlow	= table.PoisonSlow

		local target = self:GetParent()
		if not IsImmuneToSlow(target) then
			target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_dirk_poison_slow", { PoisonSlow = self.PoisonSlow,
																									  Duration = self:GetDuration() })
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
	local stacks = 1

	if target:HasModifier("modifier_weakening_venom") then
		stacks = target:GetModifierStackCount("modifier_weakening_venom", self:GetAbility())
	end

	DoDamage(caster, target, self.PoisonDamage * stacks, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false) 
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

function modifier_dirk_poison:GetModifierPhysicalArmorBonus()
	if self:GetCaster().IsWeakeningVenomAcquired then
    	return self:GetParent():GetModifierStackCount("modifier_weakening_venom", self:GetAbility()) * -1*0.5
    else
    	return 0
    end
end
