atalanta_crossing_arcadia = class({})

function atalanta_crossing_arcadia:OnUpgrade()
    local caster = self:GetCaster()
    local ability = self

    if IsServer() then
        if not caster.ShootAoEArrow then
            function caster:ShootAoEArrow(...)
                ability:ShootAoEArrow(...)
            end
        end
    end
end

function atalanta_crossing_arcadia:GetCastRange()
    return self:GetSpecialValueFor("cast_range")
end

function atalanta_crossing_arcadia:GetAOERadius()
    local caster = self:GetCaster()
    local aoe = self:GetSpecialValueFor("aoe")

    --[[if IsServer() and caster:HasModifier("modifier_tauropolos") then
        local tauropolos = caster:FindAbilityByName("atalanta_tauropolos")
        aoe = aoe + tauropolos:GetSpecialValueFor("bonus_aoe_per_agi") * caster:GetAgility()
    end]]
    if caster:HasModifier("modifier_arrows_of_the_big_dipper") then
      local fAgility = CustomNetTables:GetTableValue("sync","atalanta_agility").fAgility
      local tAttributeTable = CustomNetTables:GetTableValue("sync","atalanta_big_dipper")
      aoe = aoe + (tAttributeTable.fAOEPerAGI * fAgility)
    end

    return aoe
end

function atalanta_crossing_arcadia:CastFilterResultLocation(location)
    local caster = self:GetCaster()

    --[[if IsServer() then
        if GridNav:IsBlocked(location) or not GridNav:IsTraversable(location) then
            return UF_FAIL_CUSTOM
        end
    end]]

    if not caster:HasArrow(self:GetSpecialValueFor("arrow_cost")) then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end

function atalanta_crossing_arcadia:GetCustomCastErrorLocation(location)
    --[[if IsServer() then
        if GridNav:IsBlocked(location) or not GridNav:IsTraversable(location) then
            return "#Cannot_Travel"
        end
    end]]

    return "#Not_enough_arrows"
end

function atalanta_crossing_arcadia:OnProjectileHit_ExtraData(target, location, data)
    local caster = self:GetCaster()

    if not target then
        return
    end
    local targets = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, data["1"], DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
    for _,v in pairs(targets) do
        --caster:GrantQBuff(self)
        --[[if data["3"] == 0 then
            caster:ArrowHit(v, data["2"],data["3"])
        else
            if v:GetName() ~= "npc_dota_ward_base" then]]
                caster:ArrowHit(v, data["2"], data["3"], data["4"])
        --    end
        --end
    end
end

function atalanta_crossing_arcadia:ShootAoEArrow(keys)
    local caster = self:GetCaster()
    local ability = self

    local source
    local origin
    local target
    local dummy
    local position

    if keys.Origin then
        local originDummy = CreateUnitByName("dummy_unit", keys.Origin, false, caster, caster, caster:GetTeamNumber())
        originDummy:SetOrigin(keys.Origin)
        originDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

        Timers:CreateTimer(1, function()
            originDummy:RemoveSelf()
        end)

        source = originDummy
        origin = keys.Origin
    else
        source = caster
        origin = caster:GetOrigin()
    end

    if not keys.Target then
        dummy = CreateUnitByName("dummy_unit", keys.Position, false, caster, caster, caster:GetTeamNumber())
        dummy:SetOrigin(keys.Position)
        dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)

        target = dummy
        position = keys.Position
    else
        target = keys.Target
        position = target:GetOrigin()
    end

    local displacement = position - origin
    if displacement == Vector(0, 0, 0) then
        displacement = Vector(1, 1, 0)
    end
    local velocity = displacement / keys.Delay

    local projectile = {
        Target = target,
        Source = source,
        Ability = self,
        EffectName = keys.Effect,
        bDodgable = false,
        bProvidesVision = false,
        iMoveSpeed = velocity:Length(),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
	    ExtraData = {keys.AoE or 0, keys.Slow or 0, keys.IsPhoebus or 0, keys.IsCombo or 0}
    }
    ProjectileManager:CreateTrackingProjectile(projectile)

    Timers:CreateTimer(keys.Delay + 0.1, function()
        if dummy then
            dummy:RemoveSelf()
        end

    end)
end

