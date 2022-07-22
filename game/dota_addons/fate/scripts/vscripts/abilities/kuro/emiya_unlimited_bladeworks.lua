emiya_unlimited_bladeworks = class({})
LinkLuaModifier("modifier_ubw_chant_count", "abilities/emiya/modifiers/modifier_ubw_chant_count", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_unlimited_bladeworks", "abilities/emiya/modifiers/modifier_unlimited_bladeworks", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_unlimited_bladeworks_autoblade", "abilities/emiya/modifiers/modifier_unlimited_bladeworks_autoblade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arrow_rain_window", "abilities/emiya/modifiers/modifier_arrow_rain_window", LUA_MODIFIER_MOTION_NONE)

local chainTargetsTable = nil
local ubwTargets = nil
local ubwTargetLoc = nil
local ubwCasterPos = nil
local ubwdummies = nil
local ubwCenter = Vector(5600, -4398, 200)
local aotkCenter = Vector(500, -4800, 208)

function emiya_unlimited_bladeworks:GetBuffDuration()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")

    return duration
end

function emiya_unlimited_bladeworks:GetUBWCastCount()
    local caster = self:GetCaster()
    local modifier = caster:FindModifierByName("modifier_ubw_chant_count")
    local currentStack = modifier and modifier:GetStackCount() or 0

    return currentStack
end

function emiya_unlimited_bladeworks:GrantUBWChantBuff()
    local caster = self:GetCaster()
    local ability = self
    --local currentStack =  --caster:FindModifierByName("modifier_ubw_chant_count"):GetStackCount() or 0
    caster:AddNewModifier(caster, self, "modifier_ubw_chant_count", {duration = self:GetBuffDuration(),
                                                                     MsBonus = self:GetSpecialValueFor("movespeed_bonus")})
    --caster:SetModifierStackCount("modifier_ubw_chant_count", self, currentStack + 1)

    EmitGlobalSound("emiya_ubw" .. self:GetUBWCastCount())
end

function emiya_unlimited_bladeworks:ReduceAbilityCooldowns()
    local caster = self:GetCaster()
    local bpCd = caster:GetAbilityByIndex(1):GetCooldownTimeRemaining()    
    local oeCd = caster:GetAbilityByIndex(2):GetCooldownTimeRemaining()

    caster:GetAbilityByIndex(0):EndCooldown()    
    caster:GetAbilityByIndex(1):EndCooldown()
    caster:GetAbilityByIndex(2):EndCooldown()

    caster:GetAbilityByIndex(0):StartCooldown(1)
    caster:GetAbilityByIndex(1):StartCooldown(math.max(bpCd - self:GetSpecialValueFor("cooldown_set"), 1))
    caster:GetAbilityByIndex(2):StartCooldown(math.max(oeCd - self:GetSpecialValueFor("cooldown_set"), 1))
end

function emiya_unlimited_bladeworks:OnSpellStart()
    if self:GetUBWCastCount() < 6 then
        self:GrantUBWChantBuff()
        self:ReduceAbilityCooldowns()
    else
        self:StartUBW()
    end
end

