medea_blink = class({})


function medea_blink:CastFilterResultLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if not (IsServer() and IsLocked(hCaster)) and not ( IsServer() and not IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) ) then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function medea_blink:GetCustomCastErrorLocation(vLocation)
    local hCaster = self:GetCaster()

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if IsServer() and IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) then
            return "#Is_Locked"
        end
    end
    return "#Wrong_Target_Location"
end

 

function medea_blink:GetAOERadius()
	return self:GetSpecialValueFor("base_dist")
end

function medea_blink:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCursorPosition()
		local dist = self:GetSpecialValueFor("base_dist") 

		if (target - caster:GetAbsOrigin()):Length2D() > dist then
			target = caster:GetAbsOrigin() + (((target - caster:GetAbsOrigin()):Normalized()) * dist)
		end

		local afterBlinkPos = AbilityBlink(caster, target, self:GetAOERadius())



	end
end

