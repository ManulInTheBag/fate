
demon_king_blink = class({})
LinkLuaModifier("modifier_maou_airborn_self", "abilities/demon_king_nobunaga/demon_king_blink", LUA_MODIFIER_MOTION_VERTICAL)
LinkLuaModifier("modifier_maou_invis", "abilities/demon_king_nobunaga/demon_king_blink", LUA_MODIFIER_MOTION_NONE)

function demon_king_blink:GetAOERadius()
	return self:GetSpecialValueFor("aoe_radius")
end
function demon_king_blink:CastFilterResultLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if not (IsServer() and IsLocked(hCaster)) and not ( IsServer() and not IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) ) then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function demon_king_blink:GetCustomCastErrorLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if IsServer() and IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) then
            return "#Is_Locked"
        end
    end
    return "#Wrong_Target_Location"
end


function demon_king_blink:OnSpellStart()
   local caster = self:GetCaster() 
   if IsServer() then
    EndAnimation(caster)
    StartAnimation(caster, {duration=1, activity=ACT_DOTA_CAST_DEAFENING_BLAST, rate=1})
   end 
   if caster.demon_king_attribute_2 then 
      caster:FindAbilityByName("demon_king_beam"):EndCooldown()
   end
   ProjectileManager:ProjectileDodge(caster) 
   local target = self:GetCursorPosition()
  caster:EmitSound("maou_blink_fire_start")
   local vector = (target- caster:GetAbsOrigin()):Normalized()
      vector.z = 0
    if (target - caster:GetAbsOrigin()):Length2D() > self:GetSpecialValueFor("range") then
         target = caster:GetAbsOrigin() + vector * self:GetSpecialValueFor("range")
    end
    if (target - caster:GetAbsOrigin()):Length2D() < 30 then
         target = caster:GetAbsOrigin() + vector * 30
    else
           caster:SetForwardVector(vector)
    end
 

   -- DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
   -- giveUnitDataDrivenModifier(caster, target, "locked", self:GetSpecialValueFor("lock_duration"))
   -- giveUnitDataDrivenModifier(caster, target, "stunned", 0.3)
   FindClearSpaceForUnit(caster, target, true)
   caster:AddNewModifier(caster, self, "modifier_maou_invis",{duration = self:GetSpecialValueFor("invis_dur") })
   caster:AddNewModifier(caster, self, "modifier_maou_airborn_self",{duration = self:GetSpecialValueFor("total_duration") + self:GetSpecialValueFor("invis_dur"), height = 700})
   --local afterBlinkPos = AbilityBlink(caster, target, self:GetSpecialValueFor("range"))
   
   giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", self:GetSpecialValueFor("total_duration"))  
   Timers:CreateTimer(self:GetSpecialValueFor("invis_dur"), function()
      self:PerformAttackTimer()
   
   
   end)
   
end

