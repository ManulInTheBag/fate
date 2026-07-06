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
    "nero_health",
    "nero_mana",
    "nero_defence",
    "fate_empty1",
    "nero_imperial_close",
    "nero_spectaculi_initium",
    "attribute_bonus_custom"
}

function nero_imperial_open:OnUpgrade()
    local hCaster = self:GetCaster()
    
    hCaster:FindAbilityByName("nero_health"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("nero_mana"):SetLevel(self:GetLevel())
    --hCaster:FindAbilityByName("nero_tactics"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("nero_defence"):SetLevel(self:GetLevel())
    hCaster:FindAbilityByName("nero_imperial_close"):SetLevel(self:GetLevel())
end

function nero_imperial_open:OnSpellStart()
    local hCaster = self:GetCaster()

    hCaster.ImperialChoose = "nero_health"

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

nero_health = class({})

function nero_health:OnSpellStart()
    local caster = self:GetCaster()
    caster.ImperialChoose = "nero_health"
    UpdateAbilityLayout(caster, tUpdatedAbilities)
end

nero_mana = class({})

function nero_mana:OnSpellStart()
    local caster = self:GetCaster()
    caster.ImperialChoose = "nero_mana"
    UpdateAbilityLayout(caster, tUpdatedAbilities)
end

nero_tactics = class({})

function nero_tactics:OnSpellStart()
    local caster = self:GetCaster()
    caster.ImperialChoose = "nero_tactics"
    UpdateAbilityLayout(caster, tUpdatedAbilities)
end

nero_defence = class({})

function nero_defence:OnSpellStart()
    local caster = self:GetCaster()
    caster.ImperialChoose = "nero_defence"
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
-- (the old getters were server-only and displayed as zero on the client)
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
    if choose == "nero_health" then
        t.bonus_damage = v("nero_health", "base_value") + (base_only and 0 or v("nero_health", "bonus_value"))
    elseif choose == "nero_mana" then
        local regen = v("nero_mana", "base_value") + (base_only and 0 or v("nero_mana", "bonus_value"))
        t.mana_regen, t.hp_regen = regen, regen
    elseif choose == "nero_defence" then
        t.armor = v("nero_defence", "base_armor") + (base_only and 0 or v("nero_defence", "bonus_armor"))
        t.mr    = v("nero_defence", "base_mr")    + (base_only and 0 or v("nero_defence", "bonus_mr"))
    end
    return t
end

modifier_imperial_buff = class({})

function modifier_imperial_buff:OnCreated(kv)
    self.bonus_damage = kv.bonus_damage or 0
    self.mana_regen   = kv.mana_regen or 0
    self.hp_regen     = kv.hp_regen or 0
    self.armor        = kv.armor or 0
    self.mr           = kv.mr or 0
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
        if self.parent.ImperialChoose == "nero_tactics" then
            local cooldown = self.rank*self.parent:FindAbilityByName("nero_tactics"):GetSpecialValueFor("bonus_value")
            local tresFontCD = caster:FindAbilityByName("nero_tres_new"):GetCooldownTimeRemaining()
            caster:FindAbilityByName("nero_tres_new"):EndCooldown()
            if tresFontCD - cooldown > 0 then
                caster:FindAbilityByName("nero_tres_new"):StartCooldown(tresFontCD - cooldown)
            end 

            local glaudiusCD = caster:FindAbilityByName("nero_gladiusanus_new"):GetCooldownTimeRemaining()
            caster:FindAbilityByName("nero_gladiusanus_new"):EndCooldown()
            if glaudiusCD - cooldown > 0 then
                caster:FindAbilityByName("nero_gladiusanus_new"):StartCooldown(glaudiusCD - cooldown)
            end 

            local rosaCD = caster:FindAbilityByName("nero_rosa_new"):GetCooldownTimeRemaining()
            caster:FindAbilityByName("nero_rosa_new"):EndCooldown()
            if rosaCD - cooldown > 0 then
                caster:FindAbilityByName("nero_rosa_new"):StartCooldown(rosaCD - cooldown)
            end
            self:Destroy()
        end
    end
end

function modifier_imperial_buff:OnRefresh(kv)
    self.bonus_damage = kv.bonus_damage or 0
    self.mana_regen   = kv.mana_regen or 0
    self.hp_regen     = kv.hp_regen or 0
    self.armor        = kv.armor or 0
    self.mr           = kv.mr or 0
    if IsServer() then
        self.rank = self.parent:FindModifierByName("modifier_nero_heat").rank
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

function modifier_imperial_buff_h:OnCreated(kv)
    self.bonus_damage = kv.bonus_damage or 0
    self.mana_regen   = kv.mana_regen or 0
    self.hp_regen     = kv.hp_regen or 0
    self.armor        = kv.armor or 0
    self.mr           = kv.mr or 0
    if IsServer() then
        self.parent = self:GetParent()
        local caster = self:GetCaster()
        --print(self.parent.ImperialChoose)
        self.rank = self.parent:FindModifierByName("modifier_nero_heat").rank
        if self.parent.ImperialChoose == "nero_tactics" then
            local cooldown = self.rank*self.parent:FindAbilityByName("nero_tactics"):GetSpecialValueFor("bonus_value")
            local tresFontCD = caster:FindAbilityByName("nero_tres_new"):GetCooldownTimeRemaining()
            caster:FindAbilityByName("nero_tres_new"):EndCooldown()
            if tresFontCD - cooldown > 0 then
                caster:FindAbilityByName("nero_tres_new"):StartCooldown(tresFontCD - cooldown)
            end 

            local glaudiusCD = caster:FindAbilityByName("nero_gladiusanus_new"):GetCooldownTimeRemaining()
            caster:FindAbilityByName("nero_gladiusanus_new"):EndCooldown()
            if glaudiusCD - cooldown > 0 then
                caster:FindAbilityByName("nero_gladiusanus_new"):StartCooldown(glaudiusCD - cooldown)
            end 

            local rosaCD = caster:FindAbilityByName("nero_rosa_new"):GetCooldownTimeRemaining()
            caster:FindAbilityByName("nero_rosa_new"):EndCooldown()
            if rosaCD - cooldown > 0 then
                caster:FindAbilityByName("nero_rosa_new"):StartCooldown(rosaCD - cooldown)
            end
            self:Destroy()
        end
    end
end

function modifier_imperial_buff_h:OnRefresh(kv)
    self.bonus_damage = kv.bonus_damage or 0
    self.mana_regen   = kv.mana_regen or 0
    self.hp_regen     = kv.hp_regen or 0
    self.armor        = kv.armor or 0
    self.mr           = kv.mr or 0
    if IsServer() then
        self.rank = self.parent:FindModifierByName("modifier_nero_heat").rank
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