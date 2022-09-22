atalanta_big_dipper = class({})
LinkLuaModifier("modifier_tanya_elinium_slow", "abilities/atalanta/atalanta_big_dipper", LUA_MODIFIER_MOTION_NONE)

function atalanta_big_dipper:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function atalanta_big_dipper:CastFilterResultLocation(location)
    local caster = self:GetCaster()

    if caster:HasArrow(3) or caster:HasModifier("modifier_tauropolos") then
        return UF_SUCCESS
    end

    return UF_FAIL_CUSTOM
end

function atalanta_big_dipper:GetCustomCastErrorLocation(location)
    return "#Not_enough_arrows"
end
function atalanta_big_dipper:OnSpellStart()
    LoopOverPlayers(function(player, playerID, playerHero)
            --print("looping through " .. playerHero:GetName())
            if playerHero.gachi == true then
                -- apply legion horn vsnd on their client
                CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="elinium"})
                --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
            end
        end)
end
function atalanta_big_dipper:OnChannelFinish(bInterrupted)
    if bInterrupted then
        self:GetCaster():Interrupt()
        return nil
    end
    --if GameRules:GetGameTime() - self:GetChannelStartTime() + 0.1 >= self:GetChannelTime() then
        local caster = self:GetCaster()
        local point = self:GetCursorPosition()

        local distance = self:GetSpecialValueFor("range")
        local direction = caster:GetForwardVector()--(point - caster:GetAbsOrigin()):Normalized()

        local width = self:GetSpecialValueFor("width")
        local speed = self:GetSpecialValueFor("speed")

        caster:UseArrow(3)

        local elinium_projectile = {    Ability             = self,
                                        EffectName          = "particles/custom/atalanta/atalanta_arrow_10stack.vpcf",
                                        vSpawnOrigin        = caster:GetAbsOrigin() + Vector(0,0,150),
                                        fDistance           = distance,
                                        fStartRadius        = 0,
                                        fEndRadius          = width,
                                        Source              = caster,
                                        bHasFrontalCone     = true,
                                        bReplaceExisting    = false,
                                        iUnitTargetTeam     = self:GetAbilityTargetTeam(),
                                        iUnitTargetFlags    = self:GetAbilityTargetFlags(),
                                        iUnitTargetType     = self:GetAbilityTargetType(),
                                        --fExpireTime         = GameRules:GetGameTime() + 10.0,
                                        bDeleteOnHit        = true,
                                        vVelocity           = Vector(direction.x,direction.y,0) * speed,
                                        bProvidesVision     = false,
                                        ExtraData           =   {   radius = self:GetAOERadius(),
                                                                    teams = self:GetAbilityTargetTeam(),
                                                                    types = self:GetAbilityTargetType(),
                                                                    flags = self:GetAbilityTargetFlags(),
                                                                    duration = self:GetSpecialValueFor("duration")
                                                                } 
                                    }
            
        ProjectileManager:CreateLinearProjectile(elinium_projectile)

        --EmitSoundOn("Tanya.Elinium.Cast.End", caster)
        caster:EmitSound("Ability.Powershot.Alt")
        EmitSoundOn("big_dipper_fly", caster)
    --end
end
function atalanta_big_dipper:OnProjectileThink(location)
    AddFOWViewer(2, location, 40, 0.4, false)
    AddFOWViewer(3, location, 40, 0.4, false)
end
function atalanta_big_dipper:OnProjectileHit_ExtraData(hTarget, vLocation, table)
    local enemies = FindUnitsInRadius(  self:GetCaster():GetTeamNumber(),
                                        vLocation,
                                        nil,
                                        table.radius,
                                        table.teams,
                                        table.types,
                                        table.flags,
                                        FIND_ANY_ORDER,
                                        false)

    for _,enemy in pairs(enemies) do
        if IsInSameRealm(enemy:GetAbsOrigin(), self:GetCaster():GetAbsOrigin()) then
            DoDamage(self:GetCaster(), enemy, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
            self:GetCaster():AddHuntStack(enemy, 1)

            enemy:AddNewModifier(self:GetCaster(), self, "modifier_atalanta_big_dipper_slow", {duration = table.duration})
        end
    end

    local effect_boom = ParticleManager:CreateParticle("particles/econ/items/crystal_maiden/crystal_maiden_cowl_of_ice/maiden_crystal_nova_cowlofice.vpcf", PATTACH_WORLDORIGIN, nil)
                        ParticleManager:SetParticleControl(effect_boom, 0, GetGroundPosition(vLocation, nil))
                        ParticleManager:SetParticleControl(effect_boom, 1, Vector(table.radius, 7, table.radius))
                        ParticleManager:ReleaseParticleIndex(effect_boom)

    StopSoundOn("big_dipper_fly", self:GetCaster())
    EmitSoundOn("big_dipper_boom", self:GetCaster())

    EmitSoundOnLocationWithCaster(vLocation, "big_dipper_boom", self:GetCaster())

    if not self:GetCaster().ArrowsOfTheBigDipperAcquired then
        return true
    end

    return false
end
---------------------------------------------------------------------------------------------------------------------
modifier_atalanta_big_dipper_slow = class({})
function modifier_atalanta_big_dipper_slow:IsHidden() return false end
function modifier_atalanta_big_dipper_slow:IsDebuff() return true end
function modifier_atalanta_big_dipper_slow:IsPurgable() return true end
function modifier_atalanta_big_dipper_slow:IsPurgeException() return true end
function modifier_atalanta_big_dipper_slow:RemoveOnDeath() return true end
function modifier_atalanta_big_dipper_slow:DeclareFunctions()
    local funcs = { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,}
    return funcs
end
function modifier_atalanta_big_dipper_slow:GetModifierMoveSpeedBonus_Percentage()
    return self:GetAbility():GetSpecialValueFor("slow")
end
--[[function modifier_atalanta_big_dipper_slow:GetEffectName()
    return "particles/items3_fx/silver_edge_slow.vpcf"
end
function modifier_atalanta_big_dipper_slow:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end]]