function demon_king_blink:PerformAttackTimer()
   local counter = 0
   local caster = self:GetCaster()
   local max_counter = self:GetSpecialValueFor("damage_ticks")
   local duration = self:GetSpecialValueFor("total_duration")
   local tick_duration = self:GetSpecialValueFor("total_duration") / max_counter
   local tick_damage =  self:GetSpecialValueFor("damage_total")/ (self:GetSpecialValueFor("damage_ticks") + 1)
   local aoe_radius = self:GetSpecialValueFor("aoe_radius")




   local effect_ground_hit = ParticleManager:CreateParticle("particles/maou_blink/maou_blink_main.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
   ParticleManager:SetParticleControl(effect_ground_hit, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*100)
    local effect_ground_hit3 = ParticleManager:CreateParticle("particles/maou_blink/maou_blink_main_ground.vpcf", PATTACH_WORLDORIGIN, caster)
   ParticleManager:SetParticleControl(effect_ground_hit3, 0, GetGroundPosition(caster:GetAbsOrigin(), caster))
   --




   Timers:CreateTimer(0, function()
       if (counter+1) >= max_counter then
            self:PerformDealingDamage(tick_damage*2, aoe_radius)
       else
             self:PerformDealingDamage(tick_damage, aoe_radius)
       end
        counter = counter + 1
        if counter == (3) then
            self.effect_ground_hit2 = ParticleManager:CreateParticle("particles/maou_blink/maou_blink_land.vpcf", PATTACH_WORLDORIGIN, caster)
            ParticleManager:SetParticleControl(self.effect_ground_hit2, 0, caster:GetAbsOrigin() + caster:GetForwardVector()*100)
            ParticleManager:SetParticleControl(self.effect_ground_hit2, 1, caster:GetAbsOrigin() + caster:GetForwardVector()*100)
            ParticleManager:SetParticleControl(self.effect_ground_hit2, 2, Vector(aoe_radius,aoe_radius,aoe_radius))
            caster:EmitSound("maou_blink_explosion")
            if caster.demon_king_attribute_1 then 
                caster:FindAbilityByName("demon_king_materialization"):CreateFireGroundSa(caster:GetAbsOrigin())
            end
        end
        if counter < max_counter then

            return tick_duration
        else
            caster:RemoveModifierByName("modifier_maou_airborn_self")
            ParticleManager:DestroyParticle(effect_ground_hit, true)
            ParticleManager:ReleaseParticleIndex(effect_ground_hit)
            ParticleManager:DestroyParticle(effect_ground_hit3, false)
            ParticleManager:ReleaseParticleIndex(effect_ground_hit3)
            ParticleManager:DestroyParticle(self.effect_ground_hit2, false)
            ParticleManager:ReleaseParticleIndex(self.effect_ground_hit2)
            FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
            return
        end
   
   end)


end

function demon_king_blink:PerformDealingDamage(tick_damage, aoe_radius)
   local caster = self:GetCaster()
      local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
					DoDamage(caster, v, tick_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
					
			end
		end

end

modifier_maou_invis = class({})

function modifier_maou_invis:OnCreated()
       		self.state = { [MODIFIER_STATE_INVISIBLE] = true,
    					   [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    					   --[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,
    					 }

end

function modifier_maou_invis:GetEffectName()
    return "particles/maou/maou_invis.vpcf"
end

function modifier_maou_invis:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end


function modifier_maou_invis:IsPurgable()
    return true
end

function modifier_maou_invis:IsDebuff()
    return false
end

function modifier_maou_invis:RemoveOnDeath()
    return true
end

function modifier_maou_invis:CheckState()
   return self.state
 end


 modifier_maou_airborn_self = class({})
function modifier_maou_airborn_self:IsHidden() return true end
function modifier_maou_airborn_self:IsDebuff() return false end
function modifier_maou_airborn_self:IsPurgable() return false end
function modifier_maou_airborn_self:IsPurgeException() return false end
function modifier_maou_airborn_self:RemoveOnDeath() return true end
function modifier_maou_airborn_self:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_maou_airborn_self:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_maou_airborn_self:CheckState()
    local state =   { 
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
						      [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                    }
    return state
end

function modifier_maou_airborn_self:OnCreated(table)
	if IsServer() then
		self.caster = self:GetCaster()
		self.parent = self:GetParent()
		self.ability = self:GetAbility()
		self.dashType = table.dashType
		self.height = table.height
		self.ticker = 0
      self.speed = self.height/0.4
			self:StartIntervalThink(FrameTime())
      self.parent:SetOrigin(self.caster:GetAbsOrigin() + Vector(0,0, self.height) )
		
		
	end
end
function modifier_maou_airborn_self:OnIntervalThink()
	self.ticker = self.ticker + FrameTime()
    self:UpdateVerticalMotion(self:GetParent(), FrameTime())

end
function modifier_maou_airborn_self:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_maou_airborn_self:UpdateVerticalMotion(me, dt)
	if self.ticker < 0.3 then
	
	else
		if IsServer() then
				local units_per_dt = self.speed * dt
				local parent_pos = self.parent:GetAbsOrigin()
				local next_pos = parent_pos + Vector(0,0,-1) * units_per_dt
				self.parent:SetOrigin(next_pos )
				--self.parent:SetForwardVector(self.direction )
		end
	end
end
 

function modifier_maou_airborn_self:OnDestroy()

 
    if IsServer() then
        --self.parent:InterruptMotionControllers(true)
    end
end