
LinkLuaModifier("modifier_nobbus_dash", "abilities/demon_king_nobunaga/maou_nobbus_gumi_dash", LUA_MODIFIER_MOTION_NONE)
maou_nobbus_gumi_dash = class({})



function maou_nobbus_gumi_dash:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_nobbus_dash", { Duration = 1 })
end

modifier_nobbus_dash = class({})
function modifier_nobbus_dash:IsHidden() return true end
function modifier_nobbus_dash:IsDebuff() return false end
function modifier_nobbus_dash:IsPurgable() return false end
function modifier_nobbus_dash:IsPurgeException() return false end
function modifier_nobbus_dash:RemoveOnDeath() return true end
function modifier_nobbus_dash:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_nobbus_dash:GetMotionPriority() return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH end
function modifier_nobbus_dash:CheckState()
    local state =   { 
                        --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
                        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
                        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                        [MODIFIER_STATE_ROOTED] = true,
                        --[MODIFIER_STATE_DISARMED] = true,
                        --[MODIFIER_STATE_SILENCED] = true,
                        --[MODIFIER_STATE_MUTED] = true,
                    }
    return state
end
function modifier_nobbus_dash:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION, 
                    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,}
    return func
end
function modifier_nobbus_dash:GetOverrideAnimation()
    return ACT_DOTA_ATTACK
end
function modifier_nobbus_dash:GetOverrideAnimationRate()
    return 1.0
end
function modifier_nobbus_dash:OnCreated(table)
    self.caster = self:GetCaster()
    self.parent = self:GetParent()
    self.ability = self:GetAbility()

    if IsServer() then
        self.speed          = self.ability:GetSpecialValueFor("speed")
        self.distance       =self.ability:GetSpecialValueFor("range")
        self.damage         = self.ability:GetSpecialValueFor("damage_per_hit")

        self.point          = self.ability:GetCursorPosition() + RandomVector(1)
        self.direction      = (self.point - self.parent:GetAbsOrigin()):Normalized()
        self.direction.z    = 0
        self.point          = self.parent:GetAbsOrigin() + self.direction * self.distance

        self.parent:Stop()
        self.parent:FaceTowards(self.point)
        self.parent:SetForwardVector(self.direction)

        self.FirstTarget        = nil
        
        self.DamageToTargetsPercentTable = {}


        self.parent:EmitSound("nobusengumi_2")


        local dash_fx = ParticleManager:CreateParticle("particles/okita/okita_vendetta_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(dash_fx, 0, self.parent:GetAbsOrigin())

        self:AddParticle(dash_fx, false, false, -1, true, false)

        self.dash_fx2 = ParticleManager:CreateParticle("particles/okita/okita_surge_try.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(self.dash_fx2, 0, self.parent:GetAbsOrigin())

        self:AddParticle(self.dash_fx2, false, false, -1, true, false)

        self:StartIntervalThink(FrameTime())

    end
end
function modifier_nobbus_dash:OnIntervalThink()
    self:UpdateHorizontalMotion(self:GetParent(), FrameTime())
end
function modifier_nobbus_dash:OnRefresh(table)
    self:OnCreated(table)
end
function modifier_nobbus_dash:UpdateHorizontalMotion(me, dt)
    if IsServer() then
         

        if self.distance >= 0 then
            local units_per_dt = self.speed * dt
            local parent_pos = self.parent:GetAbsOrigin()
            local direction = self.direction--self.parent:GetForwardVector()

            local next_pos = parent_pos + direction * units_per_dt
            next_pos = GetGroundPosition(next_pos, self.parent)
            local distance_will = self.distance - units_per_dt

            if distance_will < 0 then
                --next_pos = self.point
            end

            self.parent:SetAbsOrigin(next_pos)

            self:PlayEffects(parent_pos, next_pos)

            self.distance = self.distance - units_per_dt
        else
            self.parent:RemoveModifierByName("modifier_okita_sandanzuki_charge")
            self:Destroy()
        end
    end
end
function modifier_nobbus_dash:PlayEffects(pos1, pos2)
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

                local caster = self:GetCaster()
                local ability = self:GetAbility()

                local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
                ParticleManager:SetParticleControl(slashIndex, 0, enemy:GetAbsOrigin())
                ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))
                ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))
                Timers:CreateTimer(0.4, function()
                    self.particle = ParticleManager:CreateParticle("particles/custom/false_assassin/tsubame_gaeshi/slashes.vpcf", PATTACH_ABSORIGIN, caster)
                    ParticleManager:SetParticleControl(self.particle, 0, enemy:GetAbsOrigin())
                end)

                Timers:CreateTimer(0.8, function()
                    caster:EmitSound("nobusengumi_1")

                  
                    local damage = ability:GetSpecialValueFor("base_damage") + caster.Level * ability:GetSpecialValueFor("damage_per_caster_level")


                    DoDamage(caster.Caster, enemy, damage, DAMAGE_TYPE_PURE, 0, caster.Ability, false)



                    enemy:EmitSound("Tsubame_Slash_" .. math.random(1,3))
                end)
                Timers:CreateTimer(1, function()

                    local damage = ability:GetSpecialValueFor("base_damage")  + caster.Level * ability:GetSpecialValueFor("damage_per_caster_level")


                    DoDamage(caster.Caster, enemy, damage, DAMAGE_TYPE_PURE, 0, caster.Ability, false)



                    enemy:EmitSound("Tsubame_Slash_" .. math.random(1,3))
                end)
                Timers:CreateTimer(1.2, function()

                    local damage = ability:GetSpecialValueFor("base_damage")  + caster.Level * ability:GetSpecialValueFor("damage_per_caster_level")


                     DoDamage(caster.Caster, enemy, damage, DAMAGE_TYPE_PURE, 0, caster.Ability, false)


                    enemy:EmitSound("Tsubame_Focus")
                   
                end)
                Timers:CreateTimer(1.5, function()
                    ParticleManager:DestroyParticle(self.particle, true)
                    ParticleManager:ReleaseParticleIndex(self.particle)
                    ParticleManager:DestroyParticle(slashIndex, true)
                    ParticleManager:ReleaseParticleIndex(slashIndex)
                    end)
            end
        end
    end
end
function modifier_nobbus_dash:OnHorizontalMotionInterrupted()
    if IsServer() then
        self:Destroy()
    end
end
function modifier_nobbus_dash:OnDestroy()
    if IsServer() then
        self.parent:InterruptMotionControllers(true)
    end
end
