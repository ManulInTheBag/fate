vlad_battle_continuation = class({})
LinkLuaModifier("modifier_battle_continuation", "abilities/vlad/modifier_battle_continuation", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_battle_continuation_heal", "abilities/vlad/modifier_battle_continuation_heal", LUA_MODIFIER_MOTION_NONE)

--if not IsServer() then
--  return
--end

function vlad_battle_continuation:VFX1_Cast(caster)
	local PI1 = FxCreator("particles/custom/vlad/vlad_bc_cast.vpcf", PATTACH_CENTER_FOLLOW, caster,0, nil)
  ParticleManager:SetParticleControlEnt(PI1, 2, caster, PATTACH_CENTER_FOLLOW, nil, caster:GetAbsOrigin(), false)
  ParticleManager:SetParticleControlEnt(PI1, 3, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), false)
	Timers:CreateTimer(2, function()
    FxDestroyer(PI1, false)
  end)
end

function vlad_battle_continuation:CastFilterResult()
  local caster = self:GetCaster()
  local hp_condition = self:GetSpecialValueFor("hp_condition")
  if caster.ProtectionOfFaithAcquired then
    hp_condition = caster.MasterUnit2:FindAbilityByName("vlad_attribute_protection_of_faith"):GetSpecialValueFor("bc_hp_condition")
  end
  if caster:GetHealthPercent() >= hp_condition then
    return UF_FAIL_CUSTOM
  end
  return UF_SUCCESS
end

function vlad_battle_continuation:GetCustomCastError()
  return "Condition not met."
end

function vlad_battle_continuation:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  caster:AddNewModifier(caster, self, "modifier_battle_continuation",{duration = duration})

  if caster.ProtectionOfFaithAcquired then
    local bc_heal_duration = caster.MasterUnit2:FindAbilityByName("vlad_attribute_protection_of_faith"):GetSpecialValueFor("bc_heal_duration")
    caster:AddNewModifier(caster,self,"modifier_battle_continuation_heal",{duration = bc_heal_duration+0.1})
  end

  self:VFX1_Cast(caster)
  caster:EmitSound("Hero_LifeStealer.Rage")
  if caster.BloodletterAcquired then
    if caster:GetHealth()/caster:GetMaxHealth() <= 0.6 then
  
      local saDamage = caster.MasterUnit2:FindAbilityByName("vlad_attribute_bloodletter"):GetSpecialValueFor("damage")
      local saBleed = caster.MasterUnit2:FindAbilityByName("vlad_attribute_bloodletter"):GetSpecialValueFor("bleed")
      local explosionFx = ParticleManager:CreateParticle("particles/vlad/vlad_impale_fort.vpcf", PATTACH_WORLDORIGIN, nil)
      ParticleManager:SetParticleControl(explosionFx, 3, caster:GetAbsOrigin())
      ParticleManager:ReleaseParticleIndex(explosionFx)
      caster:EmitSound("Hero_Lycan.Attack")
      local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
        for k,v in pairs(targets) do
          DoDamage(caster, v, saDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
          caster:AddBleedStack(v, false, saBleed)
          giveUnitDataDrivenModifier(caster, v, "rooted", 0.5)
  
        end
    end
  end
end

function vlad_battle_continuation:GetAbilityTextureName()
  return "custom/vlad_battle_continuation"
end
