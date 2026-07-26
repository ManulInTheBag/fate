-- lancelot_nuke — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/lancelot/lancelot_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lancelot_nuke = class({})

LinkLuaModifier("modifier_nuke_cooldown", "abilities/lancelot/lancelot_nuke", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/lancelot_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnNukeStart, SpinInCircle

OnNukeStart = function(keys)
    local caster = keys.caster
    local ability = keys.ability
    local targetPoint = keys.ability:GetCursorPosition()
    if not IsInSameRealm(caster:GetAbsOrigin(), targetPoint) then 
        caster:SetMana(caster:GetMana()+keys.ability:GetManaCost(keys.ability:GetLevel()-1)) 
        keys.ability:EndCooldown()
        SendErrorMessage(caster:GetPlayerOwnerID(), "#Invalid_Location")
        return
    end

    EmitGlobalSound("Lancelot.Nuke_Alert") 
    if math.random(1,2) == 1 then
        EmitGlobalSound("Nuclear_Launch_Detected")
    else
        EmitGlobalSound("Tactical_Nuke_Incoming")
    end


    -- Set master's combo cooldown
    local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(keys.ability:GetCooldown(1))
    caster:AddNewModifier(caster, ability, "modifier_nuke_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})

    caster:FindAbilityByName("lancelot_combo_arondite_overload"):StartCooldown(150)

    local nukemsg = {
        message = "Engaging Enemy, HQ.",
        duration = 2.0
    }
    FireGameEvent("show_center_message",nukemsg)

    local f16 = CreateUnitByName("f16_dummy", Vector(0, 0, 0), true, nil, nil, caster:GetTeamNumber())
    f16:SetOwner(caster)
    local visiondummy = CreateUnitByName("sight_dummy_unit", targetPoint, false, keys.caster, keys.caster, keys.caster:GetTeamNumber())
    visiondummy:SetDayTimeVisionRange(1500)
    visiondummy:SetNightTimeVisionRange(1500)
    visiondummy:AddNewModifier(caster, nil, "modifier_kill", {duration = 8})

    local unseen = visiondummy:FindAbilityByName("dummy_unit_passive")
    unseen:SetLevel(1)
    local nukeMarker = ParticleManager:CreateParticle( "particles/custom/lancelot/lancelot_nuke_calldown_marker_c.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl( nukeMarker, 0, targetPoint)
    ParticleManager:SetParticleControl( nukeMarker, 1, Vector(300, 300, 300))
    -- Destroy particle after delay
    Timers:CreateTimer( 3.0, function()
        ParticleManager:DestroyParticle( nukeMarker, false )
        ParticleManager:ReleaseParticleIndex( nukeMarker )
    end)

    -- Create F16 nunit
    Timers:CreateTimer(1.97, function()
        EmitGlobalSound("Lancelot.Nuke_Beep")
        EmitGlobalSound("Lancelot.Helicoptor")
        -- Set up unit
        LevelAllAbility(f16)
        FindClearSpaceForUnit(f16, f16:GetAbsOrigin(), true)
        f16:SetAbsOrigin(targetPoint)
        Timers:CreateTimer(0.033, function()
            f16:EmitSound("Hero_Gyrocopter.Rocket_Barrage")
        end)
    end)
    
    
    -- Move jet around
    local flyCount = 0
    local t = 0
    Timers:CreateTimer(2.0, function()
        if flyCount == 121 then f16:ForceKill(true) return end
        t = t+0.12
        SpinInCircle(f16, targetPoint, t, 650)
        flyCount = flyCount + 1
        return 0.033
    end)

    local barrageCount = 0
    Timers:CreateTimer(2.0, function()
        if flyCount == 121 then f16:ForceKill(true) return end
        local barrageVec1 = RandomVector(RandomInt(100, 800))
        local targets1 = FindUnitsInRadius(caster:GetTeam(), targetPoint + barrageVec1, nil, 200, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for k,v in pairs(targets1) do
            DoDamage(caster, v, 300, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
            if not v:IsMagicImmune() then v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 0.75}) end
        end
        -- particle
        if caster.AltPart.combo == 0 then
            local barrageImpact1 = ParticleManager:CreateParticle( "particles/custom/lancelot/lancelot_nuke_impact_circle.vpcf", PATTACH_CUSTOMORIGIN, nil )
            ParticleManager:SetParticleControl( barrageImpact1, 0, targetPoint+barrageVec1)
            ParticleManager:SetParticleControl( barrageImpact1, 1, Vector(300, 300, 300))
            Timers:CreateTimer( 2.0, function()
                ParticleManager:DestroyParticle( barrageImpact1, false )
                ParticleManager:ReleaseParticleIndex( barrageImpact1 )
            end)
        else
            local barrageImpact1 = ParticleManager:CreateParticle( "particles/custom/archer/archer_sword_barrage_impact_circle.vpcf", PATTACH_CUSTOMORIGIN, nil )
            ParticleManager:SetParticleControl( barrageImpact1, 0, targetPoint+barrageVec1)
            ParticleManager:SetParticleControl( barrageImpact1, 1, Vector(300, 300, 300))
            Timers:CreateTimer( 2.0, function()
                ParticleManager:DestroyParticle( barrageImpact1, false )
                ParticleManager:ReleaseParticleIndex( barrageImpact1 )
            end)
        end

        local barrageImpact2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_spell_light_strike_array_impact_sparks.vpcf", PATTACH_CUSTOMORIGIN, nil )
        ParticleManager:SetParticleControl( barrageImpact2, 0, targetPoint+barrageVec1)
        visiondummy:EmitSound("Hero_Gyrocopter.Rocket_Barrage.Launch")
        -- Destroy particle after delay
        Timers:CreateTimer( 2.0, function()
            ParticleManager:DestroyParticle( barrageImpact2, false )
            ParticleManager:ReleaseParticleIndex( barrageImpact2 )
        end)
    
        barrageCount = barrageCount + 1
        return 0.033
    end)

    Timers:CreateTimer(4.5, function()
        EmitGlobalSound("Lancelot.TacticalNuke") 
    end)

    Timers:CreateTimer(7.0, function()
        EmitGlobalSound("Lancelot.Nuke_Impact")
        local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, 1500, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
        for k,v in pairs(targets) do
            DoDamage(caster, v, 2000, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
            if not v:IsMagicImmune() then v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 1.0}) end
        end
        -- particle
        local impactFxIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_gyrocopter/gyro_calldown_explosion_second.vpcf", PATTACH_CUSTOMORIGIN, nil )
        ParticleManager:SetParticleControl( impactFxIndex, 0, targetPoint)
        ParticleManager:SetParticleControl( impactFxIndex, 1, Vector(2500, 2500, 1500))
        ParticleManager:SetParticleControl( impactFxIndex, 2, Vector(2500, 2500, 2500))
        ParticleManager:SetParticleControl( impactFxIndex, 3, targetPoint)
        ParticleManager:SetParticleControl( impactFxIndex, 4, Vector(2500, 2500, 2500))
        ParticleManager:SetParticleControl( impactFxIndex, 5, Vector(2500, 2500, 2500))

        local mushroom = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_spell_light_strike_array_explosion.vpcf", PATTACH_CUSTOMORIGIN, nil )
        ParticleManager:SetParticleControl( mushroom, 0, targetPoint)

        -- Destroy particle after delay
        Timers:CreateTimer( 2.0, function()
            ParticleManager:DestroyParticle( impactFxIndex, false )
            ParticleManager:ReleaseParticleIndex( impactFxIndex )
            ParticleManager:DestroyParticle( mushroom, false )
            ParticleManager:ReleaseParticleIndex( mushroom )
        end)
    end)
end

SpinInCircle = function(unit, center, t, multiplier)
    local x = math.cos(t) * multiplier
    local y = math.sin(t) * multiplier
    lastPos = unit:GetAbsOrigin()
    unit:SetAbsOrigin(Vector(center.x + x, center.y + y, 750))
    local diff = (unit:GetAbsOrigin() - lastPos):Normalized() 
    unit:SetForwardVector(diff) 


end


function lancelot_nuke:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function lancelot_nuke:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: lancelot_ability / OnNukeStart
	OnNukeStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Target = "POINT"
	})
end

modifier_nuke_cooldown = class({})

function modifier_nuke_cooldown:IsDebuff() return true end
function modifier_nuke_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
