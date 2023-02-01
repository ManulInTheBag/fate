LinkLuaModifier("modifier_shukuchi_as", "abilities/okita/modifiers/modifier_shukuchi_as", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shukuchi_crit", "abilities/okita/modifiers/modifier_shukuchi_as", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_window", "abilities/okita/okita_shukuchi", LUA_MODIFIER_MOTION_NONE)

okita_shukuchi = class({})

function okita_shukuchi:CastFilterResultLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if not (IsServer() and IsLocked(hCaster)) and not ( IsServer() and not IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) ) then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function okita_shukuchi:GetCustomCastErrorLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if IsServer() and IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) then
            return "#Is_Locked"
        end
    end
    return "#Wrong_Target_Location"
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

		if true then
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