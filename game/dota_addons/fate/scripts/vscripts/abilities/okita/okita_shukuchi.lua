LinkLuaModifier("modifier_shukuchi_as", "abilities/okita/modifiers/modifier_shukuchi_as", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shukuchi_crit", "abilities/okita/modifiers/modifier_shukuchi_as", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_window", "abilities/okita/okita_shukuchi", LUA_MODIFIER_MOTION_NONE)

locks = {
    --"modifier_purge",
    "modifier_sex_scroll_root",
    "locked",
    "dragged",
    "jump_pause_postlock",
    "modifier_aestus_domus_aurea_enemy",
    "modifier_aestus_domus_aurea_ally",
    "modifier_aestus_domus_aurea_nero",
    "modifier_rho_aias",
    "modifier_binding_chains",
    "modifier_arcueid_melty",
    --"modifier_whitechapel_murderer",
    --"modifier_whitechapel_murderer_ally",
    --"modifier_whitechapel_murderer_enemy",
}


okita_shukuchi = class({})

function okita_shukuchi:IsLocked(target)
    for i=1, #locks do
        if target:HasModifier(locks[i]) then return true end
    end
    return false
end

function okita_shukuchi:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if caster:HasModifier("modifier_okita_sandanzuki_charge") or caster:HasModifier("modifier_okita_sandanzuki_pepeg") then
    	return UF_SUCESS--UF_FAIL_CUSTOM
    elseif IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
    	return UF_FAIL_CUSTOM
    --[[elseif self:IsLocked(caster) or caster:HasModifier("jump_pause_nosilence") or caster:HasModifier("modifier_story_for_someones_sake") then
        return UF_FAIL_CUSTOM]] --smth causes bugs here
    else
    	return UF_SUCCESS
    end
end

function okita_shukuchi:GetCustomCastErrorLocation(hLocation)
	local caster = self:GetCaster()
    if caster:HasModifier("modifier_okita_sandanzuki_charge") or caster:HasModifier("modifier_okita_sandanzuki_pepeg") then
    	return "#Sandanzuki_Active_Error"
    elseif not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
    	return "#Wrong_Target_Location"
    end
end

function okita_shukuchi:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCursorPosition()
		local modifier = caster:FindModifierByName("modifier_tennen_stacks")
		local slashes = self:GetSpecialValueFor("base_slashes")
		local stacks = modifier and modifier:GetStackCount() or 0
		local dist = self:GetSpecialValueFor("base_dist") + stacks*self:GetSpecialValueFor("stack_dist")

		if (target - caster:GetAbsOrigin()):Length2D() > dist then
			target = caster:GetAbsOrigin() + (((target - caster:GetAbsOrigin()):Normalized()) * dist)
		end

		ProjectileManager:ProjectileDodge(caster)

		local particle1 = ParticleManager:CreateParticle("particles/okita/okita_shukuchi.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(particle1, 0, caster:GetAbsOrigin())

		if not self:IsLocked(caster) then
			FindClearSpaceForUnit(caster, target, true)
		end

		local particle2 = ParticleManager:CreateParticle("particles/okita/okita_shukuchi.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(particle2, 0, caster:GetAbsOrigin())

		caster:AddNewModifier(caster, self, "modifier_shukuchi_as", {duration = self:GetSpecialValueFor("as_duration") + (caster.IsCoatOfOathsAcquired and 1 or 0)})
		if caster.IsTennenAcquired and caster:HasModifier("modifier_tennen_active") then
			caster:AddNewModifier(caster, self, "modifier_shukuchi_crit", {duration = self:GetSpecialValueFor("as_duration") + (caster.IsCoatOfOathsAcquired and 1 or 0)})
		end

		--print(caster:GetAbsOrigin())
		--print(GetGroundPosition(caster:GetAbsOrigin(), caster))
		
		if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 and caster:HasModifier("modifier_tennen_active") then
			if (caster:GetAbilityByIndex(5):GetName()=="okita_sandanzuki") and caster:FindAbilityByName("okita_sandanzuki"):IsCooldownReady() and not caster:HasModifier("modifier_okita_zekken_cd") then
				if not caster:HasModifier("modifier_okita_window") then
					caster:SwapAbilities("okita_zekken", "okita_sandanzuki", true, false)
					caster:AddNewModifier(caster, self, "modifier_okita_window", {duration = 4})
					Timers:CreateTimer(4, function()
						caster:SwapAbilities("okita_zekken", "okita_sandanzuki", false, true)
					end)
				end
			end
		end
	end
end

modifier_okita_window = class({})
function modifier_okita_window:IsHidden() return true end
function modifier_okita_window:IsPurgable() return false end
function modifier_okita_window:IsPurgeException() return true end