
demon_king_breath = class({})
LinkLuaModifier("modifier_merlin_self_pause","abilities/merlin/merlin_orbs", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vision_provider", "abilities/general/modifiers/modifier_vision_provider", LUA_MODIFIER_MOTION_NONE)
function demon_king_breath:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=0.9, activity=ACT_DOTA_CAST_ABILITY_6, rate=1.2})
    EmitSoundOn("maou_breath_cast", caster)
end

function demon_king_breath:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
    caster:StopSound("maou_breath_cast")
end


function demon_king_breath:GetAOERadius()
	return self:GetSpecialValueFor("aoe_radius")
end


function demon_king_breath:OnSpellStart()
   local caster = self:GetCaster() 
   local point = self:GetCursorPosition()
   local castRange = self:GetSpecialValueFor("range")
   local casterPos = caster:GetAbsOrigin()
   local vector  = (point - casterPos):Normalized()
   vector.z = 0
   local realRange = (point - casterPos):Length2D()
   local additionalCastPoint = self:GetSpecialValueFor("total_duration")
   local minRange = self:GetSpecialValueFor("minimal_range")
   caster:AddNewModifier(caster, nil, "modifier_vision_provider", { Duration = 1.5})
   if realRange < minRange then
         point = casterPos + (caster:GetForwardVector()):Normalized() * minRange
   end
   if realRange > castRange then
        point = casterPos + vector * castRange
   end
   local vectorWithDistance = (point - casterPos)
   vectorWithDistance.z = 0
   caster:AddNewModifier(caster, self, "modifier_merlin_self_pause", {Duration = additionalCastPoint}) 
   --giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", additionalCastPoint)  
   Timers:CreateTimer(additionalCastPoint, function()
        local casterpos = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("mouth")) 
        local breath_effect = ParticleManager:CreateParticle("particles/maou/fire_breath/maou_breathe_fire_.vpcf", PATTACH_CUSTOMORIGIN, caster)
        ParticleManager:SetParticleControl(breath_effect, 0, casterpos)
        ParticleManager:SetParticleControl(breath_effect, 1, vectorWithDistance * 2)
        ParticleManager:SetParticleShouldCheckFoW(breath_effect, false)
        Timers:CreateTimer(0.5, function()
        
            ParticleManager:DestroyParticle(breath_effect, false)
            ParticleManager:ReleaseParticleIndex(breath_effect)
        end)
        local projectileBreath = 
            {
                Ability = self,
                EffectName = "",
                iMoveSpeed = vectorWithDistance:Length2D() * 2,
                vSpawnOrigin = caster:GetOrigin(),
                fDistance = castRange,
                fStartRadius = 300,
                fEndRadius = 300,
                Source = caster,
                bHasFrontalCone = true,
                bReplaceExisting = true,
                iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
                iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
                iUnitTargetType = DOTA_UNIT_TARGET_ALL,
                fExpireTime = GameRules:GetGameTime() + 2.0,
                bDeleteOnHit = false,
                vVelocity = vectorWithDistance * 2
            }
        local projectile = ProjectileManager:CreateLinearProjectile(projectileBreath)
        caster:EmitSound("maou_breath_projectile_release")
   end)
   Timers:CreateTimer(0.5 + additionalCastPoint, function()
		self.BasicRadius = ParticleManager:CreateParticle("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(self.BasicRadius, 0, point)
		ParticleManager:SetParticleControl(self.BasicRadius, 1, Vector(1,0.1,0.1))
		ParticleManager:SetParticleControl(self.BasicRadius, 2, Vector(self:GetSpecialValueFor("aoe_radius"),self:GetSpecialValueFor("black_hole_delay") + self:GetSpecialValueFor("black_hole_duration"),0))	
        ParticleManager:SetParticleShouldCheckFoW(self.BasicRadius, false)
        self.BlackHoleParticlePreCast = ParticleManager:CreateParticle("particles/maou/breath_blackhole/maou_black_hole_center_precast.vpcf", PATTACH_WORLDORIGIN, nil)
    	ParticleManager:SetParticleControl(self.BlackHoleParticlePreCast, 0, point)
        ParticleManager:SetParticleShouldCheckFoW(self.BlackHoleParticlePreCast, false)
            EmitSoundOnLocationWithCaster(point, "maou_blackhole_deploy", self:GetCaster())
        
   end)
   Timers:CreateTimer(additionalCastPoint +self:GetSpecialValueFor("black_hole_delay") + 0.5, function()
        
        self:CreateBlackHole(point, self:GetSpecialValueFor("black_hole_duration"), self:GetSpecialValueFor("aoe_radius"), self:GetSpecialValueFor("black_hole_pull_str"), 
                    self:GetSpecialValueFor("black_hole_damage") + ( caster.demon_king_attribute_5 and caster.MasterUnit2:FindAbilityByName("demon_king_attribute_5"):GetSpecialValueFor("hole") * caster:GetIntellect() or 0))
        caster:EmitSound("maou_breath_cast_2")

   end)
end


function demon_king_breath:CreateBlackHole(position, duration, radius, pull_str, dmg)
    local caster = self:GetCaster() 
    local timerCounter = 0
    local timerCounterMax = duration * 10
    local timePerTick = 0.1
    Timers:RemoveTimer("maou_blackhole")
    self:RemoveBlackHoleEffects(self.endpos)
    self.endpos = position
    self.Dummy = CreateUnitByName("dummy_unit", position, false, nil, nil, caster:GetTeamNumber())
	self.Dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.Dummy:SetAbsOrigin(position)
    EmitSoundOn("maou_blackhole_1", self.Dummy)
    EmitSoundOn("maou_blackhole_3", self.Dummy)
    EmitSoundOn("maou_blackhole_4", self.Dummy)
    self.BlackHoleParticle = ParticleManager:CreateParticle("particles/maou/breath_blackhole/enigma_blackhole_ti5_2.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.BlackHoleParticle, 0, position)
    ParticleManager:SetParticleShouldCheckFoW(self.BlackHoleParticle, false)
    self.BasicRadius2 = ParticleManager:CreateParticle("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(self.BasicRadius2, 0, position)
	ParticleManager:SetParticleControl(self.BasicRadius2, 1, Vector(1,0.1,0.1))
	ParticleManager:SetParticleControl(self.BasicRadius2, 2, Vector(radius,duration,0))	
    if caster.demon_king_attribute_1 then 
      caster:FindAbilityByName("demon_king_materialization"):CreateFireGroundSa(position)
   end

    ParticleManager:SetParticleShouldCheckFoW(self.BasicRadius2, false)
    local knockback1 = { should_stun = false,
                        knockback_duration = 0.1,
                        duration = 0.1,
                        knockback_distance = -pull_str/10,
                        knockback_height = 0,
                        center_x =position.x,
                        center_y = position.y,
                        center_z = position.z }
    Timers:CreateTimer("maou_blackhole", {callback = function()
        if timerCounter > timerCounterMax then
                self:RemoveBlackHoleEffects(position)
                self.endpos = nil
            return
        end
        local targets = FindUnitsInRadius(caster:GetTeam(), position  , nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for k,v in pairs(targets) do
            DoDamage(caster, v, dmg/10 , DAMAGE_TYPE_MAGICAL, 0, self, false)
            if( not IsKnockbackImmune(v)) then
				v:RemoveModifierByName("modifier_knockback")
                v:AddNewModifier(caster, self, "modifier_knockback", knockback1)
			end

        end
        timerCounter = timerCounter + 1
        return timePerTick

    end})


end

function demon_king_breath:RemoveBlackHoleEffects(endpos)
    if self.BlackHoleParticle then
        ParticleManager:DestroyParticle(self.BlackHoleParticle, false)
        ParticleManager:ReleaseParticleIndex(self.BlackHoleParticle)
    end
    if self.BasicRadius then
        ParticleManager:DestroyParticle(self.BasicRadius, true)
        ParticleManager:ReleaseParticleIndex(self.BasicRadius)
    end
    if self.BlackHoleParticlePreCast then
        ParticleManager:DestroyParticle(self.BlackHoleParticlePreCast, true)
        ParticleManager:ReleaseParticleIndex(self.BlackHoleParticlePreCast)
    end
    if self.BasicRadius2 then
        ParticleManager:DestroyParticle(self.BasicRadius2, true)
        ParticleManager:ReleaseParticleIndex(self.BasicRadius2)
    end
    if self.Dummy ~= nil then
         self.Dummy:RemoveSelf()
         self.Dummy = nil
    end
    
    if endpos then 
        EmitSoundOnLocationWithCaster(endpos, "maou_blackhole_2", self:GetCaster())
    end
end



function demon_king_breath:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage_fire") + ( caster.demon_king_attribute_5 and caster.MasterUnit2:FindAbilityByName("demon_king_attribute_5"):GetSpecialValueFor("fire") * caster:GetIntellect() or 0)
	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
    caster:FindAbilityByName("demon_king_materialization"):IncreaseStackCount(1)

end


