nobu_shot = class({})

LinkLuaModifier("modifier_nobu_slow","abilities/nobu/nobu_shot", LUA_MODIFIER_MOTION_NONE)

function nobu_shot:CastFilterResultLocation(vLocation)
    local caster = self:GetCaster()
    if    IsServer()  and caster:FindModifierByName("modifier_nobu_turnlock") then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function nobu_shot:GetCustomCastErrorLocation()
	return "Can not be used while shooting"
end

function nobu_shot:OnSpellStart()
    local hCaster = self:GetCaster()
    local aoe = 32
    local position = self:GetCursorPosition()
    local origin = hCaster:GetAttachmentOrigin(3) 
    hCaster:EmitSound("nobu_shoot")
 
    local facing = ForwardVForPointGround(hCaster,position)
    Timers:CreateTimer(0.1, function()
        self:Shoot({
            Origin = origin,
            Speed = 10000,
            Facing = facing,
            AoE = aoe,
            Range = 1000,
        } )
    
    
    
    end)
    
   
end

function nobu_shot:Shoot(keys)
    local projectileTable = {
        EffectName = "particles/nobu/nobu_bullet.vpcf" ,
        Ability = self,
        vSpawnOrigin = keys.Origin,
        vVelocity = keys.Facing * keys.Speed,
        fDistance = keys.Range,
        fStartRadius = keys.AoE,
        fEndRadius = keys.AoE,
        Source = self:GetCaster(),
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        flExpireTime = GameRules:GetGameTime() + 0.33,
        
    }
    ProjectileManager:CreateLinearProjectile(projectileTable)
end

 
function nobu_shot:OnProjectileHit(target, location )
    if target == nil then
        return
    end
    local hCaster = self:GetCaster()
    local damage = hCaster:FindAbilityByName("nobu_guns"):GetGunsDamage() * self:GetSpecialValueFor("damage_mod")
    if IsDivineServant(target) and hCaster.UnifyingAcquired then 
        damage= damage*1.2
    end
    DoDamage(hCaster, target, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
    target:EmitSound("nobu_shot_impact_"..math.random(1,2))
    target:AddNewModifier(hCaster, self, "modifier_nobu_slow", {Duration = self:GetSpecialValueFor("duration")})    
    if(hCaster.ISDOW) then
        local gun_spawn = hCaster:GetAbsOrigin()
        local random1 = RandomInt(25, 150) -- position of gun spawn
		local random2 = RandomInt(0,1) -- whether weapon will spawn on left or right side of hero
		local random3 = RandomInt(80,200)*Vector(0,0,1) 
        

		if random2 == 0 then 
			gun_spawn = gun_spawn +  hCaster:GetRightVector() * -1 * random1 + random3
		else 
			gun_spawn = gun_spawn + hCaster:GetRightVector() * random1 + random3
        end
        local aoe = 32
        
        hCaster:FindAbilityByName("nobu_guns"):DOWShoot({
            Speed = 10000,
            AoE = aoe,
            Range = 1000,
        },  gun_spawn )
    end
    return true 
end



modifier_nobu_slow = class({})

function modifier_nobu_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_nobu_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_power")
end

function modifier_nobu_slow:IsHidden()
	return false 
end