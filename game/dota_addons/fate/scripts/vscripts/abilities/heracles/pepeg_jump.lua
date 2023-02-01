LinkLuaModifier("modifier_pepeg_jump", "abilities/heracles/pepeg_jump", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_pepe_slow", "abilities/heracles/pepeg_jump", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pepe_mute", "abilities/heracles/pepeg_jump", LUA_MODIFIER_MOTION_NONE)

pepeg_jump = class({})

function pepeg_jump:GetBehavior()
    if self:GetCaster():HasModifier("modifier_heracles_berserk") then
        return (DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES)
    end
    return (DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE)
end

function pepeg_jump:OnSpellStart()
	local caster = self:GetCaster()

    if caster:HasModifier("modifier_heracles_berserk") then
	   caster:AddNewModifier(caster, self, "modifier_pepeg_jump", {Berserked = true})
       LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.zlodemon == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_herc_berserk_e"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
    else
        local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
        print (targets[2])
        if targets[2] then
            targets[2]:AddNewModifier(caster, self, "modifier_pepeg_jump", {Berserked = false})
            LoopOverPlayers(function(player, playerID, playerHero)
                --print("looping through " .. playerHero:GetName())
                if playerHero.zlodemon == true then
                    -- apply legion horn vsnd on their client
                    CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_herc_e"})
                    --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
                end
            end)
        else
            self:EndCooldown() 
            caster:GiveMana(400)
        end
    end
end

function pepeg_jump:GetAbilityTextureName()
    if self:GetCaster():HasModifier("modifier_heracles_berserk") then
        return "custom/heracles/pepeg_jump_true"
    else
        return "custom/heracles/pepeg_jump"
    end
end

function pepeg_jump:GetCastRange(vLocation, hTarget)
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_heracles_berserk") then
        return self:GetSpecialValueFor("berserked_range") + caster:GetStrength()*2
    end
    return self:GetSpecialValueFor("range") + caster:GetStrength()*2
end

function pepeg_jump:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function pepeg_jump:CastFilterResultTarget(hTarget)
    local caster = self:GetCaster()
    if IsServer() then
        local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
        if targets[2] == nil then
            return UF_FAIL_CUSTOM
        else
            return UF_SUCESS
        end
    end
end

function pepeg_jump:GetCustomCastErrorTarget()
    return "Can only be activated in Derange"
end

function pepeg_jump:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() then
        local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
        if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then 
            return UF_FAIL_OUT_OF_WORLD
        elseif targets[2] == nil and not caster:HasModifier("modifier_heracles_berserk") then
            return UF_FAIL_CUSTOM
        else
            return UF_SUCESS
        end
    end
    return UF_SUCESS
end

function pepeg_jump:GetCustomCastErrorLocation(hLocation)
    return "No targets?"
end

modifier_pepeg_jump = class({})
function modifier_pepeg_jump:IsHidden() return true end
function modifier_pepeg_jump:DeclareFunctions()
    if self:GetParent() == self:GetCaster() then
	   return {	MODIFIER_PROPERTY_DISABLE_TURNING,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION }
    else
         return {   MODIFIER_PROPERTY_DISABLE_TURNING}
    end
end
function modifier_pepeg_jump:GetOverrideAnimation()
    return ACT_DOTA_OVERRIDE_ABILITY_3
end
function modifier_pepeg_jump:GetModifierDisableTurning()
	return 1