function emiya_unlimited_bladeworks:StartUBW()
    local caster = self:GetCaster()
    local casterLocation = caster:GetAbsOrigin()
    local castDelay = 2
    local radius = self:GetSpecialValueFor("radius")
    
    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius - 550, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    for q,w in pairs(targets) do
        giveUnitDataDrivenModifier(caster, w, "pause_sealdisabled", castDelay)
    end

    EmitGlobalSound("emiya_ubw7")    
    giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", castDelay)
    StartAnimation(caster, {duration=2, activity=ACT_DOTA_CAST_ABILITY_4, rate=2})
    
    Timers:CreateTimer({
        endTime = castDelay,
        callback = function()
        if caster:IsAlive() then
            local newLocation = caster:GetAbsOrigin()
            caster.UBWLocator = CreateUnitByName("ping_sign2", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
            caster.UBWLocator:FindAbilityByName("ping_sign_passive"):SetLevel(1)
            caster.UBWLocator:AddNewModifier(caster, caster, "modifier_kill", {duration = 12.5})
            caster.UBWLocator:SetAbsOrigin(caster:GetAbsOrigin())
            self:EnterUBW()

            caster:AddNewModifier(caster, self, "modifier_unlimited_bladeworks", { Duration = 12 })

            local entranceFlashParticle = ParticleManager:CreateParticle("particles/custom/archer/ubw/entrance_flash.vpcf", PATTACH_ABSORIGIN, caster)
            ParticleManager:SetParticleControl(entranceFlashParticle, 0, newLocation)
            ParticleManager:CreateParticle("particles/custom/archer/ubw/exit_flash.vpcf", PATTACH_ABSORIGIN, caster)
        end
    end
    })    

    for i=2, 3 do
        local dummy = CreateUnitByName("dummy_unit", casterLocation, false, caster, caster, i)
        dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
        dummy:SetAbsOrigin(ubwCenter)
        AddFOWViewer(i, ubwCenter, 1800, 3, false)

        local particle = ParticleManager:CreateParticleForTeam("particles/custom/archer/ubw/firering.vpcf", PATTACH_ABSORIGIN, dummy, i)
        ParticleManager:SetParticleControl(particle, 6, casterLocation)
        local particleRadius = 0
        Timers:CreateTimer(0, function()
            if particleRadius < radius then
                particleRadius = particleRadius + radius * 0.03 / 2
                ParticleManager:SetParticleControl(particle, 1, Vector(particleRadius,0,0))
                return 0.03
            end
        end)
    end
end

function emiya_unlimited_bladeworks:EnterUBW()
    CreateUITimer("Unlimited Blade Works", 12, "ubw_timer")
    
    local caster = self:GetCaster()
    local ability = self
    local radius = self:GetSpecialValueFor("radius")

    local ubwdummyLoc1 = ubwCenter + Vector(600,-600, 1000)
    local ubwdummyLoc2 = ubwCenter + Vector(600,600, 1000)
    local ubwdummyLoc3 = ubwCenter + Vector(-600,600, 1000)
    local ubwdummyLoc4 = ubwCenter + Vector(-600,-600, 1000)

    caster:RemoveModifierByName("modifier_ubw_chant_count")
    caster:RemoveModifierByName("modifier_hrunting_window")
    caster:RemoveModifierByName("modifier_aestus_domus_aurea_ally")
    caster:RemoveModifierByName("modifier_aestus_domus_aurea_enemy")

    -- swap Archer's skillset with UBW ones
    self:SwitchAbilities(true)

    -- Find eligible UBW targets
    ubwTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    caster.IsUBWDominant = true
    
    -- Remove any dummy or hero in jump
    i = 1
    while i <= #ubwTargets do
        if IsValidEntity(ubwTargets[i]) and not ubwTargets[i]:IsNull() then
            ProjectileManager:ProjectileDodge(ubwTargets[i]) -- Disjoint particles
            if ubwTargets[i]:HasModifier("jump_pause") 
                or string.match(ubwTargets[i]:GetUnitName(),"dummy") 
                or ubwTargets[i]:HasModifier("spawn_invulnerable") 
                and ubwTargets[i] ~= caster then 
                table.remove(ubwTargets, i)
                i = i - 1
            end
        end
        i = i + 1
    end

    if caster:GetAbsOrigin().x < 3000 and caster:GetAbsOrigin().y < -2000 then
        ubwdummyLoc1 = aotkCenter + Vector(600,-600, 1000)
        ubwdummyLoc2 = aotkCenter + Vector(600,600, 1000)
        ubwdummyLoc3 = aotkCenter + Vector(-600,600, 1000)
        ubwdummyLoc4 = aotkCenter + Vector(-600,-600, 1000)
        caster.IsUBWDominant = false
    end
    caster.IsUBWActive = true

    --[[local dunCounter = 0
    Timers:CreateTimer(function() 
        if dunCounter == 5 then return end 
        if caster:IsAlive() then EmitGlobalSound("Archer.UBWAmbient") else return end 
        dunCounter = dunCounter + 1
        return 3.0 
    end)]]

    -- Add sword shooting dummies
    local ubwdummy1 = CreateUnitByName("dummy_unit", ubwdummyLoc1, false, caster, caster, caster:GetTeamNumber())
    local ubwdummy2 = CreateUnitByName("dummy_unit", ubwdummyLoc2, false, caster, caster, caster:GetTeamNumber())
    local ubwdummy3 = CreateUnitByName("dummy_unit", ubwdummyLoc3, false, caster, caster, caster:GetTeamNumber())
    local ubwdummy4 = CreateUnitByName("dummy_unit", ubwdummyLoc4, false, caster, caster, caster:GetTeamNumber())
    ubwdummies = {ubwdummy1, ubwdummy2, ubwdummy3, ubwdummy4}
    
    ubwdummy1:SetAbsOrigin(ubwdummyLoc1)
    ubwdummy2:SetAbsOrigin(ubwdummyLoc2)
    ubwdummy3:SetAbsOrigin(ubwdummyLoc3)
    ubwdummy4:SetAbsOrigin(ubwdummyLoc4)    
    
    for i=1, #ubwdummies do
        ubwdummies[i]:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
        ubwdummies[i]:SetDayTimeVisionRange(1000)
        ubwdummies[i]:SetNightTimeVisionRange(1000)
        ubwdummies[i]:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 1000})
    end

    -- Automated weapon shots
    if caster:HasModifier("modifier_projection_attribute") then
        caster:AddNewModifier(caster, self, "modifier_unlimited_bladeworks_autoblade", { Duration = 12})
    end

    if not caster.IsUBWDominant then return end 

    ubwTargetLoc = {}
    local diff = nil
    local ubwTargetPos = nil
    ubwCasterPos = caster:GetAbsOrigin()
    
    --breakpoint
    -- record location of units and move them into UBW(center location : 6000, -4000, 200)
    for i=1, #ubwTargets do
        if IsValidEntity(ubwTargets[i]) then
            if ubwTargets[i]:GetName() ~= "npc_dota_ward_base" then
                ubwTargets[i]:RemoveModifierByName("modifier_aestus_domus_aurea_enemy")
                ubwTargets[i]:RemoveModifierByName("modifier_aestus_domus_aurea_ally")
                ubwTargets[i]:RemoveModifierByName("modifier_aestus_domus_aurea_nero")

                if ubwTargets[i]:GetName() == "npc_dota_hero_bounty_hunter" then
                    ubwTargets[i].IsInMarble = true
                end

                ubwTargetPos = ubwTargets[i]:GetAbsOrigin()
                ubwTargetLoc[i] = ubwTargetPos
                diff = (ubwCasterPos - ubwTargetPos) -- rescale difference to UBW size(1200)
                ubwTargets[i]:SetAbsOrigin(ubwCenter - diff)
                ubwTargets[i]:Stop()
                FindClearSpaceForUnit(ubwTargets[i], ubwTargets[i]:GetAbsOrigin(), true)
                Timers:CreateTimer(0.1, function() 
                    if caster:IsAlive() and IsValidEntity(ubwTargets[i]) then
                        ubwTargets[i]:AddNewModifier(ubwTargets[i], ubwTargets[i], "modifier_camera_follow", {duration = 1.0})
                    end
                end)
            end
        end
    end    
