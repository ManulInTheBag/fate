LinkLuaModifier("modifier_altera_form_str", "abilities/altera/altera_form", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_form_agi", "abilities/altera/altera_form", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_form_int", "abilities/altera/altera_form", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_form_pepeg", "abilities/altera/altera_form", LUA_MODIFIER_MOTION_NONE)

altera_form_open = class({})
altera_form_close = class({})

local tStandardAbilities = {
    "altera_whip",
    "altera_dash",
    "altera_rift",
    "fate_empty1",
    "altera_form_open",
    "altera_beam",
    "attribute_bonus_custom"
}

local tForms = {
    "altera_form_str",
    "altera_form_agi",
    "altera_form_int",
    "fate_empty1",
    "altera_form_close",
    "altera_beam",
    "attribute_bonus_custom"
}

--[[function altera_form_open:OnUpgrade()
    local hCaster = self:GetCaster()
    
    hCaster:FindAbilityByName("kuro_rho_aias"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("kuro_gae_bolg"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("kuro_excalibur_image"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("kuro_nine_lives"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("kuro_rosa_ichthys"):SetLevel(self:GetLevel())
end]]

function altera_form_open:OnSpellStart()
	self:OpenSezame()
end

function altera_form_open:OpenSezame()
	local hCaster = self:GetCaster()
    
    UpdateAbilityLayout(hCaster, tForms)

    hCaster.CurrentAbilLayout = "forms"
end

function altera_form_open:GetIntrinsicModifierName()
	return "modifier_altera_form_pepeg"
end

--------

function altera_form_close:OnSpellStart()
    local hCaster = self:GetCaster()
    UpdateAbilityLayout(hCaster, tStandardAbilities)

    hCaster.CurrentAbilLayout = "standard"

    hCaster:FindAbilityByName("altera_form_open"):EndCooldown()
end

function altera_form_close:OnSpellCalled(forced)
    local hCaster = self:GetCaster()

    local abil = hCaster:FindAbilityByName("altera_form_open")

    abil:EndCooldown()
    if forced then
    	--abil:StartCooldown(abil:GetCooldown(0))
    end

    if hCaster.CurrentAbilLayout == "standard" then return end
    UpdateAbilityLayout(hCaster, tStandardAbilities)
    hCaster.CurrentAbilLayout = "standard"
end

--------

altera_form_str = class({})

function altera_form_str:OnSpellStart()
	local caster = self:GetCaster()

	caster:RemoveModifierByName("modifier_altera_form_str")
	caster:RemoveModifierByName("modifier_altera_form_agi")
	caster:RemoveModifierByName("modifier_altera_form_int")

	caster:FindAbilityByName("altera_form_close"):OnSpellCalled(false)

	caster:AddNewModifier(caster, self, "modifier_altera_form_str", {})
	--caster:SetPrimaryAttribute(DOTA_ATTRIBUTE_STRENGTH)
end

altera_form_agi = class({})

function altera_form_agi:OnSpellStart()
	local caster = self:GetCaster()

	caster:RemoveModifierByName("modifier_altera_form_str")
	caster:RemoveModifierByName("modifier_altera_form_agi")
	caster:RemoveModifierByName("modifier_altera_form_int")

	caster:FindAbilityByName("altera_form_close"):OnSpellCalled(false)
		
	caster:AddNewModifier(caster, self, "modifier_altera_form_agi", {})
	--caster:SetPrimaryAttribute(DOTA_ATTRIBUTE_AGILITY)
end

altera_form_int = class({})

function altera_form_int:OnSpellStart()
	local caster = self:GetCaster()

	caster:RemoveModifierByName("modifier_altera_form_str")
	caster:RemoveModifierByName("modifier_altera_form_agi")
	caster:RemoveModifierByName("modifier_altera_form_int")

	caster:FindAbilityByName("altera_form_close"):OnSpellCalled(false)
		
	caster:AddNewModifier(caster, self, "modifier_altera_form_int", {})
	--caster:SetPrimaryAttribute(DOTA_ATTRIBUTE_INTELLECT)
end

-------

modifier_altera_form_pepeg = class({})

function modifier_altera_form_pepeg:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.close_ability = self.parent:FindAbilityByName("altera_form_close")

	self.parent:AddNewModifier(self.parent, self.parent:FindAbilityByName("altera_form_int"), "modifier_altera_form_int", {})
	--self.parent:SetPrimaryAttribute(DOTA_ATTRIBUTE_INTELLECT)

	self.parent.CurrentAbilLayout = "standard"
end

--[[function modifier_altera_form_pepeg:OnTakeDamage(args)
	if (args.unit ~= self.parent) and (args.attacker ~= self.parent) then return end
	if self.parent:HasModifier("modifier_altera_adaptive") then return end

	self.close_ability:OnSpellCalled(true)
end]]

function modifier_altera_form_pepeg:IsHidden()
	return true 
end

function modifier_altera_form_pepeg:RemoveOnDeath()
	return false
end

function modifier_altera_form_pepeg:IsDebuff()
	return false 
end

function modifier_altera_form_pepeg:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

------------

modifier_altera_form_str = class({})

function modifier_altera_form_str:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			 MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_altera_form_str:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("str_bonus")
end

function modifier_altera_form_str:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("agi_bonus")
end

function modifier_altera_form_str:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("int_bonus")
end

function modifier_altera_form_str:IsHidden()
	return false 
end

function modifier_altera_form_str:RemoveOnDeath()
	return false
end

function modifier_altera_form_str:IsDebuff()
	return false 
end

function modifier_altera_form_str:GetEffectName()
    return "particles/altera/altera_buff_red.vpcf"
end

function modifier_altera_form_str:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

---------------

modifier_altera_form_agi = class({})

function modifier_altera_form_agi:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			 MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_altera_form_agi:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("str_bonus")
end

function modifier_altera_form_agi:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("agi_bonus")
end

function modifier_altera_form_agi:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("int_bonus")
end

function modifier_altera_form_agi:IsHidden()
	return false 
end

function modifier_altera_form_agi:RemoveOnDeath()
	return false
end

function modifier_altera_form_agi:IsDebuff()
	return false 
end

function modifier_altera_form_agi:GetEffectName()
    return "particles/altera/altera_buff_green.vpcf"
end

function modifier_altera_form_agi:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

------------

modifier_altera_form_int = class({})

function modifier_altera_form_int:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			 MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_altera_form_int:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("str_bonus")
end

function modifier_altera_form_int:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("agi_bonus")
end

function modifier_altera_form_int:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("int_bonus")
end

function modifier_altera_form_int:IsHidden()
	return false 
end

function modifier_altera_form_int:RemoveOnDeath()
	return false
end

function modifier_altera_form_int:IsDebuff()
	return false 
end

function modifier_altera_form_int:GetEffectName()
    return "particles/altera/altera_buff_blue.vpcf"
end

function modifier_altera_form_int:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end