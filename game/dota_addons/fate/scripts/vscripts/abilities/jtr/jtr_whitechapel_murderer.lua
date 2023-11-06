jtr_whitechapel_murderer = class({})

LinkLuaModifier("modifier_whitechapel_murderer", "abilities/jtr/modifiers/modifier_whitechapel_murderer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_whitechapel_murderer_target", "abilities/jtr/jtr_whitechapel_murderer", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_whitechapel_cooldown", "abilities/jtr/modifiers/modifier_whitechapel_cooldown", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jtr_bloody_thirst_active", "abilities/jtr/jtr_bloody_thirst", LUA_MODIFIER_MOTION_NONE)

function jtr_whitechapel_murderer:OnSpellStart()
	local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local duration = self:GetSpecialValueFor("duration")

    caster:AddNewModifier(caster, self, "modifier_whitechapel_cooldown", { Duration = self:GetCooldown(1) })

    local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))

    EmitGlobalSound("jtr_combo")
    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Swordland"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)

    caster:AddNewModifier(caster, caster:FindAbilityByName("jtr_bloody_thirst"), "modifier_jtr_bloody_thirst_active", {duration = duration})
    

	caster:AddNewModifier(caster, self, "modifier_whitechapel_murderer", { Duration = duration,
																		   AgiBonus = self:GetSpecialValueFor("agi_bonus")
	})

    target:AddNewModifier(caster, self, "modifier_whitechapel_murderer_target", {duration = duration})
end

modifier_whitechapel_murderer_target = class({})

function modifier_whitechapel_murderer_target:IsDebuff() return true end
function modifier_whitechapel_murderer_target:IsHidden() return false end

function modifier_whitechapel_murderer_target:RemoveOnDeath() return true end

function modifier_whitechapel_murderer_target:DeclareFunctions()
    return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
            MODIFIER_PROPERTY_PROVIDES_FOW_POSITION}
end
function modifier_whitechapel_murderer_target:GetModifierIncomingDamage_Percentage(keys)
    if keys.attacker == self:GetCaster() then
        return self:GetAbility():GetSpecialValueFor("target_dmg")
    else
        return 0
    end
end

function modifier_whitechapel_murderer_target:GetModifierProvidesFOWVision()
    return 1
end

function modifier_whitechapel_murderer_target:GetEffectName()
    return "particles/jtr/jtr_whitechapel_track_circle.vpcf"
end

function modifier_whitechapel_murderer_target:OnDestroy()
    if not IsServer() then return end
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local radius = ability:GetSpecialValueFor("search_radius")

    local modifier = caster:FindModifierByName("modifier_whitechapel_murderer")
    if modifier then
        local duration_remaining = modifier.time_remaining
        if duration_remaining <= FrameTime()*2 then return end

        local targets = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
        for k,v in pairs(targets) do
            v:AddNewModifier(caster, ability, "modifier_whitechapel_murderer_target", {duration = duration_remaining})
            break
        end

        local ring_fx = ParticleManager:CreateParticle( "particles/jtr/jtr_whitechapel_kill_burst.vpcf", PATTACH_ABSORIGIN, parent)
        ParticleManager:SetParticleControl(ring_fx, 0, parent:GetAbsOrigin())
        ParticleManager:SetParticleControl(ring_fx, 2, Vector(radius, 0, 0))

        ParticleManager:ReleaseParticleIndex(ring_fx)
    end
end