LinkLuaModifier("modifier_okita_zekken", "abilities/okita/okita_zekken", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_zekken_anim", "abilities/okita/okita_zekken", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_zekken_flight", "abilities/okita/okita_zekken", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_zekken_cd", "abilities/okita/modifiers/modifier_okita_zekken_cd", LUA_MODIFIER_MOTION_NONE)

okita_zekken = class({})

function okita_zekken:OnAbilityPhaseStart()
    EmitGlobalSound("Okita.Precombo")
    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.voice == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="vergil_prepare"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
    return true
end

function okita_zekken:OnAbilityPhaseInterrupted()
    StopGlobalSound("Okita.Precombo")
end

function okita_zekken:GetAOERadius()
    return self:GetSpecialValueFor("range")
end

function okita_zekken:OnSpellStart()
	local caster = self:GetCaster()
    local ability = self

    local ability_cooldown = caster:FindAbilityByName("okita_sandanzuki")
    ability_cooldown:StartCooldown(ability_cooldown:GetCooldown(1))

    local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))

    caster:AddNewModifier(caster, self, "modifier_okita_zekken_flight", {})
end

function okita_zekken:StartZekken(target)
    local caster = self:GetCaster()

    local origin = target:GetAbsOrigin()
    local ability = self
    local interval = ability:GetSpecialValueFor("interval")
    local duration = ability:GetSpecialValueFor("duration")
    local radius = ability:GetSpecialValueFor("radius")

    local count = 0

    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.voice == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="vergil_to_die"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)

    caster:AddNewModifier(caster, self, "modifier_okita_zekken", {duration = 3.9, targetind = target:entindex()})
    caster:AddNewModifier(caster, self, "modifier_okita_zekken_cd", {duration = ability:GetCooldown(1)})

    local circleIndex = ParticleManager:CreateParticle( "particles/okita/okita_zekken_ring.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl( circleIndex, 0, origin)
    ParticleManager:SetParticleControl( circleIndex, 1, Vector(radius, 0, 0))

    --EmitGlobalSound("Okita.Precombo")
    --local p = CreateParticle("particles/heroes/juggernaut/phantom_sword_dance.vpcf",PATTACH_ABSORIGIN,caster,2)
    --ParticleManager:SetParticleControl( p, 0, caster:GetAbsOrigin())
    --ParticleManager:SetParticleControl( p, 2, point)
    Timers:CreateTimer(function()
        if count < duration and caster and caster:IsAlive() then
            --[[if count <= 1 then
                origin = target:GetAbsOrigin()
            end]]
            local damage = ability:GetSpecialValueFor("damage") + (caster.IsKikuIchimonjiAcquired and caster:GetAgility()*self:GetSpecialValueFor("kiku_agi_ratio") or 0)
            local angle = RandomInt(0, 360)
            local startLoc = GetRotationPoint(origin,RandomInt(300, 600),angle)
            local endLoc = GetRotationPoint(origin,RandomInt(300, 600),angle + RandomInt(120, 240))
            local fxIndex = ParticleManager:CreateParticle( "particles/okita/okita_zekken_slash_tgt_serrakura.vpcf", PATTACH_ABSORIGIN, caster)
            ParticleManager:SetParticleControl( fxIndex, 0, startLoc)
            ParticleManager:SetParticleControl( fxIndex, 1, endLoc + Vector(0,0,50))
            --local p = CreateParticle("particles/heroes/juggernaut/phantom_sword_dance_a.vpcf",PATTACH_ABSORIGIN,caster,2)
            --ParticleManager:SetParticleControl( p, 0, startLoc)
            --ParticleManager:SetParticleControl( p, 2, endLoc + Vector(0,0,50))
            local unitGroup = FindUnitsInRadius(caster:GetTeam(), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
            for i = 1, #unitGroup do
                if caster.IsTennenAcquired then
                    caster:PerformAttack( unitGroup[i], true, true, true, true, false, true, true )
                end
                DoDamage(caster, unitGroup[i], damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                --caster:PerformAttack( unitGroup[i], true, true, true, true, false, false, true )
            end
            FindClearSpaceForUnit(caster,endLoc,true)
            for k,v in pairs(unitGroup) do
                --CauseDamage(caster,unitGroup,damage,damageType,ability3)
                --caster:PerformAttack(v,true,true,true,false,false,false,true)
            end
            --if #unitGroup == 0 then
                caster:EmitSound("Tsubame_Focus")
            --end
            count = count + interval
            return interval
        elseif caster and caster:IsAlive() then
            caster:RemoveModifierByName("modifier_okita_zekken")
            FindClearSpaceForUnit(caster,origin,true)

            ParticleManager:DestroyParticle(circleIndex, false)
            ParticleManager:ReleaseParticleIndex(circleIndex)
        end
    end)
end

modifier_okita_zekken_flight = class({})
function modifier_okita_zekken_flight:IsHidden() return true end
function modifier_okita_zekken_flight:IsDebuff() return false end
function modifier_okita_zekken_flight:IsPurgable() return false end
function modifier_okita_zekken_flight:IsPurgeException() return false end
function modifier_okita_zekken_flight:RemoveOnDeath() return true end
function modifier_okita_zekken_flight:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_okita_zekken_flight:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_okita_zekken_flight:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
function modifier_okita_zekken_flight:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION, 
                    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,}
    return func
end
function modifier_okita_zekken_flight:GetOverrideAnimation()
    return ACT_DOTA_ATTACK_EVENT
end
function modifier_okita_zekken_flight:GetOverrideAnimationRate()
    return 1.0
end
function modifier_okita_zekken_flight:OnCreated(table)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    if IsServer() then
        self.speed          = self.ability:GetSpecialValueFor("speed")
        self.distance       = self.ability:GetAOERadius()--self.ability:GetSpecialValueFor("distance")

        self.point          = self.ability:GetCursorPosition() + RandomVector(1)
        self.direction      = (self.point - self.parent:GetAbsOrigin()):Normalized()
        self.direction.z    = 0
        self.point          = self.parent:GetAbsOrigin() + self.direction * self.distance

        self.parent:Stop()
        self.parent:FaceTowards(self.point)
        self.parent:SetForwardVector(self.direction)

        self.FirstTarget        = nil
        
        self.DamageToTargetsPercentTable = {}

        local dash_fx = ParticleManager:CreateParticle("particles/okita/okita_vendetta_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(dash_fx, 0, self.parent:GetAbsOrigin())

        self:AddParticle(dash_fx, false, false, -1, true, false)

        self.dash_fx2 = ParticleManager:CreateParticle("particles/okita/okita_surge_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(self.dash_fx2, 0, self.parent:GetAbsOrigin())

        self:AddParticle(self.dash_fx2, false, false, -1, true, false)

        self:StartIntervalThink(FrameTime())
        
        --[[if self:ApplyHorizontalMotionController() == false then 
            self:Destroy()
        end]]
    end
end
function modifier_okita_zekken_flight:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_okita_zekken_flight:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_okita_zekken_flight:UpdateHorizontalMotion(me, dt)
    if IsServer() then
         

        if self.distance >= 0 then
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()
            local direction = self.parent:GetForwardVector()

            local next_pos = parent_pos + direction * units_per_dt
            next_pos = GetGroundPosition(next_pos, self.parent)
            local distance_will = self.distance - units_per_dt

            if distance_will < 0 then
                --next_pos = self.point
            end

            self.parent:FaceTowards(self.point)
            self.parent:SetForwardVector(self.direction)

            self.parent:SetOrigin(next_pos)

            self:PlayEffects(parent_pos, next_pos)

            self.distance = self.distance - units_per_dt
        else
            self.parent:RemoveModifierByName("modifier_okita_sandanzuki_charge")
            self:Destroy()
        end
    end
end
function modifier_okita_zekken_flight:PlayEffects(pos1, pos2)
    local dir = (pos2 - pos1):Normalized()
    local enemies = FATE_FindUnitsInLine(
                                        self.parent:GetTeamNumber(),
                                        pos1 - dir*175,
                                        pos2,
                                        self.parent:Script_GetAttackRange(),
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_CLOSEST
                                    )

    for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) and enemy ~= self.parent and not self.FirstTarget then
            if not (enemy:GetName() == "npc_dota_ward_base") then
                self.FirstTarget = true

                self.ability:StartZekken(enemy)
            end
        end
    end
end
function modifier_okita_zekken_flight:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_okita_zekken_flight:OnDestroy()
    if IsServer() then
        if not self.FirstTarget then
            StopGlobalSound("Okita.Precombo")
        end
        self.parent:InterruptMotionControllers(true)
    end
end

modifier_okita_zekken = class({})
function modifier_okita_zekken:IsHidden() return true end
function modifier_okita_zekken:IsDebuff() return false end
function modifier_okita_zekken:IsPurgable() return false end
function modifier_okita_zekken:IsPurgeException() return false end
function modifier_okita_zekken:RemoveOnDeath() return true end
function modifier_okita_zekken:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_okita_zekken:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_okita_zekken:CheckState()
    local state =   { 
                        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        [MODIFIER_STATE_DISARMED] = true,
                        [MODIFIER_STATE_SILENCED] = true,
                        [MODIFIER_STATE_MUTED] = true,
                        [MODIFIER_STATE_UNTARGETABLE] = true,
                        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
                        [MODIFIER_STATE_INVULNERABLE] = true,
                    }
    return state
end
function modifier_okita_zekken:OnCreated(args)
	if IsServer() then
		self.target = EntIndexToHScript(args.targetind)
		self:StartIntervalThink(FrameTime())
	end
end
function modifier_okita_zekken:OnIntervalThink()
	self:GetParent():FaceTowards(self.target:GetAbsOrigin())
end

modifier_okita_zekken_anim = class({})

function modifier_okita_zekken_anim:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    				MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE }
    return func
end
function modifier_okita_zekken_anim:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_2
end
function modifier_okita_zekken_anim:GetOverrideAnimationRate()
    return 0.5
end