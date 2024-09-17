vlad_instant_curse = class({})

if not IsServer() then
  return
end

function vlad_instant_curse:OnSpellStart()
  local caster = self:GetCaster()
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
  if caster.InstantSwapTimer then
  	caster:RemoveModifierByName("modifier_cursed_lance")
    caster:RemoveModifierByName("modifier_cursed_lance_bp")
  end
end

function vlad_instant_curse:GetCastAnimation()
  return nil
end

function vlad_instant_curse:GetAbilityTextureName()
  return "shadow_demon_disruption"
end
