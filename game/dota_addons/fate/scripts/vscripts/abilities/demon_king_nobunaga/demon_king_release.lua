
demon_king_release = class({})

LinkLuaModifier("modifier_demon_king_release", "abilities/demon_king_nobunaga/demon_king_release", LUA_MODIFIER_MOTION_NONE)
function demon_king_release:GetAOERadius()
   
	return self:GetSpecialValueFor("aoe_radius")
end

LinkLuaModifier("modifier_demon_king_extermination_burn", "abilities/demon_king_nobunaga/demon_king_extermination", LUA_MODIFIER_MOTION_NONE)
function demon_king_release:OnSpellStart()
   local caster = self:GetCaster() 
   local time = 1 
   EndAnimation(caster)
   StartAnimation(caster, {duration=time, activity=ACT_DOTA_RAZE_1, rate=1})
   caster:EmitSound("maou_release_start")
   giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled",  time)  
   self:PerformAttackTimer()
end



function demon_king_release:PerformAttackTimer()
   local counter = 0
   local caster = self:GetCaster()
   local max_counter = self:GetSpecialValueFor("damage_ticks")
   local duration = self:GetSpecialValueFor("total_duration")
   local tick_duration = self:GetSpecialValueFor("total_duration") / max_counter
   local stacks = caster:GetModifierStackCount("demon_king_materialization", caster)
   local damage_total = math.min(caster:GetMaxHealth(), self:GetSpecialValueFor("total_damage_base")  + self:GetSpecialValueFor("damage_per_stack") * stacks)

   local tick_damage =  damage_total/ self:GetSpecialValueFor("damage_ticks")
   local aoe_radius = self:GetSpecialValueFor("aoe_radius")

   local effect_ground_hit = ParticleManager:CreateParticle("particles/maou/maou_release/maou_release_.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
   ParticleManager:SetParticleControl(effect_ground_hit, 0, caster:GetAbsOrigin())
   ParticleManager:SetParticleControl(effect_ground_hit,1, Vector(500, 0,0))

   local onHeroEffect = ParticleManager:CreateParticle("particles/maou/ambient_jopa/ambient_jopa.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
   ParticleManager:SetParticleControl(onHeroEffect, 0, caster:GetAbsOrigin())

   caster:EmitSound("maou_release_voice")
   caster:AddNewModifier(caster, self, "modifier_demon_king_release", {duration = duration})

   Timers:CreateTimer(0, function()
      self:PerformDealingDamage(tick_damage, aoe_radius)
         if counter == 1 then
            caster:EmitSound("maou_release")
         end
        counter = counter + 1
        if counter < max_counter then

            return tick_duration
        else
            --FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
            ParticleManager:DestroyParticle(effect_ground_hit, false)
            ParticleManager:ReleaseParticleIndex(effect_ground_hit)
            ParticleManager:DestroyParticle(onHeroEffect, false)
            ParticleManager:ReleaseParticleIndex(onHeroEffect)
            caster:RemoveModifierByName("demon_king_materialization")
            return
        end
   
   end)


end

function demon_king_release:PerformDealingDamage(tick_damage, aoe_radius)
   local caster = self:GetCaster()
      local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
					DoDamage(caster, v, tick_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
					
			end
		end
      if caster:GetHealthPercent() > 20 then
         DoDamage(caster, caster, tick_damage, DAMAGE_TYPE_PURE, 0, self, false)
      end

end

modifier_demon_king_release = class({})

function modifier_demon_king_release:IsHidden()
	return false 
end

function modifier_demon_king_release:RemoveOnDeath()
	return true
end




function modifier_demon_king_release:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
	MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL }

	return funcs
end

function modifier_demon_king_release:GetAbsoluteNoDamagePhysical() 
	return 1
end

function modifier_demon_king_release:GetAbsoluteNoDamageMagical() 
	return 1
end