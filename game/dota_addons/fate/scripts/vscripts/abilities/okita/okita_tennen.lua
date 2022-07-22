LinkLuaModifier("modifier_tennen_stacks", "abilities/okita/modifiers/modifier_tennen_stacks", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tennen_active", "abilities/okita/modifiers/modifier_tennen_active", LUA_MODIFIER_MOTION_NONE)

okita_tennen = class({})

function okita_tennen:GetIntrinsicModifierName()
	return "modifier_tennen_stacks"
end

function okita_tennen:CastFilterResult()
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_okita_sandanzuki_charge") or caster:HasModifier("modifier_okita_sandanzuki_pepeg") then
    	return UF_SUCESS--UF_FAIL_CUSTOM
    else
    	return UF_SUCESS
    end
end

function okita_tennen:GetCustomCastError()
    return "#Sandanzuki_Active_Error"
end

function okita_tennen:OnSpellStart()
	local caster = self:GetCaster()

    EmitSoundOn("okita_kill_2", caster)
	caster:AddNewModifier(caster, self, "modifier_tennen_active", {duration = self:GetSpecialValueFor("duration")})
    --[[if caster:HasModifier("modifier_shukuchi_as") and caster.IsSummerMadnessAcquired and caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
        if caster:GetAbilityByIndex(3):GetName() ~= "okita_jet" and not caster:HasModifier("modifier_okita_jet_cd") then
            caster:SwapAbilities("okita_jet", "okita_weak_constitution_summer", true, false)
            Timers:CreateTimer(7, function()
                if caster:GetAbilityByIndex(3):GetName() == "okita_jet" then
                    caster:SwapAbilities("okita_jet", "okita_weak_constitution_summer", false, true)
                end
            end)
        end
    end]]
end