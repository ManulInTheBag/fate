passive_anim_modifier_caster = passive_anim_modifier_caster or class({})

LinkLuaModifier("modifier_caster_health_state", "abilities/medea/passive_anim_modifier_caster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_caster_gait",         "abilities/medea/passive_anim_modifier_caster", LUA_MODIFIER_MOTION_NONE)

function passive_anim_modifier_caster:GetIntrinsicModifierName()
    return "modifier_caster_health_state"
end

modifier_caster_health_state = modifier_caster_health_state or class({})

function modifier_caster_health_state:IsHidden()      return true  end
function modifier_caster_health_state:IsPurgable()    return false end
function modifier_caster_health_state:RemoveOnDeath()  return false end
function modifier_caster_health_state:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_caster_health_state:DeclareFunctions()
    return { MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS }
end

function modifier_caster_health_state:GetActivityTranslationModifiers()
    local p = self:GetParent()
    if not p or p:IsNull() then return "" end
    local hp_pct = p:GetHealth() / p:GetMaxHealth()
    return hp_pct < 0.4 and "injured" or ""
end

function modifier_caster_health_state:OnCreated()
    if not IsServer() then return end

    local p = self:GetParent()
    if not p:HasModifier("modifier_caster_gait") then
        p:AddNewModifier(p, self:GetAbility(), "modifier_caster_gait", {})
    end
    
    self:StartIntervalThink(0.25)
end

function modifier_caster_health_state:OnIntervalThink()
    local p = self:GetParent()
    local hp_pct = p:GetHealth() / p:GetMaxHealth()
    local injured = hp_pct < 0.4
    if self.lastInjured ~= nil and injured ~= self.lastInjured then
        p:StopAnimation()
    end
    self.lastInjured = injured
end

modifier_caster_gait = modifier_caster_gait or class({})

function modifier_caster_gait:IsHidden()      return true  end
function modifier_caster_gait:IsPurgable()    return false end
function modifier_caster_gait:RemoveOnDeath()  return false end
function modifier_caster_gait:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_caster_gait:DeclareFunctions()
    return { MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS }
end

function modifier_caster_gait:GetActivityTranslationModifiers()
    local p = self:GetParent()
    if not p or p:IsNull() then return "slow" end
    return p:GetIdealSpeed() > 450 and "fast" or "slow"
end

function modifier_caster_gait:OnCreated()
    if not IsServer() then return end
    self:StartIntervalThink(0.1)
end

function modifier_caster_gait:OnIntervalThink()
    local p = self:GetParent()
    local fast = p:GetIdealSpeed() > 450
    if self.lastFast ~= nil and fast ~= self.lastFast then
        p:StopAnimation()
    end
    self.lastFast = fast
end