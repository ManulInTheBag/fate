LinkLuaModifier("modifier_shukuchi_as", "abilities/okita/modifiers/modifier_shukuchi_as", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shukuchi_crit", "abilities/okita/modifiers/modifier_shukuchi_as", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_okita_window", "abilities/okita/okita_shukuchi", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tennen_stacks", "abilities/okita/modifiers/modifier_tennen_stacks", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tennen_active", "abilities/okita/modifiers/modifier_tennen_active", LUA_MODIFIER_MOTION_NONE)

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

function okita_shukuchi:GetIntrinsicModifierName()
	return "modifier_tennen_stacks"
end

function okita_shukuchi:GetAOERadius()
	return self:GetSpecialValueFor("base_dist")
end

function okita_shukuchi:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCursorPosition()
		local modifier = caster:FindModifierByName("modifier_tennen_stacks")
		local slashes = self:GetSpecialValueFor("base_slashes")
		local stacks = modifier and modifier:GetStackCount() or 0
		local dist = self:GetSpecialValueFor("base_dist") + (caster.IsReducedEarthAcquired and stacks*self:GetSpecialValueFor("stack_dist") or 0)

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

		caster:AddNewModifier(caster, self, "modifier_shukuchi_as", {duration = self:GetSpecialValueFor("duration") + (caster.IsCoatOfOathsAcquired and 1 or 0)})
		caster:AddNewModifier(caster, self, "modifier_tennen_active", {duration = self:GetSpecialValueFor("duration")})
		if caster.IsTennenAcquired then
			caster:AddNewModifier(caster, self, "modifier_shukuchi_crit", {duration = self:GetSpecialValueFor("duration") + (caster.IsCoatOfOathsAcquired and 1 or 0)})
		end

		--print(caster:GetAbsOrigin())
		--print(GetGroundPosition(caster:GetAbsOrigin(), caster))
	end
end

modifier_okita_window = class({})
function modifier_okita_window:IsHidden() return true end
function modifier_okita_window:IsPurgable() return false end
function modifier_okita_window:IsPurgeException() return true end