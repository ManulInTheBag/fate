modifier_rending = class({})

function modifier_rending:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_rending:DeclareFunctions()
  local funcs = {
	--MODIFIER_EVENT_ON_ATTACK_LANDED,
  MODIFIER_EVENT_ON_RESPAWN
  }
  return funcs
end

function modifier_rending:OnAttackLanded(keys)
  local caster = self:GetCaster()
	local ability = self:GetAbility()
	local target = keys.target
  if target == caster:GetAttackTarget() and not caster.InnocentMonsterAcquired then
     ability:AddStack(target,true)
  end
end

if IsServer() then
  function modifier_rending:OnRespawn(keys)   
    local parent = self:GetParent()
    if keys.unit ~= parent then return end
    if parent:HasModifier("modifier_hero_selection_skin") then
      print(self.particle == nil)
      if (self.particle == nil) then
          self.particle = ParticleManager:CreateParticle("particles/verg/verg_blade.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
          ParticleManager:SetParticleControlEnt(self.particle , 0,parent, PATTACH_POINT_FOLLOW, "attach_lance_tip", Vector(0,0,0), false) 
          ParticleManager:SetParticleControlEnt(self.particle , 1,parent, PATTACH_POINT_FOLLOW, "attach_lance_tip_3", Vector(0,0,0), false) 
      end
    end
    if parent.InnocentMonsterAcquired and not parent:HasModifier("modifier_innocent_monster") then
      parent:AddNewModifier(parent, parent.MasterUnit2:FindAbilityByName("vlad_attribute_innocent_monster"), "modifier_innocent_monster", {})
    end
    if parent.ProtectionOfFaithAcquired and not parent:HasModifier("modifier_protection_of_faith") then
      parent:AddNewModifier(parent, parent.MasterUnit2:FindAbilityByName("vlad_attribute_protection_of_faith"), "modifier_protection_of_faith", {})
    end
    if parent.ImprovedImpalingAcquired and not parent:HasModifier("modifier_improved_impaling") then
      parent:AddNewModifier(parent, parent.MasterUnit2:FindAbilityByName("vlad_attribute_improved_impaling"), "modifier_improved_impaling", {})
    end
  end
end
function modifier_rending:IsHidden()
  return true
end

function modifier_rending:IsDebuff()
  return false
end

function modifier_rending:RemoveOnDeath()
  return false
end
