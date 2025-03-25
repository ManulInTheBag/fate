
demon_king_ignition = class({})

LinkLuaModifier("modifier_demon_king_ignition", "abilities/demon_king_nobunaga/demon_king_ignition", LUA_MODIFIER_MOTION_NONE)
function demon_king_ignition:OnSpellStart()
   self.caster = self:GetCaster() 
   --StartAnimation(self.caster, {duration=3, activity=ACT_DOTA_CAST_ABILITY_3, rate=1})
   if(self.caster:HasModifier("modifier_demon_king_ignition")) then
      self.caster:RemoveModifierByName("modifier_demon_king_ignition")
      self:StartCooldown(self:GetCooldown(-1))
   else
      self:EndCooldown()
      self:StartCooldown(self:GetSpecialValueFor("deactivate_cooldown"))
      self.caster:AddNewModifier(  self.caster, self, "modifier_demon_king_ignition", {duration = self:GetSpecialValueFor("maximum_duration")}) 
   end
end




modifier_demon_king_ignition = class({})
 

function modifier_demon_king_ignition:OnCreated()
    local ability = self:GetAbility()
    self.caster = self:GetCaster()
    self.spellamp = ability:GetSpecialValueFor("spell_amp_base")
    self.spellamp_cap = ability:GetSpecialValueFor("dmg_amp_cap")
    self.spellamp_per_second = ability:GetSpecialValueFor("dmg_amp_per_second")
    self.dmg_per_second = ability:GetSpecialValueFor("damage_per_second_base")
    self.dmg_per_second_cap = ability:GetSpecialValueFor("dmg_per_second_cap")
    self.dmg_per_second_increase = ability:GetSpecialValueFor("dmg_increase_per_second")
    self.tick_interval = ability:GetSpecialValueFor("tick_interval")
    self:StartIntervalThink(self.tick_interval)
    self.particle_ignition = ParticleManager:CreateParticle("particles/demon_king_nobunaga/demon_king_nobunaga_ignition.vpcf", PATTACH_ABSORIGIN_FOLLOW,   self.caster)
    ParticleManager:SetParticleControl(self.particle_ignition, 0,    self.caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(self.particle_ignition, 1, Vector( 10,0,0))
    self:AddParticle(self.particle_ignition, false, true, -1, true, false)
end

function modifier_demon_king_ignition:OnIntervalThink()
 --add check to be sure dmg is non-lethal
 if(not IsServer()) then return end
   DoDamage(  self.caster,   self.caster , self.dmg_per_second/100*self.tick_interval*self.caster:GetMaxHealth(), DAMAGE_TYPE_PURE,  0, self:GetAbility(), true)
 if self.dmg_per_second < self.dmg_per_second_cap then
    self.dmg_per_second = self.dmg_per_second + self.dmg_per_second_increase*self.tick_interval
    ParticleManager:SetParticleControl(self.particle_ignition, 1, Vector( self.dmg_per_second*20+10,0,0))
 end

 if self.spellamp< self.spellamp_cap then
    self.spellamp = self.spellamp + self.spellamp_per_second*self.tick_interval
 end

end

function modifier_demon_king_ignition:DeclareFunctions()
	return { MODIFIER_PROPERY_DAMAGEOUTGOING_PERCENTAGE }
end
 
function modifier_demon_king_ignition:OnDestroy() 
   if(not IsServer()) then return end
   self:GetAbility():EndCooldown()
   self:GetAbility():StartCooldown(self:GetAbility():GetCooldown(-1))
end
 


function modifier_demon_king_ignition:GetModifierDamageOutgoing_Percentage()
   return self.spellamp
end
--- yeah, its not spell amp, but all damage increase. Too lazy too change naming  


function modifier_demon_king_ignition:IsHidden()	return false end
function modifier_demon_king_ignition:RemoveOnDeath()return true end 
function modifier_demon_king_ignition:IsDebuff() 	return false end

 