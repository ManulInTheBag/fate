LinkLuaModifier("modifier_okada_dmg_reduct", "abilities/okada/okada_ult", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okada_statusfx", "abilities/okada/okada_ult", LUA_MODIFIER_MOTION_NONE)
okada_ult = class({})

function okada_ult:OnAbilityPhaseStart()
    if self:GetCaster():HasModifier("modifier_okada_manslayer") then
        self:GetCaster():EmitSound("okada_ult_cast_2")
    else
        self:GetCaster():EmitSound("okada_ult_cast")
    end
end

function okada_ult:PerformLastStrike(unit, caster, target, dmgMod)
    local initorigin = target:GetForwardVector()*-300 + target:GetAbsOrigin()
    unit:SetAbsOrigin(initorigin)
    local diff = (target:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized()
    unit:FaceTowards(target:GetAbsOrigin())
    unit:SetForwardVector(Vector(diff.x, diff.y, 0))

    Timers:CreateTimer(0.3, function()
        local sImagePFX = "particles/okada/okada_slash_ult.vpcf"
        if caster:HasModifier("modifier_okada_manslayer") then
            sImagePFX = "particles/okada/okada_slash_ult_red.vpcf"
        end
        local point1 = target:GetAbsOrigin() + target:GetRightVector() * -200 + Vector(0,0, 50)
        local point2 = target:GetAbsOrigin() + target:GetRightVector() * 200 + Vector(0,0, 350)
        self:CreateLashSlashParticle(point1, point2, sImagePFX)
    
    end)
    Timers:CreateTimer(0.4, function()
        local damage = self:GetSpecialValueFor("damage")
        if target and target:IsAlive() then
            target:EmitSound("okada_ult_last_1")
            target:EmitSound("okada_ult_last_2")
            target:EmitSound("okada_e_slash")
			DoDamage(caster, target, damage * dmgMod, DAMAGE_TYPE_PHYSICAL, DOTA_DAMAGE_FLAG_NONE, self, false)
		end
        if unit ~= caster then
            unit:RemoveSelf()
        else
            FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
        end
    end)


end

function okada_ult:HasItemInTable(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function okada_ult:indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end

function okada_ult:CreateSlashParticle(location, particle)
    local fx = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(fx, 7, location)
    ParticleManager:SetParticleControl(fx, 0, location)
    ParticleManager:SetParticleControl(fx, 1, location)
    ParticleManager:SetParticleControl(fx, 2, location)
    ParticleManager:SetParticleShouldCheckFoW(fx, false)
    ParticleManager:ReleaseParticleIndex(fx)

end

function okada_ult:CreateLashSlashParticle(location1, location2, particle)
    local fx = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(fx, 0, location1)
    ParticleManager:SetParticleControl(fx, 2, location2)
    ParticleManager:SetParticleShouldCheckFoW(fx, false)
    ParticleManager:ReleaseParticleIndex(fx)

end

function okada_ult:PerformStrike(unit, caster, target, dmgMod, soundCounter)
    
    local point = PointOnCircle(GetGroundPosition(target:GetAbsOrigin(), target), 150, math.random(0, 359))
    unit:SetAbsOrigin(point)
    local diff = (target:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized()
    unit:SetForwardVector(Vector(diff.x, diff.y, 0))
    local sImagePFX = "particles/okada/okada_dash_slashes.vpcf"
    if caster:HasModifier("modifier_okada_manslayer") then
        sImagePFX = "particles/okada/okada_dash_slashes_red.vpcf"
    end
    self:CreateSlashParticle(target:GetAbsOrigin() + Vector(0,0, 50),sImagePFX )


    Timers:CreateTimer(0.1, function()
        local damage = self:GetSpecialValueFor("damage")
        if target and target:IsAlive() then
            target:EmitSound("okada_ult_"..soundCounter)
			DoDamage(caster, target, damage* dmgMod, DAMAGE_TYPE_PHYSICAL, DOTA_DAMAGE_FLAG_NONE, self, false)
		end
    end)
end

function okada_ult:PlayRandomAttackAnimation(unit, animTable)
    if IsServer() then
        local number = math.random( #animTable )
        local value = animTable[number  ]
        table.remove(animTable, number)
        --EndAnimation(self.hParent)
       StartAnimation( unit, {duration=0.2, activity=value , rate=6})
       return animTable
    end
end

function okada_ult:SearchForRandomTarget(unit, radius, point, oldTarget, TargetToIgnore)
    local enemies = FindUnitsInRadius(  self:GetCaster():GetTeamNumber(),
                point,
                nil,
                radius,
                DOTA_UNIT_TARGET_TEAM_ENEMY,
                DOTA_UNIT_TARGET_ALL,
                DOTA_UNIT_TARGET_FLAG_NONE,
                FIND_ANY_ORDER,
                false)
    local indexOfUnit = self:indexOf(enemies, TargetToIgnore)
    if TargetToIgnore ~= nil   then
        if indexOfUnit ~= nil then
            table.remove(enemies, indexOfUnit)
        end
    end
    if #enemies > 1 then
            if enemies[2] ~= oldTarget then
                return enemies[2]
            else
                return enemies[1]
            end
    elseif #enemies == 1 then
        return enemies[1] 
    else
    
        if self:GetCaster() ~= unit then
            unit:RemoveSelf()
        end
    end


     
end

function okada_ult:PefrormAttackTimer(unit, caster, targetInnit, dmgMod, shouldJumpTargets, TargetToIgnore)
    local animTable = {
        ACT_DOTA_RAZE_1,
        ACT_DOTA_RAZE_2,
        ACT_DOTA_RAZE_3,
        ACT_DOTA_ICE_VORTEX

    }
    local counterAnim = 1
    local counterAnimMax = #animTable
    local counterPerform = 0
    local counterPerformMax = 3
    local animationTimerTime  = 0.15
    local totalPerformTimerTime = animationTimerTime * counterAnimMax
    local soundCounterMax = 3
    local soundCounter = 1
    local target = targetInnit
    animTable = self:PlayRandomAttackAnimation(unit, animTable)
    self:PerformStrike(unit, caster, target, dmgMod, soundCounter)
    Timers:CreateTimer(animationTimerTime, function()
        if not caster:IsAlive() then
            return
        end
         if not target:IsAlive()  then
            if self:GetAutoCastState() then
                target = self:SearchForRandomTarget(unit, 500, target:GetAbsOrigin(), target, TargetToIgnore)
            else
                return
            end
        end
        if soundCounter >= soundCounterMax then
            soundCounter = 0
        end
        if counterAnim >= counterAnimMax then
            animTable = {
                ACT_DOTA_RAZE_1,
                ACT_DOTA_RAZE_2,
                ACT_DOTA_RAZE_3,
                ACT_DOTA_ICE_VORTEX
            }
            counterAnim = 0
            counterPerform = counterPerform + 1
        end
        if counterPerform >= counterPerformMax then 
            self:PerformLastStrike(unit, caster, target, dmgMod * 3)
            StartAnimation( unit, {duration=0.5, activity=ACT_DOTA_CAST_ICE_WALL , rate=2})
            return
        end
        counterAnim = counterAnim + 1
        soundCounter = soundCounter + 1
        self:PerformStrike(unit, caster, target, dmgMod, soundCounter)
        animTable = self:PlayRandomAttackAnimation(unit, animTable)
        if shouldJumpTargets then
             target = self:SearchForRandomTarget(unit, 500, target:GetAbsOrigin(), target, TargetToIgnore)
        end
        return animationTimerTime
    end)
    

end

function okada_ult:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if IsSpellBlocked(target) then return end 
    local duration = 0.15 * 13 + 0.2
    self:PefrormAttackTimer(caster, caster, target,  1, false)
    caster:AddNewModifier(caster, nil, "modifier_phased", {duration = duration})
	giveUnitDataDrivenModifier(caster, caster, "dragged", duration)
	caster:AddNewModifier(caster, nil, "modifier_okada_dmg_reduct", {duration = duration})
    if caster:HasModifier("modifier_okada_manslayer") then
        caster:EmitSound("okada_r2")
        local secondTarget = self:SearchForRandomTarget(caster,500, target:GetAbsOrigin(),target, target )
        if secondTarget ~= nil then
            local Dummy1 = CreateUnitByName("okada_clone", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
            Dummy1:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
            Dummy1:SetModelScale(1.3)
            Dummy1:SetDayTimeVisionRange(0)
            Dummy1:SetNightTimeVisionRange(0)
            Dummy1:AddNewModifier(caster, nil, "modifier_okada_statusfx", {duration = duration})

            Dummy1:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY )
            self:PefrormAttackTimer(Dummy1, caster, secondTarget,  0.5, true, target)
            local Dummy2 = CreateUnitByName("okada_clone", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
            Dummy2:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
            Dummy2:SetModelScale(1.3)
            Dummy2:SetDayTimeVisionRange(0)
            Dummy2:SetNightTimeVisionRange(0)
            Dummy2:AddNewModifier(caster, nil, "modifier_okada_statusfx", {duration = duration})
	        
            Dummy2:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY )
            self:PefrormAttackTimer(Dummy2, caster, secondTarget,  0.5, true, target)
        end
    else
        caster:EmitSound("okada_r")
    end
	
end






modifier_okada_dmg_reduct = class({})

function modifier_okada_dmg_reduct:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	   }

	return funcs
end




function modifier_okada_dmg_reduct:IsHidden() 
	return true
end

function modifier_okada_dmg_reduct:IsDebuff() 
	return false
end


function modifier_okada_dmg_reduct:GetModifierIncomingDamage_Percentage() 
	return -45
end

modifier_okada_statusfx = class({})
function modifier_okada_statusfx:IsHidden() return true end
function modifier_okada_statusfx:IsDebuff() return false end
function modifier_okada_statusfx:RemoveOnDeath() return true end

function modifier_okada_statusfx:GetStatusEffectName()
    return "particles/econ/items/invoker/invoker_ti7/status_effect_alacrity_ti7.vpcf"
end

 





