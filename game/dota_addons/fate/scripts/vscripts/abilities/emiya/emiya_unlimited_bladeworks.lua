emiya_unlimited_bladeworks = class({})
modifier_ubw_chronosphere = class({})

LinkLuaModifier("modifier_ubw_chant_count", "abilities/emiya/modifiers/modifier_ubw_chant_count", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_unlimited_bladeworks", "abilities/emiya/modifiers/modifier_unlimited_bladeworks", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_unlimited_bladeworks_autoblade", "abilities/emiya/modifiers/modifier_unlimited_bladeworks_autoblade", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arrow_rain_window", "abilities/emiya/modifiers/modifier_arrow_rain_window", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_inside_marble", "abilities/general/modifiers/modifier_inside_marble", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ubw_chronosphere", "abilities/emiya/emiya_unlimited_bladeworks", LUA_MODIFIER_MOTION_NONE)

local chainTargetsTable = nil
local ubwTargets = nil
local ubwTargetLoc = nil
local ubwCasterPos = nil
 
local ubwCenter = Vector(5926, -4837, 222)
if( IsServer()) then 
    if(IsFFA()) then
        ubwCenter = Vector(5578.463867, -4475.173828, 159.689697)
    end
end

local aotkCenter = Vector(288,-4504, 261)

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

    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero == caster then
            if playerHero.zlodemon == true then
                
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_emiya_r_".. self:GetUBWCastCount()})
             else
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="emiya_ubw".. self:GetUBWCastCount()})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
            end
        end
    end) 

    caster:EmitSound("emiya_ubw".. self:GetUBWCastCount())
    
end

