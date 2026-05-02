ozy_light_chacram_recast = class({})



function ozy_light_chacram_recast:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
    
    if caster.OzyChacramTarget == nil then return end
    self.LastHitTarget  = caster.OzyChacramTarget
    if caster:HasModifier("modifier_ozy_chacram_ability_change") then
        caster:RemoveModifierByName("modifier_ozy_chacram_ability_change")
    end
    caster:FindAbilityByName("ozy_light_chacram").casted = false
    Timers:RemoveTimer("ozymandias_chacram_checker")
    local StartPoint = self.LastHitTarget:GetAbsOrigin()
    local vector = (target - StartPoint):Normalized()
    local range = self:GetSpecialValueFor("distance")
    local EndPoint = StartPoint + vector * range
    local radius = self:GetSpecialValueFor("radius")
    local damage  = self:GetSpecialValueFor("damage")
    local stun_duration = self:GetSpecialValueFor("duration")
    print((StartPoint - EndPoint):Length2D())
	local enemies = FindUnitsInLine(
                                    caster:GetTeamNumber(),
                                    StartPoint,
                                    EndPoint,
                                    nil,
                                    radius,
                                    DOTA_UNIT_TARGET_TEAM_ENEMY,
                                    DOTA_UNIT_TARGET_ALL,
                                    0
                                )
    local closestUnit = nil
    local minimumDistance = 15000
    if #enemies > 1 then
        for k, v in pairs(enemies) do 
            if v~= self.LastHitTarget then
                local TempDistance = (v:GetAbsOrigin() - self.LastHitTarget:GetAbsOrigin()):Length2D()
                if  TempDistance < minimumDistance then
                    closestUnit = v
                    minimumDistance = TempDistance
                end
            end

        end
        if IsNotNull(closestUnit) then
            self:PerformRecastEffects(self.LastHitTarget, closestUnit)

        end
    else
        if IsNotNull(caster.Anchor) then
            if caster.Anchor:IsAlive() then
                local units = FindUnitsInLine(
                            caster:GetTeamNumber(),
                            StartPoint,
                            EndPoint,
                            nil,
                            radius,
                            DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                            DOTA_UNIT_TARGET_ALL,
                            DOTA_UNIT_TARGET_FLAG_INVULNERABLE
                            )
                for k, v in pairs(units) do 
                    if v ==  caster.Anchor then
                        closestUnit = v
                    end

                end
                if IsNotNull(closestUnit) then
                    self:PerformRecastEffects(self.LastHitTarget, closestUnit)

                end
            end
        end



    end
  
end 

function ozy_light_chacram_recast:CreateChainParticle(unit, point)
    local particle = ParticleManager:CreateParticle("particles/ozy/ozy_chacram_hook.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControl(particle, 1, point + Vector(0,0, 200))
    Timers:CreateTimer(0.3, function()
        ParticleManager:DestroyParticle(particle, true)
        ParticleManager:ReleaseParticleIndex(particle)
    
    end)


end

function ozy_light_chacram_recast:CreateChainParticleUnits(unit, unit2)
    local particle = ParticleManager:CreateParticle("particles/ozy/ozy_chacram_hook.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControlEnt(particle, 1, unit2, PATTACH_ABSORIGIN_FOLLOW ,"attach_hitloc" , Vector(0,0,100), true)
    Timers:CreateTimer(0.3, function()
        ParticleManager:DestroyParticle(particle, true)
        ParticleManager:ReleaseParticleIndex(particle)
    
    end)


end

function ozy_light_chacram_recast:PerformRecastEffects(unit1, unit2)
    if IsNotNull(unit1) and IsNotNull(unit2) then
        local caster = self:GetCaster()
        if unit1:HasModifier("modifier_knockback") then
            unit1:RemoveModifierByName("modifier_knockback")
        end
        if unit2:HasModifier("modifier_knockback") then
            unit2:RemoveModifierByName("modifier_knockback")
        end
        local IsTargetPillar = (unit2:GetUnitName() == "ozy_anchor")
        local pullOrigin = Vector(0,0,0)
        local vectorFromU1ToU2 = (unit1:GetAbsOrigin() - unit2:GetAbsOrigin())
        local distance = vectorFromU1ToU2:Length2D()
        if IsTargetPillar or IsKnockbackImmune(unit2) then 
            if IsKnockbackImmune(unit1) then return end
            pullOrigin = unit2:GetAbsOrigin() + vectorFromU1ToU2:Normalized() * 50
            local knockback1 = { should_stun = false,
                                knockback_duration = 0.3,
                                duration = 0.3,
                                knockback_distance = -(unit1:GetAbsOrigin() - pullOrigin):Length2D(),
                                knockback_height = 30,
                                center_x =pullOrigin.x,
                                center_y = pullOrigin.y,
                                center_z = pullOrigin.z }
            unit1:AddNewModifier(caster, self, "modifier_knockback", knockback1)
            DoDamage(caster, unit1, self:GetSpecialValueFor("damage"), self:GetAbilityDamageType(), 0, self, false)
            if not unit1:IsMagicImmune() then
                giveUnitDataDrivenModifier(caster, unit1, "stunned", self:GetSpecialValueFor("duration"))
            end
            self:CreateChainParticle(unit1, pullOrigin)
        else
            if IsKnockbackImmune(unit1) then 
                pullOrigin = unit1:GetAbsOrigin() + vectorFromU1ToU2:Normalized() * 50
                local knockback1 = { should_stun = false,
                    knockback_duration = 0.3,
                    duration = 0.3,
                    knockback_distance = -(unit2:GetAbsOrigin() - pullOrigin):Length2D(),
                    knockback_height = 30,
                    center_x =pullOrigin.x,
                    center_y = pullOrigin.y,
                    center_z = pullOrigin.z }
                unit2:AddNewModifier(caster, self, "modifier_knockback", knockback1)
                self:CreateChainParticle(unit2, pullOrigin)
            else
                pullOrigin = unit2:GetAbsOrigin() + vectorFromU1ToU2 * 0.5
                DoDamage(caster, unit1, self:GetSpecialValueFor("damage"), self:GetAbilityDamageType(), 0, self, false)
                if not unit1:IsMagicImmune() then
                    giveUnitDataDrivenModifier(caster, unit1, "stunned", self:GetSpecialValueFor("duration"))
                end
                local knockback1 = { should_stun = false,
                    knockback_duration = 0.3,
                    duration = 0.3,
                    knockback_distance = -(unit2:GetAbsOrigin() - pullOrigin):Length2D(),
                    knockback_height = 100,
                    center_x =pullOrigin.x,
                    center_y = pullOrigin.y,
                    center_z = pullOrigin.z }
                 
                unit2:AddNewModifier(caster, self, "modifier_knockback", knockback1)

                    local knockback2 = { should_stun = false,
                    knockback_duration = 0.3,
                    duration = 0.3,
                    knockback_distance = -(unit1:GetAbsOrigin() - pullOrigin):Length2D(),
                    knockback_height = 100,
                    center_x =pullOrigin.x,
                    center_y = pullOrigin.y,
                    center_z = pullOrigin.z }
                unit1:AddNewModifier(caster, self, "modifier_knockback", knockback2)
                self:CreateChainParticleUnits(unit1, unit2)
            end
            DoDamage(caster, unit2, self:GetSpecialValueFor("damage"), self:GetAbilityDamageType(), 0, self, false)
            if not unit2:IsMagicImmune() then
                giveUnitDataDrivenModifier(caster, unit2, "stunned", self:GetSpecialValueFor("duration"))
            end
            
            

        end
       
    end
end
