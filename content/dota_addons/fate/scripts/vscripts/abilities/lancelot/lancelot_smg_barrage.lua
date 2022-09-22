lancelot_smg_barrage = class({})

LinkLuaModifier("modifier_barrage_upkeep", "abilities/lancelot/modifiers/modifier_barrage_upkeep", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_barrage_debuff", "abilities/lancelot/modifiers/modifier_barrage_debuff", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eternal_flame_shred", "abilities/lancelot/modifiers/modifier_eternal_flame_shred", LUA_MODIFIER_MOTION_NONE)

function lancelot_smg_barrage:GetCastPoint()
    return 0.3
end

function lancelot_smg_barrage:GetCooldown(iLevel)
    return 0
end

function lancelot_smg_barrage:GetManaCost(iLevel)
	local caster = self:GetCaster()
	local charge = 0
	if caster:HasModifier("modifier_barrage_upkeep") then
		charge = caster:GetModifierStackCount("modifier_barrage_upkeep", caster)
	end

	return 100 + (charge * 30)
end


function lancelot_smg_barrage:CastFilterResultLocation(vLocation)
	local caster = self:GetCaster()

	--if caster:HasModifier("modifier_arondite") then
	--	return UF_FAIL_CUSTOM
	--end

	return UF_SUCCESS
end

function lancelot_smg_barrage:GetCustomCastErrorLocation(vLocation)
	return "#Arondite_Active"
end

function lancelot_smg_barrage:OnSpellStart()
	local caster = self:GetCaster()
    --PrintTable(caster)
	local ability = self
    local frontward = caster:GetForwardVector()
    local range = self:GetSpecialValueFor("range")
    local start_radius = self:GetSpecialValueFor("start_radius")
    local end_radius = self:GetSpecialValueFor("end_radius")

    local smg = 
    {
        Ability = self,
        --EffectName = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf",
        iMoveSpeed = 2000,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = range,
        fStartRadius = start_radius,
        fEndRadius = end_radius,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
        bDeleteOnHit = false,
        vVelocity = caster:GetForwardVector() * 2000
    }
   
    ProjectileManager:CreateLinearProjectile(smg)

    caster:EmitSound("Heckler_Koch_MP5_Unsuppressed")
    caster:AddNewModifier(caster, self, "modifier_barrage_upkeep", { Duration = 2})    
    
    -- Initialize local variables
    local current_point = caster:GetAbsOrigin()
    local currentForwardVec = caster:GetForwardVector()
    local current_radius = start_radius
    local current_distance = 0
    local forwardVec = (self:GetCursorPosition() - current_point ):Normalized()
    local end_point = current_point + range * forwardVec
    local difference = end_radius - start_radius
    
    -- Loop creating particles
    while current_distance < range do
        -- Create particle
        local particleIndex = ParticleManager:CreateParticle( "particles/custom/lancelot/lancelot_smg.vpcf", PATTACH_CUSTOMORIGIN, caster )
        ParticleManager:SetParticleControl( particleIndex, 0, current_point )
        ParticleManager:SetParticleControl( particleIndex, 1, Vector(current_radius, 0, 0 ) )
        
        Timers:CreateTimer( 1.0, function()
            ParticleManager:DestroyParticle( particleIndex, false )
            ParticleManager:ReleaseParticleIndex( particleIndex )
            return nil
        end)
        
        -- Update current point
        current_point = current_point + current_radius * forwardVec
        current_distance = current_distance + current_radius
        current_radius = start_radius + current_distance / range * difference
    end
    
    -- Create particle
    local particleIndex = ParticleManager:CreateParticle( "particles/custom/lancelot/lancelot_smg.vpcf", PATTACH_CUSTOMORIGIN, caster )
    ParticleManager:SetParticleControl( particleIndex, 0, end_point )
    ParticleManager:SetParticleControl( particleIndex, 1, Vector( end_radius, 0, 0 ) )
        
    Timers:CreateTimer( 1.0, function()
        ParticleManager:DestroyParticle( particleIndex, true )
        ParticleManager:ReleaseParticleIndex( particleIndex )
        return nil
    end)

    self:CheckCombo()
end

function lancelot_smg_barrage:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

    --print("hit", hTarget)
	local hCaster = self:GetCaster()
    local damage_bonus = hCaster:GetAverageTrueAttackDamage(hCaster)
	local damage = self:GetSpecialValueFor("damage") + damage_bonus*0.3
	local stacks = 0

	if hTarget:HasModifier("modifier_barrage_debuff") then
		stacks = hTarget:GetModifierStackCount("modifier_barrage_debuff", hCaster)
		damage = damage + (stacks * (self:GetSpecialValueFor("stack_damage")+0.1*damage_bonus))
	end

    if hCaster:HasModifier("modifier_eternal_flame_attribute") then
        hTarget:AddNewModifier(hCaster, self, "modifier_eternal_flame_shred", { Duration = 5 })
    end
	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
	hTarget:AddNewModifier(hCaster, self, "modifier_barrage_debuff", { Duration = 5 })
end

function lancelot_smg_barrage:CheckCombo()
    local caster = self:GetCaster()
    if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 and not caster:HasModifier("modifier_arondite") then
        if caster:HasModifier("modifier_double_edge") and caster:FindAbilityByName("lancelot_f16"):IsCooldownReady() and caster.nukeAvail ~= true then            
            local abilname = "fate_empty1"
            if caster:FindAbilityByName("lancelot_blessing_of_fairy") then abilname = "lancelot_blessing_of_fairy" end
            caster:SwapAbilities("lancelot_f16", abilname, true, false)
            caster.nukeAvail = true
            local newTime =  GameRules:GetGameTime()
            Timers:CreateTimer({
                endTime = 8,
                callback = function()
                if caster:FindAbilityByName("lancelot_blessing_of_fairy") then abilname = "lancelot_blessing_of_fairy" end
                caster:SwapAbilities("lancelot_f16", abilname, false, true)                
                caster.nukeAvail = false
            end
            })        
        end
    end
end