function emiya_unlimited_bladeworks:OnProjectileHit_ExtraData(hTarget, vLocation, tExtraData) -- autoattack in ubw
	local target = EntIndexToHScript(tExtraData.targetIndex)
	if target == nil then return end
	local hCaster = self:GetCaster()
	hCaster:PerformAttack(target, true, true, true, false, false, false, false)


	
    local slash_pfx =   ParticleManager:CreateParticle("particles/emiya/emiya_swords_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControlEnt(slash_pfx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(slash_pfx)

 
	
end

function emiya_unlimited_bladeworks:ReduceAbilityCooldowns()
    local caster = self:GetCaster()
    local pepeCd = caster:GetAbilityByIndex(0):GetCooldownTimeRemaining()
    local bpCd = caster:GetAbilityByIndex(1):GetCooldownTimeRemaining()    
    local oeCd = caster:GetAbilityByIndex(2):GetCooldownTimeRemaining()

    caster:GetAbilityByIndex(0):EndCooldown()    
    caster:GetAbilityByIndex(1):EndCooldown()
    caster:GetAbilityByIndex(2):EndCooldown()

    if pepeCd - self:GetSpecialValueFor("cooldown_set") > 0 then
        caster:GetAbilityByIndex(0):StartCooldown(pepeCd - self:GetSpecialValueFor("cooldown_set"))
    end

    if bpCd - self:GetSpecialValueFor("cooldown_set") > 0 then
        caster:GetAbilityByIndex(1):StartCooldown(bpCd - self:GetSpecialValueFor("cooldown_set"))
    end

    if oeCd - self:GetSpecialValueFor("cooldown_set") > 0 then
        caster:GetAbilityByIndex(2):StartCooldown(oeCd - self:GetSpecialValueFor("cooldown_set"))
    end

    --[[caster:GetAbilityByIndex(0):StartCooldown(1)
    caster:GetAbilityByIndex(1):StartCooldown(math.max(bpCd - self:GetSpecialValueFor("cooldown_set"), 1))
    caster:GetAbilityByIndex(2):StartCooldown(math.max(oeCd - self:GetSpecialValueFor("cooldown_set"), 1))]]
end

function emiya_unlimited_bladeworks:OnSpellStart()
    if self:GetUBWCastCount() < 6 then
        if self:GetUBWCastCount() <1 then 
            self:CheckCombo()
        end
        self:GrantUBWChantBuff()
        self:ReduceAbilityCooldowns()
    else
        self:StartUBW(true)
    end
end

function emiya_unlimited_bladeworks:StartUBW(boolsoundOn)
    local caster = self:GetCaster()
    local casterLocation = caster:GetAbsOrigin()
    local castDelay = 1.5 + (boolsoundOn and   0.5 or 0)
    local radius = self:GetSpecialValueFor("radius")

    local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, radius - 550, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    for q,w in pairs(targets) do
        --giveUnitDataDrivenModifier(caster, w, "pause_sealdisabled", castDelay)
        --[[local stopOrder = {
            UnitIndex = w:entindex(), 
            OrderType = DOTA_UNIT_ORDER_STOP
        }

        ExecuteOrderFromTable(stopOrder)]] 
        --w:AddNewModifier(caster, self, "modifier_ubw_chronosphere", { Duration = castDelay })
        giveUnitDataDrivenModifier(caster, w, "rooted", castDelay)
        giveUnitDataDrivenModifier(caster, w, "locked", castDelay)
    end

    giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", castDelay)
    caster:AddNewModifier(caster, self, "modifier_unlimited_bladeworks", { duration = castDelay })
    if boolsoundOn then 
        --giveUnitDataDrivenModifier(caster, caster, "jump_pause", castDelay)
        LoopOverPlayers(function(player, playerID, playerHero)
            --print("looping through " .. playerHero:GetName())
            if playerHero == caster then
                if playerHero.zlodemon == true then
                
                CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_emiya_r_7"})
                end
            end
        end) 

   
        EmitGlobalSound("emiya_ubw7")
    end
    StartAnimation(caster, {duration=castDelay, activity=ACT_DOTA_ARCTIC_BURN_END, rate=0.5})
    
    Timers:CreateTimer({
        endTime = castDelay,
        callback = function()
        if caster:IsAlive() then
            local newLocation = caster:GetAbsOrigin()
            caster.UBWLocator = CreateUnitByName("ping_sign2", caster:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber())
            caster.UBWLocator:FindAbilityByName("ping_sign_passive"):SetLevel(1)
            caster.UBWLocator:AddNewModifier(caster, caster, "modifier_kill", {duration = 15})
            caster.UBWLocator:SetAbsOrigin(caster:GetAbsOrigin())
            caster:RemoveModifierByName("modifier_unlimited_bladeworks")
            self:EnterUBW()

            caster:AddNewModifier(caster, self, "modifier_unlimited_bladeworks", { Duration = 15 })

            local entranceFlashParticle = ParticleManager:CreateParticle("particles/custom/archer/ubw/entrance_flash.vpcf", PATTACH_ABSORIGIN, caster)
            ParticleManager:SetParticleControl(entranceFlashParticle, 0, newLocation)
            ParticleManager:CreateParticle("particles/custom/archer/ubw/exit_flash.vpcf", PATTACH_ABSORIGIN, caster)
        end
    end
    })    

    for i=2, 3 do
        --небольшой комментарий: еблан, который писал этот ебаный ульт аталанты - пожалуйста, выйди в окно нахуй. Тот факт, что он не удалял дамми-юниты - это просто пиздец
        local dummy = CreateUnitByName("dummy_unit", casterLocation, false, nil, nil, i)
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
        Timers:CreateTimer(16, function()
            dummy:RemoveSelf()

        end)
    end
end

function emiya_unlimited_bladeworks:EnterUBW()
    CreateUITimer("Unlimited Blade Works", 15, "ubw_timer")
 
    local caster = self:GetCaster()
    local ability = self
    local radius = self:GetSpecialValueFor("radius")
    local swapAbil = caster:FindAbilityByName("emiya_weapon_swap")
    swapAbil:SwapWeapons(3)
    caster:SetBodygroup(0,1)

    local ubwdummyLoc1 = ubwCenter
 

    caster:RemoveModifierByName("modifier_ubw_chant_count")
    caster:RemoveModifierByName("modifier_hrunting_window")
    caster:RemoveModifierByName("modifier_aestus_domus_aurea_ally")
    caster:RemoveModifierByName("modifier_aestus_domus_aurea_enemy")



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
        ubwdummyLoc1 = aotkCenter 
 
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
    local ubwdummy1 = CreateUnitByName("dummy_unit", ubwdummyLoc1, false, nil, nil, caster:GetTeamNumber())
 
 
    
    ubwdummy1:SetAbsOrigin(ubwdummyLoc1)
 
    
 
    ubwdummy1:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
    ubwdummy1:SetDayTimeVisionRange(1500)
    ubwdummy1:SetNightTimeVisionRange(1500)
    ubwdummy1:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 1500})
    Timers:CreateTimer( 15, function()
		ubwdummy1:RemoveSelf()
	end)

    -- Automated weapon shots
    if caster:HasModifier("modifier_projection_attribute") then
        caster:AddNewModifier(caster, self, "modifier_unlimited_bladeworks_autoblade", { Duration = 15})
    end

    if not caster.IsUBWDominant then return end 

    ubwTargetLoc = {}
    local diff = nil
    local ubwTargetPos = nil
    ubwCasterPos = caster:GetAbsOrigin()
    
    --breakpoint
    -- record location of units and move them into UBW 
    for i=1, #ubwTargets do
        if IsValidEntity(ubwTargets[i]) then
            if ubwTargets[i]:GetName() ~= "npc_dota_ward_base" then
                ubwTargets[i]:RemoveModifierByName("modifier_aestus_domus_aurea_enemy")
                ubwTargets[i]:RemoveModifierByName("modifier_aestus_domus_aurea_ally")
                ubwTargets[i]:RemoveModifierByName("modifier_aestus_domus_aurea_nero")

                --if ubwTargets[i]:GetName() == "npc_dota_hero_bounty_hunter" or ubwTargets[i]:GetName() == "npc_dota_hero_riki" then
                    ubwTargets[i]:AddNewModifier(caster, self, "modifier_inside_marble", { Duration = 15 })
                --end

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
    local caster = self:GetCaster()
    local swapAbil = caster:FindAbilityByName("emiya_weapon_swap")
    swapAbil:SwapWeapons(1)
    caster:SetBodygroup(0,0)
    CreateUITimer("Unlimited Blade Works", 0, "ubw_timer")
    caster:RemoveModifierByName("modifier_unlimited_bladeworks_autoblade")
    --caster.IsUBWActive = false
    if not caster.UBWLocator:IsNull() and IsValidEntity(caster.UBWLocator) then
        caster.UBWLocator:RemoveSelf()
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

            --if units[i]:GetName() == "npc_dota_hero_bounty_hunter" or units[i]:GetName() == "npc_dota_hero_riki" then
                units[i]:RemoveModifierByName("modifier_inside_marble")
            --end

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
    local timers = 0
    Timers:CreateTimer("ubw_end_fix", {
            endTime = 0.5,
            callback = function()
                timers = timers+1
                local units = FindUnitsInRadius(caster:GetTeam(), ubwCenter, nil, 1300, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
                for i=1, #units do
                    --print("removing units in UBW")
                    if IsValidEntity(units[i]) and not units[i]:IsNull() then
                        units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_enemy")
                        units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_ally")
                        units[i]:RemoveModifierByName("modifier_aestus_domus_aurea_nero")
            
                        --if units[i]:GetName() == "npc_dota_hero_bounty_hunter" or units[i]:GetName() == "npc_dota_hero_riki" then
                            units[i]:RemoveModifierByName("modifier_inside_marble")
                        --end
            
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
                if timers < 4 then
                    return 0.5
                end
            end
        })
    ubwTargets = nil
    ubwTargetLoc = nil

    Timers:RemoveTimer("ubw_timer")
end

 

function emiya_unlimited_bladeworks:OnOwnerDied()
    if self:GetCaster().IsUBWActive then 
        self:EndUBW()
    end 

end

function emiya_unlimited_bladeworks:CheckCombo()
    local caster = self:GetCaster()

    if caster:GetStrength() > 29.1 and caster:GetAgility() > 29.1 and caster:GetIntellect() > 29.1 
        and caster:FindAbilityByName("emiya_combo"):IsCooldownReady() then 
        
        caster:SwapAbilities("emiya_unlimited_bladeworks", "emiya_combo", false, true) 
        caster:AddNewModifier(caster, self, "modifier_arrow_rain_window", { Duration = 1.2})
    end
end

function emiya_unlimited_bladeworks:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self
    
    caster:FindAbilityByName("emiya_barrage_moonwalk"):SetLevel(self:GetLevel())    
    caster:FindAbilityByName("emiya_big_swords"):SetLevel(self:GetLevel())
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

function modifier_ubw_chronosphere:CheckState()
    return { --[MODIFIER_STATE_STUNNED] = true,
             --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
             --[MODIFIER_STATE_FROZEN] = true,
             --[MODIFIER_STATE_PROVIDES_VISION] = true,
             [MODIFIER_STATE_SILENCED] = true }
end

function modifier_ubw_chronosphere:IsHidden()
    return true
end