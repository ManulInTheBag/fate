LinkLuaModifier("modifier_imperial_buff", "abilities/nero/nero_imperial", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imperial_buff_h", "abilities/nero/nero_imperial", LUA_MODIFIER_MOTION_NONE)

nero_imperial_open = class({})
nero_imperial_close = class({})

local tStandardAbilities = {
    "nero_tres_new",
    "nero_gladiusanus_new",
    "nero_rosa_new",
    "nero_heat",
    "nero_imperial_open",
    "nero_spectaculi_initium",
    "attribute_bonus_custom"
}

local tUpdatedAbilities = {
    "nero_tres_new",

    "nero_gladiusanus_new",
    "nero_rosa_new",
    "nero_heat",
    "nero_imperial_activate",
    "nero_spectaculi_initium",
    "attribute_bonus_custom"
}

local tProjections = {
    "nero_privilege_damage",
    "nero_privilege_regen",
    "nero_privilege_defence",
    "fate_empty1",
    "nero_imperial_close",
    "nero_spectaculi_initium",
    "attribute_bonus_custom"
}

function nero_imperial_open:OnUpgrade()
    local hCaster = self:GetCaster()
    
    hCaster:FindAbilityByName("nero_privilege_damage"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("nero_privilege_regen"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("nero_privilege_defence"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("nero_imperial_close"):SetLevel(self:GetLevel())
end

function nero_imperial_open:OnSpellStart()
    local hCaster = self:GetCaster()

    hCaster.ImperialChoose = "nero_privilege_damage"

    hCaster:RemoveModifierByName("modifier_laus_saint_checker")
    
    if not hCaster:HasModifier("modifier_aestus_domus_aurea_nero") then
        UpdateAbilityLayout(hCaster, tProjections)
    end
end

function nero_imperial_open:ReInit(caster)
    local caster = caster
    UpdateAbilityLayout(caster, tStandardAbilities)
end

function nero_imperial_close:OnSpellStart()
    local hCaster = self:GetCaster()
    UpdateAbilityLayout(hCaster, tStandardAbilities)
end

function nero_imperial_close:OnSpellCalled(ability)
    local hCaster = self:GetCaster()
    UpdateAbilityLayout(hCaster, tStandardAbilities)
end

-- re-applies the running imperial buffs with values for the current choice,
-- so switching the privilege updates the bonuses (and the HUD) immediately
local function NeroUpdateImperialBuffs(caster)
    for name, base_only in pairs({ ["modifier_imperial_buff_h"] = true, ["modifier_imperial_buff"] = false }) do
        local m = caster:FindModifierByName(name)
        if m and not m:IsNull() then
            local kv = NeroImperialBonuses(caster, base_only)
            kv.duration = m:GetRemainingTime()
            caster:AddNewModifier(caster, m:GetAbility(), name, kv)
        end
    end
end

nero_privilege_damage = class({})

function nero_privilege_damage:OnSpellStart()
    local caster = self:GetCaster()
    caster.ImperialChoose = "nero_privilege_damage"
    NeroUpdateImperialBuffs(caster)
    UpdateAbilityLayout(caster, tUpdatedAbilities)
end

nero_privilege_regen = class({})

function nero_privilege_regen:OnSpellStart()
    local caster = self:GetCaster()
    caster.ImperialChoose = "nero_privilege_regen"
    NeroUpdateImperialBuffs(caster)
    UpdateAbilityLayout(caster, tUpdatedAbilities)
end

nero_privilege_defence = class({})

function nero_privilege_defence:OnSpellStart()
    local caster = self:GetCaster()
    caster.ImperialChoose = "nero_privilege_defence"
    NeroUpdateImperialBuffs(caster)
    UpdateAbilityLayout(caster, tUpdatedAbilities)
end

nero_imperial_activate = class({})

--[[function nero_imperial_activate:GetAbilityTextureName()
    return "custom/nero/"..self:GetCaster().ImperialChoose
end]]

function nero_imperial_activate:OnSpellStart()
    local caster = self:GetCaster()
    if not caster:FindModifierByName("modifier_nero_heat").rank then
        caster:FindModifierByName("modifier_nero_heat").rank = 0
        if(  self:GetParent():HasModifier("modifier_nero_heat_stacks")) then  
            self:GetParent():FindModifierByName("modifier_nero_heat_stacks"):SetStackCount(0)
        end
    end
    if caster:HasModifier("modifier_aestus_domus_aurea_nero") and caster:FindModifierByName("modifier_nero_heat").rank == 1 then
        return
    elseif caster:FindModifierByName("modifier_nero_heat").rank == 0 then
        return
    end
    local kv = NeroImperialBonuses(caster, false)
    kv.duration = self:GetSpecialValueFor("duration")
    caster:AddNewModifier(caster, self, "modifier_imperial_buff", kv)
end

-- computes the current privilege bonuses on the server; the result is passed
-- through the AddNewModifier kv table so the client HUD shows real numbers
-- (the old getters were server-only and displayed as zero on the client).
-- NOTE: the internal ability names lie - per the tooltips nero_privilege_damage is
-- "Spearhead of Progress" (attack damage), nero_privilege_regen is "Soul of Rome"
-- (mana AND health regen), nero_privilege_defence is "Divine Body" (armor + MR)
function NeroImperialBonuses(caster, base_only)
    local rank = 0
    local heat = caster:FindModifierByName("modifier_nero_heat")
    if heat and heat.rank then rank = heat.rank end
    local choose = caster.ImperialChoose
    local function v(abil, key)
        local a = caster:FindAbilityByName(abil)
        return a and a:GetSpecialValueFor(key) * rank or 0
    end
    local t = { bonus_damage = 0, mana_regen = 0, hp_regen = 0, armor = 0, mr = 0 }
    if choose == "nero_privilege_damage" then
        t.bonus_damage = v("nero_privilege_damage", "base_value") + (base_only and 0 or v("nero_privilege_damage", "bonus_value"))
    elseif choose == "nero_privilege_regen" then
        local regen = v("nero_privilege_regen", "base_value") + (base_only and 0 or v("nero_privilege_regen", "bonus_value"))
        t.mana_regen, t.hp_regen = regen, regen
    elseif choose == "nero_privilege_defence" then
        t.armor = v("nero_privilege_defence", "base_armor") + (base_only and 0 or v("nero_privilege_defence", "bonus_armor"))
        t.mr    = v("nero_privilege_defence", "base_mr")    + (base_only and 0 or v("nero_privilege_defence", "bonus_mr"))
    end
    return t
end

modifier_imperial_buff = class({})

-- the AddNewModifier kv table is server-only, so the computed bonuses are
-- shipped to the client through the custom transmitter data channel -
-- that is what makes the numbers show up in the HUD in real time
function modifier_imperial_buff:AddCustomTransmitterData()
    return {
        bonus_damage = self.bonus_damage,
        mana_regen   = self.mana_regen,
        hp_regen     = self.hp_regen,
        armor        = self.armor,
        mr           = self.mr,
    }
end

function modifier_imperial_buff:HandleCustomTransmitterData(data)
    self.bonus_damage = data.bonus_damage
    self.mana_regen   = data.mana_regen
    self.hp_regen     = data.hp_regen
    self.armor        = data.armor
    self.mr           = data.mr
end

function modifier_imperial_buff:OnCreated(kv)
    if IsServer() then
        self.bonus_damage = kv.bonus_damage or 0
        self.mana_regen   = kv.mana_regen or 0
        self.hp_regen     = kv.hp_regen or 0
        self.armor        = kv.armor or 0
        self.mr           = kv.mr or 0
        self:SetHasCustomTransmitterData(true)
    end
    if IsServer() then
        self.parent = self:GetParent()
        local caster = self:GetCaster()
        --print(self.parent.ImperialChoose)
        self.rank = self.parent:FindModifierByName("modifier_nero_heat").rank
        if self.parent:HasModifier("modifier_aestus_domus_aurea_nero") then
            self.parent:FindModifierByName("modifier_nero_heat").rank = 1
            if(  self:GetParent():HasModifier("modifier_nero_heat_stacks")) then  
                self:GetParent():FindModifierByName("modifier_nero_heat_stacks"):SetStackCount(1)
            end
        else
            self.parent:FindModifierByName("modifier_nero_heat").rank = 0
            if(  self:GetParent():HasModifier("modifier_nero_heat_stacks")) then  
                self:GetParent():FindModifierByName("modifier_nero_heat_stacks"):SetStackCount(0)
            end
        end
    end
end

function modifier_imperial_buff:OnRefresh(kv)
    if IsServer() then
        self.bonus_damage = kv.bonus_damage or 0
        self.mana_regen   = kv.mana_regen or 0
        self.hp_regen     = kv.hp_regen or 0
        self.armor        = kv.armor or 0
        self.mr           = kv.mr or 0
        self.rank = self.parent:FindModifierByName("modifier_nero_heat").rank
        if self.SendBuffRefreshToClients then
            self:SendBuffRefreshToClients()
        end
    end
end

function modifier_imperial_buff:IsHidden() return false end
function modifier_imperial_buff:IsDebuff() return false end

function modifier_imperial_buff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

function modifier_imperial_buff:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage or 0
end

function modifier_imperial_buff:GetModifierMagicalResistanceBonus()
    return self.mr or 0
end

function modifier_imperial_buff:GetModifierConstantManaRegen()
    return self.mana_regen or 0
end

function modifier_imperial_buff:GetModifierConstantHealthRegen()
    return self.hp_regen or 0
end

function modifier_imperial_buff:GetModifierPhysicalArmorBonus()
    return self.armor or 0
end

function modifier_imperial_buff:GetEffectName()
    return "particles/kinghassan/pugna_decrepify.vpcf"
end

function modifier_imperial_buff:GetEffectAttachType()
    return PATTACH_POINT_FOLLOW
end

modifier_imperial_buff_h = class({})

function modifier_imperial_buff_h:AddCustomTransmitterData()
    return {
        bonus_damage = self.bonus_damage,
        mana_regen   = self.mana_regen,
        hp_regen     = self.hp_regen,
        armor        = self.armor,
        mr           = self.mr,
    }
end

function modifier_imperial_buff_h:HandleCustomTransmitterData(data)
    self.bonus_damage = data.bonus_damage
    self.mana_regen   = data.mana_regen
    self.hp_regen     = data.hp_regen
    self.armor        = data.armor
    self.mr           = data.mr
end

function modifier_imperial_buff_h:OnCreated(kv)
    if IsServer() then
        self.bonus_damage = kv.bonus_damage or 0
        self.mana_regen   = kv.mana_regen or 0
        self.hp_regen     = kv.hp_regen or 0
        self.armor        = kv.armor or 0
        self.mr           = kv.mr or 0
        self:SetHasCustomTransmitterData(true)
    end
    if IsServer() then
        self.parent = self:GetParent()
        local caster = self:GetCaster()
        --print(self.parent.ImperialChoose)
        self.rank = self.parent:FindModifierByName("modifier_nero_heat").rank
    end
end

function modifier_imperial_buff_h:OnRefresh(kv)
    if IsServer() then
        self.bonus_damage = kv.bonus_damage or 0
        self.mana_regen   = kv.mana_regen or 0
        self.hp_regen     = kv.hp_regen or 0
        self.armor        = kv.armor or 0
        self.mr           = kv.mr or 0
        self.rank = self.parent:FindModifierByName("modifier_nero_heat").rank
        if self.SendBuffRefreshToClients then
            self:SendBuffRefreshToClients()
        end
    end
end

function modifier_imperial_buff_h:IsHidden() return true end
function modifier_imperial_buff_h:IsDebuff() return false end

function modifier_imperial_buff_h:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    }
end

function modifier_imperial_buff_h:GetModifierPreAttack_BonusDamage()
    return self.bonus_damage or 0
end

function modifier_imperial_buff_h:GetModifierMagicalResistanceBonus()
    return self.mr or 0
end

function modifier_imperial_buff_h:GetModifierConstantManaRegen()
    return self.mana_regen or 0
end

function modifier_imperial_buff_h:GetModifierConstantHealthRegen()
    return self.hp_regen or 0
end

function modifier_imperial_buff_h:GetModifierPhysicalArmorBonus()
    return self.armor or 0
end