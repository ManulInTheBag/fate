gawain_excalibur_galatine_combo = class({})

LinkLuaModifier("modifier_sun_of_galatine_self", "abilities/gawain/modifiers/modifier_sun_of_galatine_self", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_excalibur_galatine_burn", "abilities/gawain/modifiers/modifier_excalibur_galatine_burn", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_excalibur_galatine_pizdets", "abilities/gawain/modifiers/modifier_excalibur_galatine_pizdets", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_galatine_combo_cd", "abilities/gawain/modifiers/modifier_gawain_combo_cd", LUA_MODIFIER_MOTION_NONE)

function gawain_excalibur_galatine_combo:GetAbilityDamageType()
    return DAMAGE_TYPE_MAGICAL
end

function gawain_excalibur_galatine_combo:OnSpellStart()
    local caster = self:GetCaster()
    local ability = self
    local radius = self:GetSpecialValueFor("area_of_effect")
    local bonus_damage = 0
    local damage = self:GetSpecialValueFor("damage") - 1500
    local fireTrailDuration = self:GetSpecialValueFor("duration")

    local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(ability:GetCooldown(1))
    caster:AddNewModifier(caster, self, "modifier_galatine_combo_cd", {duration = ability:GetCooldown(1)})
    
    giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 3.5)
    StartAnimation(caster, {duration=3.5, activity=ACT_DOTA_CAST_ABILITY_2, rate=0.1})
    --ability:ApplyDataDrivenModifier(caster, caster, "modifier_excalibur_galatine_vfx", {})  
    --ability:ApplyDataDrivenModifier(caster, caster, "modifier_excalibur_galatine_anim",{})
    EmitGlobalSound("gawain_galatine_combo_cast_1")
    --EmitGlobalSound("Uragirimono_no_Requiem")

    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.music == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Uragirimono_no_Requiem"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)

    caster:FindAbilityByName("gawain_excalibur_galatine"):StartCooldown(caster:FindAbilityByName("gawain_excalibur_galatine"):GetCooldown(1))

    local particle = ParticleManager:CreateParticle("particles/custom/gawain/gawain_combo.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(particle, 1, Vector(1000, 1000, 1000))

    local flameFx1 = ParticleManager:CreateParticle("particles/custom/gawain/gawain_excalibur_galatine_orb.vpcf", PATTACH_ABSORIGIN, caster )
    ParticleManager:SetParticleControl( flameFx1, 0, caster:GetAbsOrigin() + Vector(0,0,1000))

    Timers:CreateTimer( 3.0, function()
        ParticleManager:DestroyParticle( particle, false )
        ParticleManager:ReleaseParticleIndex( particle )
    end)

    local castFx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControl( castFx2, 0, caster:GetAbsOrigin())

    if caster.IsSoVAcquired then
        damage = damage + 1500
        local bonus_damage = 500
        fireTrailDuration = fireTrailDuration + 3
    end

    Timers:CreateTimer(3.5, function() --explosion part
            ParticleManager:DestroyParticle( flameFx1, false )
            ParticleManager:ReleaseParticleIndex( flameFx1 )
            if caster:IsAlive() then
                EmitGlobalSound("gawain_galatine_combo_activate_1")
                local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
                for k,v in pairs(targets) do
                    local dist = (v:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() 
                    finaldmg = damage*((radius-dist)/radius) + 1500 + bonus_damage
                    fireTrailDurationK = (fireTrailDuration*2/3)*(radius-dist)/radius+fireTrailDuration/3
                    DoDamage(caster, v, finaldmg, DAMAGE_TYPE_MAGICAL, 0, ability, false)
                    v:AddNewModifier(caster, self, "modifier_stunned", {Duration = 0.3})
                    v:AddNewModifier(caster, self, "modifier_excalibur_galatine_burn", {duration = fireTrailDurationK})
                    if caster.IsBeltAcquired then
                        v:AddNewModifier(caster, self, "modifier_excalibur_galatine_pizdets", {duration = 6*((radius-dist)/radius) + 4, armor_debuff = 30*((radius-dist)/radius)+20, magic_debuff = 15*((radius-dist)/radius)+5})
                    end     
                end 
                caster:EmitSound("Hero_Phoenix.SuperNova.Explode")
                local splashFx = ParticleManager:CreateParticle("particles/custom/screen_yellow_splash_gawain.vpcf", PATTACH_EYES_FOLLOW, caster)
                local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
                    ParticleManager:SetParticleControl( pfx, 0, self:GetCaster():GetAbsOrigin() )
                    ParticleManager:SetParticleControl( pfx, 1, Vector(1.5,1.5,1.5) )
                    ParticleManager:SetParticleControl( pfx, 3, self:GetCaster():GetAbsOrigin() )
                    ParticleManager:ReleaseParticleIndex(pfx)
                
                caster:AddNewModifier(caster, self, "modifier_sun_of_galatine_self", {duration = 12})
                Timers:CreateTimer( 3.0, function()
                    ParticleManager:DestroyParticle( splashFx, false )
                    ParticleManager:ReleaseParticleIndex( splashFx )
                end)
            else
                StopGlobalSound("Uragirimono_no_Requiem")
            end
        end)
end