end

function emiya_unlimited_bladeworks:EndUBW()   
    self:SwitchAbilities(false)
    local caster = self:GetCaster()

    CreateUITimer("Unlimited Blade Works", 0, "ubw_timer")
    --caster.IsUBWActive = false
    if not caster.UBWLocator:IsNull() and IsValidEntity(caster.UBWLocator) then
        caster.UBWLocator:RemoveSelf()
    end

    for i=1, #ubwdummies do
        if not ubwdummies[i]:IsNull() and IsValidEntity(ubwdummies[i]) then 
            ubwdummies[i]:ForceKill(true) 
        end
    end

    local units = FindUnitsInRadius(caster:GetTeam(), ubwCenter, nil, 1300, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

    i = 1
    while i <= #units do
        if IsValidEntity(units[i]) and not units[i]:IsNull() then
            if string.match(units[i]:GetUnitName(),"dummy") then 
                table.remove(units, i)
                i = i - 1
            end
        end
        i = i + 1
    end

    for i=1, #units do
        --print("removing units in UBW")
        if IsValidEntity(units[i]) and not units[i]:IsNull() then
            units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_enemy")
            units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_ally")
            units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_nero")

            if units[i]:GetName() == "npc_dota_hero_bounty_hunter" then
                units[i].IsInMarble = false
            end

            ProjectileManager:ProjectileDodge(units[i])
            if units[i]:GetName() == "npc_dota_hero_chen" and units[i]:HasModifier("modifier_army_of_the_king_death_checker") then
                units[i]:RemoveModifierByName("modifier_army_of_the_king_death_checker")
            end
            local IsUnitGeneratedInUBW = true
            if ubwTargets ~= nil then
                for j=1, #ubwTargets do
                    if not ubwTargets[j]:IsNull() and IsValidEntity(ubwTargets[j]) then 
                        if units[i] == ubwTargets[j] then
                            if ubwTargetLoc[j] ~= nil then
                                units[i]:SetAbsOrigin(ubwTargetLoc[j]) 
                                units[i]:Stop()
                            end
                            FindClearSpaceForUnit(units[i], units[i]:GetAbsOrigin(), true)
                            Timers:CreateTimer(0.1, function() 
                                units[i]:AddNewModifier(units[i], units[i], "modifier_camera_follow", {duration = 1.0})
                            end)
                            IsUnitGeneratedInUBW = false
                            break 
                        end
                    end
                end 
            end
            if IsUnitGeneratedInUBW then
                diff = ubwCenter - units[i]:GetAbsOrigin()
                if ubwCasterPos ~= nil then
                    units[i]:SetAbsOrigin(ubwCasterPos - diff)
                    units[i]:Stop()
                end
                FindClearSpaceForUnit(units[i], units[i]:GetAbsOrigin(), true) 
                Timers:CreateTimer(0.1, function() 
                    if not units[i]:IsNull() and IsValidEntity(units[i]) then
                        units[i]:AddNewModifier(units[i], units[i], "modifier_camera_follow", {duration = 1.0})
                    end
                end)
            end 
        end
    end

    ubwTargets = nil
    ubwTargetLoc = nil

    Timers:RemoveTimer("ubw_timer")
end

function emiya_unlimited_bladeworks:SwitchAbilities(isUbw)
    local caster = self:GetCaster()
    local tStandardAbilities = {
        "emiya_kanshou_byakuya",
        "emiya_broken_phantasm",
        "emiya_crane_wings",
        "emiya_rho_aias",
        "emiya_clairvoyance",
        "emiya_unlimited_bladeworks",
        "attribute_bonus_custom"
    }

    local tUBWAbilities = {
        "emiya_barrage_moonwalk",
        "emiya_barrage_confine",
        "emiya_gae_bolg",
        "emiya_rho_aias",
        "emiya_barrage_rain",
        "emiya_nine_lives",
        "attribute_bonus_custom"
    }

    if isUbw then
        UpdateAbilityLayout(caster, tUBWAbilities)
        self:CheckCombo()
    else
        UpdateAbilityLayout(caster, tStandardAbilities)
    end
end

function emiya_unlimited_bladeworks:OnOwnerDied()
    if self:GetCaster().IsUBWActive then 
        self:EndUBW()
    end 
    self:SwitchAbilities(false)
end

function emiya_unlimited_bladeworks:CheckCombo()
    local caster = self:GetCaster()

    if caster:GetStrength() > 19.1 and caster:GetAgility() > 19.1 and caster:GetIntellect() > 19.1 
        and caster:FindAbilityByName("emiya_arrow_rain"):IsCooldownReady() then 
        
        caster:SwapAbilities("emiya_gae_bolg", "emiya_arrow_rain", false, true) 
        caster:AddNewModifier(caster, self, "modifier_arrow_rain_window", { Duration = 4})
    end
end

function emiya_unlimited_bladeworks:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self
    
    caster:FindAbilityByName("emiya_barrage_moonwalk"):SetLevel(self:GetLevel())    
    caster:FindAbilityByName("emiya_barrage_confine"):SetLevel(self:GetLevel())
    caster:FindAbilityByName("emiya_gae_bolg"):SetLevel(self:GetLevel())
    caster:FindAbilityByName("emiya_barrage_rain"):SetLevel(self:GetLevel())
    caster:FindAbilityByName("emiya_nine_lives"):SetLevel(self:GetLevel())
end


function emiya_unlimited_bladeworks:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_4
end

function emiya_unlimited_bladeworks:GetAbilityTextureName()
    return "custom/archer_5th_ubw"
end