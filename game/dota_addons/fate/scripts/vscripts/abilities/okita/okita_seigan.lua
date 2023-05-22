LinkLuaModifier("modifier_okita_seigan_anim", "abilities/okita/okita_seigan", LUA_MODIFIER_MOTION_NONE)

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
    "modifier_rho_aias_emiya",
    "modifier_binding_chains",
    --"modifier_whitechapel_murderer",
    --"modifier_whitechapel_murderer_ally",
    --"modifier_whitechapel_murderer_enemy",
}

okita_seigan = class({})

function okita_seigan:IsLocked(target)
    for i=1, #locks do
        if target:HasModifier(locks[i]) then return true end
    end
    return false
end

function okita_seigan:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()

    if caster:HasModifier("modifier_okita_sandanzuki_charge") or caster:HasModifier("modifier_okita_sandanzuki_pepeg") then
    	return UF_FAIL_CUSTOM
    elseif IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
    	return UF_FAIL_CUSTOM
   	--[[elseif self:IsLocked(caster) or caster:HasModifier("jump_pause_nosilence") or caster:HasModifier("modifier_story_for_someones_sake") then
        return UF_FAIL_CUSTOM]] --smth causes bugs here
    else
    	return UF_SUCCESS
    end
end

function okita_seigan:GetCustomCastErrorLocation(hLocation)
	local caster = self:GetCaster()
    if caster:HasModifier("modifier_okita_sandanzuki_charge") then
    	return "#Sandanzuki_Active_Error"
    elseif not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
    	return "#Wrong_Target_Location"
    end
end

function okita_seigan:OnAbilityPhaseStart()
	EmitSoundOn("okita_attack_4", self:GetCaster())
	return true
end

function okita_seigan:OnAbilityPhaseInterrupted()
	StopSoundOn("okita_attack_4", self:GetCaster())
end

function okita_seigan:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local target = self:GetCursorPosition()
	local modifier = caster:FindModifierByName("modifier_tennen_stacks")
	local stacks = modifier and modifier:GetStackCount() or 0
	local dist = self:GetSpecialValueFor("base_dist") + stacks*self:GetSpecialValueFor("stack_dist")

	if (target - caster:GetAbsOrigin()):Length2D() > dist then
		target = caster:GetAbsOrigin() + (((target - caster:GetAbsOrigin()):Normalized()) * dist)
	end

	dist = (target - caster:GetAbsOrigin()):Length2D()

	local time = dist/2500

	local qdProjectile = 
	{
		Ability = ability,
        EffectName = nil,--"particles/custom/false_assassin/fa_quickdraw.vpcf",
        iMoveSpeed = 2500,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = dist,
        fStartRadius = 200,
        fEndRadius = 200,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 2500
	}
	if not self:IsLocked(caster) then
		local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)

		giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", time)
		caster:AddNewModifier(caster, self, "modifier_okita_seigan_anim", {})

		local fxIndex = ParticleManager:CreateParticle("particles/okita/okita_counterhelix.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl( fxIndex, 0, caster:GetAbsOrigin())
		local sin = Physics:Unit(caster)
		caster:SetPhysicsFriction(0)
		caster:SetPhysicsVelocity(caster:GetForwardVector() * 2500)
		caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)

		Timers:CreateTimer("okita_dash", {
			endTime = time,
			callback = function()
			caster:OnPreBounce(nil)
			caster:SetBounceMultiplier(0)
			caster:PreventDI(false)
			caster:SetPhysicsVelocity(Vector(0,0,0))
			caster:RemoveModifierByName("pause_sealenabled")
			caster:RemoveModifierByName("modifier_okita_seigan_anim")
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		return end
		})
	end
end

function okita_seigan:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local ability = self
	local slashes = ability:GetSpecialValueFor("base_slashes")
	local damage = ability:GetSpecialValueFor("damage")*caster:GetAverageTrueAttackDamage(caster)
	if caster.IsTennenAcquired and caster:HasModifier("modifier_tennen_active") then
		damage = damage + ability:GetSpecialValueFor("damage_big_bonus")
	end
	local damage_big = ability:GetSpecialValueFor("damage_big")*caster:GetAverageTrueAttackDamage(caster)
	if caster.IsTennenAcquired and caster:HasModifier("modifier_tennen_active") then
		damage_big = damage_big + ability:GetSpecialValueFor("damage_big_bonus")
	end
	local modifier = caster:FindModifierByName("modifier_tennen_stacks")
	local stacks = modifier and modifier:GetStackCount() or 0
	for i=1, slashes + stacks do
		Timers:CreateTimer(0.01*i, function()
			DoDamage(caster, hTarget, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
            CreateSlashFx(caster, hTarget:GetAbsOrigin() + RandomVector(300), hTarget:GetAbsOrigin() + RandomVector(300))
            hTarget:EmitSound("Tsubame_Slash_" .. math.random(1,3))
		end)
	end
	DoDamage(caster, hTarget, damage_big, DAMAGE_TYPE_PHYSICAL, 0, self, false)
	hTarget:EmitSound("Tsubame_Focus")
end

modifier_okita_seigan_anim = class({})

function modifier_okita_seigan_anim:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_OVERRIDE_ANIMATION, 
                    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,}
    return func
end
function modifier_okita_seigan_anim:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_6
end
function modifier_okita_seigan_anim:GetOverrideAnimationRate()
    return 1.0
end
function modifier_okita_seigan_anim:IsHidden() return true end