end
function modifier_pepeg_jump:IsDebuff() return false end
function modifier_pepeg_jump:RemoveOnDeath() return true end
function modifier_pepeg_jump:CheckState()
    local state = { --[[[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                   
                    [MODIFIER_STATE_ROOTED] = true,
                    [MODIFIER_STATE_SILENCED] = true,
                    [MODIFIER_STATE_MUTED] = true,]]
                    [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_DISARMED] = true,
                    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                }
    return state
end
function modifier_pepeg_jump:OnCreated(args)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    if IsServer() then
        self.point = self.ability:GetCursorPosition()
        self.radius = self.ability:GetSpecialValueFor("radius")

        self.Berserked = args.Berserked

        self.speed = self.ability:GetSpecialValueFor("speed")
        self.fly_duration = self.ability:GetSpecialValueFor("fly_duration")

        self.jump_start_pos = self.parent:GetOrigin()
        self.jump_distance = math.min(self.ability:GetCastRange(self.point, nil),(self.point - self.jump_start_pos):Length2D())
        self.jump_direction = (self.point - self.jump_start_pos):Normalized()

        -- load data
        self.jump_duration = self.fly_duration--self.jump_distance/self.speed
        self.jump_hVelocity = self.jump_distance/self.fly_duration--self.speed

        if self.parent == self:GetCaster() then
            self.jump_duration = self.jump_distance/self.speed
            self.jump_hVelocity = self.speed
        end

        self.jump_peak = self.ability:GetSpecialValueFor("max_height")
        
        --[[self.effect_duration = self.ability:GetSpecialValueFor("effect_duration")
        self.stun_height = self.ability:GetSpecialValueFor("stun_height")
        self.stun_damage = self.ability:GetSpecialValueFor("stun_damage")]]

        -- sync
        self.elapsedTime = 0
        self.motionTick = {}
        self.motionTick[0] = 0
        self.motionTick[1] = 0
        self.motionTick[2] = 0

        -- vertical motion model
        -- self.gravity = -10*1000
        self.jump_gravity = -self.jump_peak/(self.jump_duration*self.jump_duration*0.125)
        self.jump_vVelocity = (-0.5)*self.jump_gravity*self.jump_duration

        --[[local dash_fx = ParticleManager:CreateParticle("particles/heroes/anime_hero_uzume/uzume_dash.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
                        ParticleManager:SetParticleControl(dash_fx, 0, self.parent:GetOrigin()) -- point 0: origin, point 2: sparkles, point 5: burned soil
                        ParticleManager:SetParticleControl(dash_fx, 2, self.parent:GetOrigin())
                        ParticleManager:SetParticleControl(dash_fx, 5, self.parent:GetOrigin())

        self:AddParticle(dash_fx, false, false, -1, true, false)]]

        if self:ApplyVerticalMotionController() == false then
            self:Destroy()
        end
        if self:ApplyHorizontalMotionController() == false then 
            self:Destroy()
        end
    end
end
function modifier_pepeg_jump:UpdateHorizontalMotion(me, dt)
    self:SyncTime(1, dt)

    local target = self.jump_direction * self.jump_hVelocity * self.elapsedTime

    self.parent:SetOrigin(self.jump_start_pos + target)
    --self.parent:FaceTowards(self.point)
end
function modifier_pepeg_jump:UpdateVerticalMotion(me, dt)
    self:SyncTime(2, dt)

    local target = self.jump_vVelocity * self.elapsedTime + 0.5 * self.jump_gravity * self.elapsedTime * self.elapsedTime

    if self.parent == self:GetCaster() then target = target*0.001 end

    self.parent:SetOrigin(Vector(self.parent:GetOrigin().x, self.parent:GetOrigin().y, self.jump_start_pos.z + target))
end
function modifier_pepeg_jump:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_pepeg_jump:OnVerticalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_pepeg_jump:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end
function modifier_pepeg_jump:SyncTime( iDir, dt )
    -- check if already synced
    if self.motionTick[1]==self.motionTick[2] then
        self.motionTick[0] = self.motionTick[0] + 1
        self.elapsedTime = self.elapsedTime + dt
    end

    -- sync time
    self.motionTick[iDir] = self.motionTick[0]
    
    -- end motion
    if self.elapsedTime > self.jump_duration and self.motionTick[1] == self.motionTick[2] then
        self:PlayEffects()
        self:Destroy()
    end
end
function modifier_pepeg_jump:PlayEffects()
    if not self.do_damage then
        self.do_damage = true

        --[[local destruct_pfx =    ParticleManager:CreateParticle("particles/heroes/anime_hero_seth/seth_slam.vpcf", PATTACH_CUSTOMORIGIN, nil)
                                ParticleManager:SetParticleControl(destruct_pfx, 0, self.point)
                                ParticleManager:SetParticleControl(destruct_pfx, 1, Vector(self.radius, self.radius, self.radius))
                                ParticleManager:ReleaseParticleIndex(destruct_pfx)]]

        EmitSoundOnLocationWithCaster(self.point, "Hero_Leshrac.Split_Earth", self.parent)

        local hit_fx = ParticleManager:CreateParticle("particles/atalanta/atalanta_earthshock.vpcf", PATTACH_ABSORIGIN, self.parent )
		ParticleManager:SetParticleControl( hit_fx, 0, GetGroundPosition(self.parent:GetAbsOrigin(), self.parent))
		ParticleManager:SetParticleControl( hit_fx, 1, Vector(self:GetAbility():GetSpecialValueFor("radius"), 300, 150))

        local enemies = FindUnitsInRadius(  self.caster:GetTeamNumber(),
                                            self.point, 
                                            nil, 
                                            self.radius, 
                                            self.ability:GetAbilityTargetTeam(), 
                                            self.ability:GetAbilityTargetType(), 
                                            self.ability:GetAbilityTargetFlags(), 
                                            FIND_ANY_ORDER, 
                                            false)

        if self.parent == self.caster then
            self.damage = self:GetAbility():GetSpecialValueFor("pepeg_damage") + 1.25 * self.caster:GetStrength()
            self.percent_damage = self.parent:GetMaxHealth()*self.ability:GetSpecialValueFor("health_percent")/50
        else
            self.damage = self:GetAbility():GetSpecialValueFor("damage") + 1 * self.caster:GetStrength()
            self.percent_damage = self.parent:GetMaxHealth()*self.ability:GetSpecialValueFor("health_percent")/100
        end
        
        for _,enemy in ipairs(enemies) do
            if enemy ~= self.parent then 
                --[[local knockback = { should_stun = 1,
                                    knockback_duration = 0.5,
                                    duration = 0.5,
                                    knockback_distance = 0,
                                    knockback_height = self.stun_height,
                                    center_x = enemy:GetAbsOrigin().x,
                                    center_y = enemy:GetAbsOrigin().y,
                                    center_z = enemy:GetAbsOrigin().z }

                enemy:AddNewModifier(self.parent, self.ability, "modifier_knockback", knockback)

                    local damage_table = {  victim = enemy,
                                            attacker = self.parent, 
                                            damage = self.stun_damage,
                                            damage_type = self.ability:GetAbilityDamageType(),
                                            ability = self.ability }
                
                    ApplyDamage(damage_table)]]
                DoDamage(self.caster, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
                DoDamage(self.caster, enemy, self.percent_damage, DAMAGE_TYPE_PURE, 0, self:GetAbility(), false)
                CustomNetTables:SetTableValue("sync","pepe_slow" .. enemy:GetName(), { slow = -1*self:GetAbility():GetSpecialValueFor("slow") })
                enemy:AddNewModifier(self.caster, self, "modifier_pepe_slow", {duration = 2})
                enemy:AddNewModifier(self.caster, self, "modifier_pepe_mute", {duration = self:GetAbility():GetSpecialValueFor("mute_duration")})
            end
        end
        if (self.parent:GetTeamNumber() ~= self.caster:GetTeamNumber()) then
            --print(self.damage, self.caster:GetStrength(), "SIKKKA")
            --self.damage = self:GetAbility():GetSpecialValueFor("target_damage") + 1 * self.caster:GetStrength()
            --self.percent_damage = self.parent:GetMaxHealth()*self.ability:GetSpecialValueFor("health_percent")/50
            DoDamage(self.caster, self.parent, self.damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
            DoDamage(self.caster, self.parent, self.percent_damage, DAMAGE_TYPE_PURE, 0, self:GetAbility(), false)
            CustomNetTables:SetTableValue("sync","pepe_slow" .. self.parent:GetName(), { slow = -1*self:GetAbility():GetSpecialValueFor("target_slow") })
            self.parent:AddNewModifier(self.caster, self, "modifier_pepe_slow", {duration = 2})
            self.parent:AddNewModifier(self.caster, self, "modifier_pepe_mute", {duration = self:GetAbility():GetSpecialValueFor("mute_duration")})
        end
    end
end

modifier_pepe_slow = class({})

function modifier_pepe_slow:OnCreated()    
    self.slowPerc = CustomNetTables:GetTableValue("sync","pepe_slow" .. self:GetParent():GetName()).slow
    self.slowDur = 2.0

    if IsServer() then
        self:StartIntervalThink(0.1)

        --CustomNetTables:SetTableValue("sync","pepe_slow" .. self:GetParent():GetName(), { slow = self.slowPerc })
    end
end

function modifier_pepe_slow:OnRefresh(args)
    self:OnCreated()
end

function modifier_pepe_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
 
    return funcs
end

function modifier_pepe_slow:GetModifierMoveSpeedBonus_Percentage()
    if IsServer() then        
        return self.slowPerc
    elseif IsClient() then
        local slow = CustomNetTables:GetTableValue("sync","pepe_slow" .. self:GetParent():GetName()).slow
        return slow 
    end
end

function modifier_pepe_slow:OnIntervalThink()
    if self.slowDur > 0 then
        self.state = {}
        self.slowPerc = self.slowPerc + (100.0 / 4.0 * 0.1)
        self.slowDur = self.slowDur - 0.1

        CustomNetTables:SetTableValue("sync","pepe_slow" .. self:GetParent():GetName(), { slow = self.slowPerc })
    else  
        self:StartIntervalThink(-1)
        self:Destroy()
    end
end

-----------------------------------------------------------------------------------
function modifier_pepe_slow:GetEffectName()
    return "particles/items_fx/diffusal_slow.vpcf"
end

function modifier_pepe_slow:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_pepe_slow:GetAttributes() 
    return MODIFIER_ATTRIBUTE_NONE
end

function modifier_pepe_slow:IsPurgable()
    return false
end

function modifier_pepe_slow:IsDebuff()
    return true
end


function modifier_pepe_slow:RemoveOnDeath()
    return true
end

modifier_pepe_mute = class({})

function modifier_pepe_mute:CheckState()
    local state =   {
                    [MODIFIER_STATE_MUTED] = true,
                    }
 
    return state
end

function modifier_pepe_mute:IsHidden() return false end
function modifier_pepe_mute:RemoveOnDeath() return true end
function modifier_pepe_mute:IsDebuff() return true end