cu_chulain_rune_of_disengage = class({})

function cu_chulain_rune_of_disengage:GetManaCost(iLevel)
	if self:GetCaster():HasModifier("modifier_celtic_rune_attribute") then
		return 0
	else
		return 100
	end
end

function cu_chulain_rune_of_disengage:CastFilterResult()
    local hCaster = self:GetCaster()
    vLocation = true

    if vLocation
        and hCaster and not hCaster:IsNull() then
        if not (IsServer() and IsLocked(hCaster)) then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function cu_chulain_rune_of_disengage:GetCustomCastError()
    return "#Wrong_Target_Location"
end

function cu_chulain_rune_of_disengage:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_celtic_rune_attribute") then
		cooldown = cooldown - (cooldown * 0.75)
	end

	return cooldown
end

function cu_chulain_rune_of_disengage:OnSpellStart()
	local caster = self:GetCaster()
	local backward = caster:GetForwardVector() * self:GetSpecialValueFor("distance")
	local newLoc = caster:GetAbsOrigin() - backward
	local diff = newLoc - caster:GetAbsOrigin()

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_phantom_strike_end.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())

	HardCleanse(caster)
	caster:EmitSound("Hero_PhantomLancer.Doppelwalk")
	local i = 1
	while GridNav:IsBlocked(newLoc) or not GridNav:IsTraversable(newLoc) or i == 100 do
		i = i+1
		newLoc = caster:GetAbsOrigin() + diff:Normalized() * (self:GetSpecialValueFor("distance") - i*10)
	end
	Timers:CreateTimer(0.033, function() 
		caster:SetAbsOrigin(newLoc)
		ProjectileManager:ProjectileDodge(caster) 
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	end)

	if not caster:HasModifier("modifier_celtic_rune_attribute") then
		local ability = caster:FindAbilityByName("cu_chulain_rune_magic")
		ability:CloseSpellbook(self:GetCooldown(self:GetLevel()))		
	end

	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end) 
end