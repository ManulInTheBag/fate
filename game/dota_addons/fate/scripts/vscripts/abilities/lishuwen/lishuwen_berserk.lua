lishuwen_berserk = class({})
modifier_lishuwen_berserk_stats = class({})

LinkLuaModifier("modifier_berserk","abilities/lishuwen/modifiers/modifier_berserk", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shuwen_berserk_cc_immune","abilities/lishuwen/modifiers/modifier_berserk", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lishuwen_berserk_stats", "abilities/lishuwen/lishuwen_berserk", LUA_MODIFIER_MOTION_NONE)

local revokes = {    
    "modifier_enkidu_hold",
    "jump_pause",
    "pause_sealdisabled",
    "rb_sealdisabled",
    "revoked",
    "round_pause",
    "modifier_nss_shock",
    "modifier_ubw_chronosphere"
}

function lishuwen_berserk:OnSpellStart()
	local caster = self:GetCaster()	
    local ability = self

    --print("Start Berserk Concha")
    
    HardCleanse(caster)
    caster:EmitSound("Hero_Sven.WarCry")
    caster:EmitSound("bers_act")
    EmitZlodemonTrueSound("moskes_li_bers",caster)
    local dispel = ParticleManager:CreateParticle( "particles/units/heroes/hero_abaddon/abaddon_death_coil_explosion.vpcf", PATTACH_ABSORIGIN, caster )
    ParticleManager:SetParticleControl( dispel, 1, caster:GetAbsOrigin())
    -- Destroy particle after delay
    Timers:CreateTimer( 2.0, function()
        ParticleManager:DestroyParticle( dispel, false )
        ParticleManager:ReleaseParticleIndex( dispel )
    end)

	caster:AddNewModifier(caster, ability, "modifier_berserk", { Duration = self:GetSpecialValueFor("duration"),
															     CCImmuneDuration = self:GetSpecialValueFor("cc_immune_duration") })

    caster:AddNewModifier(caster, ability, "modifier_shuwen_berserk_cc_immune", { duration = self:GetSpecialValueFor("cc_immune_duration")})
end

function lishuwen_berserk:CastFilterResult()
    local caster = self:GetCaster()   

    if self:IsRevoked(caster) then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end

--[[function lishuwen_berserk:GetIntrinsicModifierName()
    return "modifier_lishuwen_berserk_stats"
end]]

function lishuwen_berserk:GetCustomCastError()
    return "#Revoked"
end

function lishuwen_berserk:GetAbilityTextureName()
    return "custom/lishuwen_berserk"
end

function lishuwen_berserk:IsRevoked(target)
    for i=1, #revokes do
        if target:HasModifier(revokes[i]) then return true end
    end
    
    return false
end

-----Passive stats
function modifier_lishuwen_berserk_stats:DeclareFunctions()
    return { MODIFIER_PROPERTY_HEALTH_BONUS,
             MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_lishuwen_berserk_stats:GetModifierHealthBonus()
    return self:GetParent():GetAgility() * 0
end

function modifier_lishuwen_berserk_stats:GetModifierPreAttack_BonusDamage()
    return self:GetParent():GetStrength() * 0
end

function modifier_lishuwen_berserk_stats:IsHidden()
    return true
end