LinkLuaModifier("modifier_jeanne_flag_swing_vfx", "abilities/jeanne_alter/jeanne_flag_swing", LUA_MODIFIER_MOTION_NONE)

jeanne_flag_swing = class({})

function jeanne_flag_swing:GetCastPoint()
    return self:GetCaster():GetSecondsPerAttack()/1.2
end
function jeanne_flag_swing:OnAbilityPhaseStart()
    if IsServer() then
        self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_jeanne_flag_swing_vfx", {duration = self:GetCaster():GetSecondsPerAttack()/1.2})

        return true
    end
end
function jeanne_flag_swing:GetPlaybackRateOverride()
    local pct_reduc = self:GetCaster():GetSecondsPerAttack()
    local base_rate = 0.4
    local cast_point = base_rate/pct_reduc
    return cast_point
end
function jeanne_flag_swing:OnSpellStart()
    local caster = self:GetCaster()

    --self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_jeanne_flag_swing_vfx", {duration = 0.5})

    if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then      
        if caster:FindAbilityByName("jeanne_lagron"):IsCooldownReady() 
            and caster:FindAbilityByName("jeanne_lagron_combo"):IsCooldownReady()  
            and caster:GetAbilityByIndex(5):GetName() == "jeanne_lagron"
            and caster:HasModifier("modifier_jeanne_lagron_combo_window") then
            caster:SwapAbilities("jeanne_lagron", "jeanne_lagron_combo", false, true)
            Timers:CreateTimer(4, function()
                caster:SwapAbilities("jeanne_lagron", "jeanne_lagron_combo", true, false)
            end)
        end
    end

    caster:EmitSound("Hero_Phoenix.FireSpirits.Launch")

    local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        500,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)

    for _,enemy in pairs(enemies) do
        caster:EmitSound("Hero_DragonKnight.BreathFire")
        local caster_angle = caster:GetAnglesAsVector().y
        local origin_difference = caster:GetAbsOrigin() - enemy:GetAbsOrigin()
        local damage = self:GetSpecialValueFor("damage")

        if caster.OblivionCorrectionAcquired and enemy:GetHealth()/enemy:GetMaxHealth() >= 0.7 then
            damage = damage*1.5
        end

        local origin_difference_vector = origin_difference:Normalized()

        local flame = 
        {
            Ability = self,
            EffectName = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf",
            iMoveSpeed = 2000,
            vSpawnOrigin = caster:GetAbsOrigin(),
            fDistance = 300,
            fStartRadius = 100,
            fEndRadius = 200,
            Source = caster,
            bHasFrontalCone = true,
            bReplaceExisting = false,
            iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
            iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
            iUnitTargetType = DOTA_UNIT_TARGET_ALL,
            fExpireTime = GameRules:GetGameTime() + 0.5,
            bDeleteOnHit = false,
            vVelocity = -Vector(origin_difference_vector.x, origin_difference_vector.y, 0) * 1500
        }
        ProjectileManager:CreateLinearProjectile(flame)

        local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)

        origin_difference_radian = origin_difference_radian * 180
        local enemy_angle = origin_difference_radian / math.pi

        enemy_angle = enemy_angle + 180.0

        local result_angle = enemy_angle - caster_angle
        result_angle = math.abs(result_angle)

        if result_angle <= 110 then
            if not enemy:IsMagicImmune() then
                DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
                if enemy:HasModifier("modifier_jeanne_curse_active") and caster.OblivionCorrectionAcquired then
                    enemy:AddNewModifier(caster, caster:FindAbilityByName("jeanne_curse"), "modifier_jeanne_curse_active", {duration = caster:FindAbilityByName("jeanne_curse"):GetSpecialValueFor("duration")})
                end
            end
            caster:PerformAttack( enemy, true, true, true, true, false, false, true )
        end
    end
end

function jeanne_flag_swing:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
    if hTarget == nil then
        return 
    end

    local hCaster = self:GetCaster()
    --print("iampepeg")
end


modifier_jeanne_flag_swing_vfx = class({})

function modifier_jeanne_flag_swing_vfx:IsHidden()            return true end
function modifier_jeanne_flag_swing_vfx:IsDebuff()            return false end
function modifier_jeanne_flag_swing_vfx:IsPurgable()          return false end
function modifier_jeanne_flag_swing_vfx:IsPurgeException()    return false end
function modifier_jeanne_flag_swing_vfx:RemoveOnDeath()       return false end
function modifier_jeanne_flag_swing_vfx:OnCreated(hTable)
    if IsServer() then
        self.parent  = self:GetParent()
        self.swing_fx = ParticleManager:CreateParticle("particles/jeanne_alter/noire_slash_cast.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, self.parent)
        local swing = self.swing_fx
            
        ParticleManager:SetParticleControlEnt(self.swing_fx, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_attack1", self.parent:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(self.swing_fx, 1, self.parent, PATTACH_POINT_FOLLOW, "attach_attack1", self.parent:GetAbsOrigin(), true)
            
        Timers:CreateTimer(0.5, function()
            ParticleManager:DestroyParticle(swing, false)
            ParticleManager:ReleaseParticleIndex(swing)
        end)
    end
end