function atalanta_crossing_arcadia:OnSpellStart()
    local caster = self:GetCaster()
    local ability = self
    local position = self:GetCursorPosition()
    local origin = caster:GetOrigin()

    if (position - caster:GetAbsOrigin()):Length2D() > self:GetSpecialValueFor("range") then
        local diff = position - caster:GetAbsOrigin()
        local length_diff = (position - caster:GetAbsOrigin()):Length2D()

        position = position - diff:Normalized() * (length_diff - self:GetSpecialValueFor("range"))
    end

    local retreatDist = self:GetSpecialValueFor("leapback_range")
    local forwardVec = caster:GetForwardVector()
    --position - caster:GetAbsOrigin()
    --caster:GetForwardVector()
    local archer = Physics:Unit(caster)
    caster:UseArrow(self:GetSpecialValueFor("arrow_cost"))

    local duration = self:GetSpecialValueFor("jump_duration")
    --local stunDuration = self:GetSpecialValueFor("stun_duration")
    local aoe = self:GetAOERadius()
    local effect = "particles/custom/atalanta/normal_arrow.vpcf"
    local facing = caster:GetForwardVector() + Vector(0, 0, -2)
    --position - caster:GetAbsOrigin()
    --caster:GetForwardVector() + Vector(0, 0, -2)
    self.bFirstHit = true
    caster:PreventDI()
    caster:SetPhysicsFriction(0)
    caster:SetPhysicsVelocity(-forwardVec * retreatDist * 2 + Vector(0,0,1200))
    caster:SetPhysicsAcceleration(Vector(0,0,-3000))
    caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
    caster:FollowNavMesh(true)

    ProjectileManager:ProjectileDodge(caster)

    Timers:CreateTimer(duration, function()
        caster:PreventDI(false)
        caster:SetPhysicsVelocity(Vector(0,0,0))
        caster:OnPhysicsFrame(nil)
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
    end)
    StartAnimation(caster, {duration=duration, activity=ACT_DOTA_ATTACK_EVENT, rate=1.0})
    --[[rotateCounter = 1
    Timers:CreateTimer(function()
        if rotateCounter == 13 then return end
        caster:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0,30*rotateCounter,0), forwardVec))
        rotateCounter = rotateCounter + 1
        return 0.03
    end)]]
    giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.5)


    if caster.CrossingArcadiaPlusAcquired then
        local offset = 0.7071 * aoe - 50
        Timers:CreateTimer(0.07, function()
            if not caster:IsAlive() then
                return
            end
            caster:ShootArrow({
                Position = position + Vector(-offset, -offset, 0),
                AoE = aoe,
                Delay = 0.2,
                Effect = effect,
                Facing = facing,
                Stun = 0,
                DontUseArrow = true,
                IsPhoebus = true,
            })
        end)

        Timers:CreateTimer(0.14, function()
            if not caster:IsAlive() then
                return
            end
            caster:ShootArrow({
                Position = position + Vector(offset, -offset, 0),
                AoE = aoe,
                Delay = 0.2,
                Effect = effect,
                Facing = facing,
                Stun = 0,
                DontUseArrow = true,
                IsPhoebus = true,
            })
        end)

        Timers:CreateTimer(0.21, function()
            if not caster:IsAlive() then
                return
            end
            caster:ShootArrow({
                Position = position + Vector(0, aoe - 50, 0),
                AoE = aoe,
                Delay = 0.2,
                Effect = effect,
                Facing = facing,
                Stun = 0,
                DontUseArrow = true,
                IsPhoebus = true,
            })
        end)

        Timers:CreateTimer(0.28, function()
            if not caster:IsAlive() then
                return
            end
            caster:ShootArrow({
                Position = position + Vector(-offset, -offset, 0),
                AoE = aoe,
                Delay = 0.2,
                Effect = effect,
                Facing = facing,
                Stun = 0,
                DontUseArrow = true,
                IsPhoebus = true,
            })
        end)

        Timers:CreateTimer(0.35, function()
            if not caster:IsAlive() then
                return
            end
            caster:ShootArrow({
                Position = position + Vector(offset, -offset, 0),
                AoE = aoe,
                Delay = 0.2,
                Effect = effect,
                Facing = facing,
                Stun = 0,
                DontUseArrow = true,
                IsPhoebus = true,
            })
        end)

        Timers:CreateTimer(duration, function()
            caster:SetForwardVector(forwardVec)
            caster:CastLastSpurt()
        end)
    else
        local offset = 0.7071 * aoe - 50
        Timers:CreateTimer(0.1, function()
            if not caster:IsAlive() then
                return
            end
            caster:ShootArrow({
                Position = position + Vector(-offset, -offset, 0),
                AoE = aoe,
                Delay = 0.2,
                Effect = effect,
                Facing = facing,
                Stun = 0,
                DontUseArrow = true,
                IsPhoebus = true,
            })
        end)

        Timers:CreateTimer(0.2, function()
            if not caster:IsAlive() then
                return
            end
            caster:ShootArrow({
                Position = position + Vector(offset, -offset, 0),
                AoE = aoe,
                Delay = 0.2,
                Effect = effect,
                Facing = facing,
                Stun = 0,
                DontUseArrow = true,
                IsPhoebus = true,
            })
        end)

        Timers:CreateTimer(0.3, function()
            if not caster:IsAlive() then
                return
            end
            caster:ShootArrow({
                Position = position + Vector(0, aoe - 50, 0),
                AoE = aoe,
                Delay = 0.2,
                Effect = effect,
                Facing = facing,
                Stun = 0,
                DontUseArrow = true,
                IsPhoebus = true,
            })
        end)

        Timers:CreateTimer(duration, function()
            caster:SetForwardVector(forwardVec)
        end)
    end

    if caster.GoldenAppleAcquired and caster:FindAbilityByName("atalanta_golden_apple"):IsCooldownReady() then
        caster:SwapAbilities("atalanta_crossing_arcadia", "atalanta_golden_apple", false, true)
        Timers:CreateTimer(self:GetSpecialValueFor("attribute_swap_duration"), function()
            caster:SwapAbilities("atalanta_golden_apple", "atalanta_crossing_arcadia", false, true)
        end)
    end
end

function atalanta_crossing_arcadia:Land(duration)
    local caster = self:GetCaster()
    local ability = self
    local origin = caster:GetOrigin()
    local position = GetGroundPosition(origin, caster)

    local tick = 1
    local tickInterval = 0.033
    local totalTicks = duration / tickInterval
    local jumpVector = (position - origin)
    local tickVector = jumpVector / totalTicks

    Timers:CreateTimer(function()
    tick = tick + 1
    caster:SetOrigin(caster:GetOrigin() + tickVector)
    
        if tick >= totalTicks then
            caster:SetOrigin(GetGroundPosition(caster:GetOrigin(), caster))
            FindClearSpaceForUnit(caster, caster:GetOrigin(), true)
            if caster.CrossingArcadiaPlusAcquired then
                caster:CastLastSpurt()
            end
            return
        end

    return tickInterval
    end)
end

function atalanta_crossing_arcadia:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_1
end

function atalanta_crossing_arcadia:GetAbilityTextureName()
    return "custom/atalanta_crossing_arcadia"
end