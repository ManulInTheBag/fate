LinkLuaModifier("modifier_lancelot_minigun", "abilities/lancelot/lancelot_minigun", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eternal_flame_shred", "abilities/lancelot/modifiers/modifier_eternal_flame_shred", LUA_MODIFIER_MOTION_NONE)

lancelot_minigun = lancelot_minigun or class({})

function lancelot_minigun:OnAbilityPhaseStart()
    local hCaster = self:GetCaster()

    EmitSoundOn("lancelot_minigun_cast", hCaster)

    return true
end
function lancelot_minigun:OnAbilityPhaseInterrupted()
    local hCaster = self:GetCaster()

    StopSoundOn("lancelot_minigun_cast", hCaster)
end
function lancelot_minigun:GetCastPoint()
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_lancelot_minigun") then
        return 0
    end

    return 0.3
end
function lancelot_minigun:GetCastAnimation()
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_lancelot_minigun") then
        return ACT_DOTA_CAST_ABILITY_1
    end

    return ACT_DOTA_CHANNEL_END_ABILITY_1
end
function lancelot_minigun:GetBehavior()
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_lancelot_minigun") then
        return (DOTA_ABILITY_BEHAVIOR_NO_TARGET)
    end

    return (DOTA_ABILITY_BEHAVIOR_POINT)
end

function lancelot_minigun:OnSpellStart()
    local hCaster   = self:GetCaster()

    local modifier = hCaster:AddNewModifier(hCaster, self, "modifier_lancelot_minigun", {duration = 5})
end
function lancelot_minigun:OnProjectileHit_ExtraData(hTarget, vLocation, hTable)
    if type(hTable.iShoot_PFX) == "number" then
        --[[if IsNotNull(hTarget) then
            ParticleManager:SetParticleControlEnt(
                                                    hTable.iShoot_PFX, 
                                                    1, 
                                                    hTarget, 
                                                    PATTACH_POINT_FOLLOW, 
                                                    "attach_hitloc", 
                                                    Vector(0, 0, 0), 
                                                    false
                                                )
        end]]

        --Timers:CreateTimer(0, function()
        ParticleManager:DestroyParticle(hTable.iShoot_PFX, false)
        ParticleManager:ReleaseParticleIndex(hTable.iShoot_PFX)
        --end)
    end
    if hTarget == nil then
        EmitSoundOnLocationWithCaster(vLocation, "lancelot_minigun_impact_"..RandomInt(1, 2), self:GetCaster())
        return
    end

    --print("hit", hTarget)
    local hCaster = self:GetCaster()
    local damage = hTable.fDamage

    EmitSoundOn("lancelot_minigun_impact_"..RandomInt(1, 2), hTarget)

    --[[if hTarget:HasModifier("modifier_barrage_debuff") then
        stacks = hTarget:GetModifierStackCount("modifier_barrage_debuff", hCaster)
        damage = damage + (stacks * (self:GetSpecialValueFor("stack_damage")+0.1*damage_bonus))
    end]]

    if hCaster:HasModifier("modifier_eternal_flame_attribute") then
        hTarget:AddNewModifier(hCaster, self, "modifier_eternal_flame_shred", { Duration = 5 })
    end
    DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
    --hTarget:AddNewModifier(hCaster, self, "modifier_barrage_debuff", { Duration = 5 })
end

lancelot_minigun_end = class({})

function lancelot_minigun_end:OnSpellStart()
    local hCaster   = self:GetCaster()

    hCaster:RemoveModifierByName("modifier_lancelot_minigun")
end
---------------------------------------------------------------------------------------------------------------------

modifier_lancelot_minigun = class({})

function modifier_lancelot_minigun:IsHidden()                                                           return false end
function modifier_lancelot_minigun:IsDebuff()                                                           return false end
function modifier_lancelot_minigun:RemoveOnDeath()                                                      return true end
function modifier_lancelot_minigun:CheckState()
    local hState =  {
                        --[MODIFIER_STATE_STUNNED] = true,
                        --[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,
                        [MODIFIER_STATE_DISARMED]                        = true,

                        [MODIFIER_STATE_NO_UNIT_COLLISION]               = true,
                        [MODIFIER_STATE_ROOTED]                        = true,
                        [MODIFIER_STATE_ALLOW_PATHING_THROUGH_CLIFFS]   = true,
                        [MODIFIER_STATE_ALLOW_PATHING_THROUGH_TREES]    = true, --NEED BECAUSE SOMETIMES U CAN'T CLICK OVER TREE... WTF
                    }
    return hState
end
function modifier_lancelot_minigun:DeclareFunctions()
    local hFunc =   { 
                        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
                        MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
                        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
                        MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
                    }
    return hFunc
end
function modifier_lancelot_minigun:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_1
end
function modifier_lancelot_minigun:GetModifierTurnRate_Percentage(keys)
    return self.fSlowTurning
end
function modifier_lancelot_minigun:GetModifierProvidesFOWVision(keys)
    return 1
end
function modifier_lancelot_minigun:GetModifierMoveSpeed_Absolute(keys)
    if IsServer() then
        return 1
    end
end
function modifier_lancelot_minigun:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()

    self.fSlowTurning = self.hAbility:GetSpecialValueFor("slow_turning")

    self.sAttach         = "attach_minigun"
    self.sProjectileName = "particles/heroes/anime_hero_lancelot/lancelot_minigun_projectile.vpcf"

    if IsServer() then
        if not (self.hCaster:GetAbilityByIndex(0):GetName() == "lancelot_minigun_end") then
            self.hCaster:SwapAbilities("lancelot_minigun", "lancelot_minigun_end", false, true)
        end

        self.vPoint    = self.vPoint or self.hAbility:GetCursorPosition() + self.hCaster:GetForwardVector()
        self.fDistance = self.hAbility:GetSpecialValueFor("range")
        self.fSpeed    = self.hAbility:GetSpecialValueFor("speed")
        self.fWidth    = self.hAbility:GetSpecialValueFor("width")

        self.iPatrons   = self.hAbility:GetSpecialValueFor("bullets_per_second")
        self.flInterval = 1 / self.iPatrons

        self.fBaseDamage   = self.hAbility:GetSpecialValueFor("base_damage")
        self.damage_perc   = self.hAbility:GetSpecialValueFor("atk_damage")/100

        self.hPatronProjectileTable =   {
                                            --EffectName        = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf",--"particles/heroes/anime_hero_guts/guts_crossbow_projectile.vpcf",
                                            source            = self.hParent,
                                            caster            = self.hParent,
                                            ability           = self.hAbility,
                                            --vSpawnOrigin      = self.hParent:GetAttachmentOrigin(self.hParent:ScriptLookupAttachment("attach_attack1")),

                                            iUnitTargetTeam   = DOTA_UNIT_TARGET_TEAM_ENEMY,
                                            iUnitTargetType   = DOTA_UNIT_TARGET_ALL,
                                            iUnitTargetFlags  = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE,

                                            distance         = self.fDistance,
                                            startRadius      = self.fWidth,
                                            endRadius        = self.fWidth,
                                            DeleteOnHit = true,

                                            ExtraData         = {
                                                                    iShoot_PFX  = 0,
                                                                    fDamage     = self.fBaseDamage
                                                                }
                                        }

        self.sEmitSound = "lancelot_minigun_loop"
        self.sound_timer = 0
        EmitSoundOn(self.sEmitSound, self.hParent)

        self.interval_timer = 0
        self.full_timer = 0

        self.manacost = self.hAbility:GetSpecialValueFor("mana_per_bullet")

        Timers:CreateTimer(FrameTime(), function()
            if self then
                self:OnIntervalThink()
            end
        end)
        self:StartIntervalThink(FrameTime())
    end
end
function modifier_lancelot_minigun:OnRefresh(hTable)
    self:OnCreated(hTable)
end
function modifier_lancelot_minigun:OnIntervalThink()
    if IsServer() then

        self.sound_timer = self.sound_timer + FrameTime()
        if self.sound_timer >= 1.7 then
            self.sound_timer = 0
            EmitSoundOn(self.sEmitSound, self.hParent)
        end

        self.full_timer = self.full_timer + FrameTime()
        self.interval_timer = self.interval_timer + FrameTime()
        if self.hCaster:IsStunned() then
            self.hCaster:RemoveModifierByName("modifier_lancelot_minigun")
            return
        end
        if not (self.interval_timer >= self.flInterval) then return end
        self.interval_timer = 0

        if self.hCaster:GetMana() < self.manacost then
            self.hCaster:RemoveModifierByName("modifier_lancelot_minigun")
            return
        end
        self.hCaster:SpendMana(self.manacost, self.hAbility)

        local vDirection = self.hParent:GetForwardVector()

        local vAttach = self.hParent:GetAttachmentOrigin(self.hParent:ScriptLookupAttachment(self.sAttach))
        local vPoint  = vAttach + vDirection * self.fDistance

        local iShoot_PFX =  ParticleManager:CreateParticle(self.sProjectileName, PATTACH_ABSORIGIN_FOLLOW, self.hParent)
                            ParticleManager:SetParticleShouldCheckFoW(iShoot_PFX, false)
                            ParticleManager:SetParticleControlEnt(
                                                                    iShoot_PFX, 
                                                                    0, 
                                                                    self.hParent, 
                                                                    PATTACH_POINT_FOLLOW, 
                                                                    self.sAttach, 
                                                                    Vector(0, 0, 0), 
                                                                    false
                                                                )
                            ParticleManager:SetParticleControl(iShoot_PFX, 1, vPoint)
                            ParticleManager:SetParticleControl(iShoot_PFX, 2, Vector(self.fSpeed, 0, 0))

        self.hPatronProjectileTable.sourceLoc = vAttach
        self.hPatronProjectileTable.direction    = self.hCaster:GetForwardVector()
        self.hPatronProjectileTable.distance    = self.fDistance
        self.hPatronProjectileTable.speed    = self.fSpeed

        self.hPatronProjectileTable.ExtraData.iShoot_PFX = iShoot_PFX
        self.hPatronProjectileTable.ExtraData.fDamage    = self.fBaseDamage + self.hCaster:GetAverageTrueAttackDamage(self.hCaster)*self.damage_perc

        FATE_ProjectileManager:CreateLinearProjectile(self.hPatronProjectileTable)
    end
end
function modifier_lancelot_minigun:OnDestroy()
    if IsServer()
        and IsNotNull(self.hCaster) then

        if not (self.hCaster:GetAbilityByIndex(0):GetName() == "lancelot_minigun") then
            self.hCaster:SwapAbilities("lancelot_minigun", "lancelot_minigun_end", true, false)
        end

        self.hCaster:FindAbilityByName("lancelot_minigun"):StartCooldown(self.full_timer*self.hAbility:GetSpecialValueFor("cooldown_per_second"))

        StopSoundOn(self.sEmitSound, self.hParent)
    end
end