modifier_bleed = class({})

require("libraries/effect_bars")

function modifier_bleed:DeclareFunctions()
  local funcs = {
  MODIFIER_EVENT_ON_RESPAWN
  }
  return funcs
end

-- Счётчик стаков рисует ряд эффектов над хелсбаром (libraries/effect_bars.lua +
-- panorama effect_bars.js); раньше это был попап vlad_cl_popup только для Влада
-- с таймером перерисовки при выходе цели из тумана.
if IsServer() then
  function modifier_bleed:OnCreated()
    self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("interval"))
    EffectBars:Track(self)
  end

  function modifier_bleed:OnIntervalThink()
    local ability = self:GetAbility()
    local dmg = ability:GetSpecialValueFor("dmg")*self:GetStackCount()
    DoDamage(self:GetCaster(), self:GetParent(), dmg, DAMAGE_TYPE_MAGICAL, 0, ability, false)
  end

  function modifier_bleed:OnDestroy()
    self:StartIntervalThink(-1)
    EffectBars:Untrack(self)
  end
  function modifier_bleed:OnRespawn()
    self:Destroy()
  end
end

function modifier_bleed:IsHidden()
  return false
end

function modifier_bleed:IsDebuff()
  return true
end

function modifier_bleed:RemoveOnDeath()
  return true
end

function modifier_bleed:GetTexture()
  return "custom/vlad_transfusion2"
end
