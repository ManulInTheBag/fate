arash_independent_action = class({})
LinkLuaModifier("modifier_arash_mobility_boost", "abilities/arash/arash_independent_action", LUA_MODIFIER_MOTION_NONE)


function arash_independent_action:OnSpellStart()
    local caster = self:GetCaster()
    self.RushPoint = self:GetCursorPosition()
    local ability = self
    local speed = self:GetSpecialValueFor("speed")      
    local max_range = self:GetSpecialValueFor("range")  
    self.move_vector = (self.RushPoint - caster:GetAbsOrigin()):Normalized()
	self.rushfx = ParticleManager:CreateParticle("particles/arash/arash_rush_self.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
	local castfx = ParticleManager:CreateParticle("particles/arash/arash_rush_start.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
    ParticleManager:SetParticleControl(castfx, 0, caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(castfx)
    local castfx2 = ParticleManager:CreateParticle("particles/arash/arash_rush_start_2.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
    ParticleManager:SetParticleControlTransformForward(castfx2, 1, caster:GetAbsOrigin(),self.move_vector)
	ParticleManager:ReleaseParticleIndex(castfx2)
    caster:FindAbilityByName("arash_arrow_construction"):GetConstructionBuff()
	local rush_time = max_range/speed
    StartAnimation(caster, {duration=rush_time, activity=ACT_DOTA_CAST_ABILITY_3_END, rate=1.0})
    caster:EmitSound("arash_dash")
    local dashProjectile = 
    {
        Ability = ability,
        EffectName = "",
        iMoveSpeed = speed,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = max_range,
        fStartRadius = 150,
        fEndRadius = 150,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
        bDeleteOnHit = true,
        vVelocity = self.move_vector * speed
    }
     
    
    local projectile = ProjectileManager:CreateLinearProjectile(dashProjectile)
    giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", rush_time)
    local sin = Physics:Unit(caster)
    caster:SetPhysicsFriction(0)
    caster:SetPhysicsVelocity(self.move_vector * speed)
    caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
      caster:SetGroundBehavior (PHYSICS_GROUND_LOCK)

      
   

    Timers:CreateTimer("arash_rush", {
        endTime = rush_time,
        callback = function()
        caster:OnPreBounce(nil)
        caster:SetBounceMultiplier(0)
        caster:PreventDI(false)
        caster:SetPhysicsVelocity(Vector(0,0,0))
        caster:RemoveModifierByName("pause_sealenabled")
        
        caster:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
        ParticleManager:DestroyParticle(  self.rushfx , true)
        ParticleManager:ReleaseParticleIndex(  self.rushfx )
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
    return end
    })

    caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
        Timers:RemoveTimer("arash_rush")
        caster:RemoveModifierByName("pause_sealenabled")
        self:StopPhysics(unit)
        ParticleManager:DestroyParticle(  self.rushfx , true)
        ParticleManager:ReleaseParticleIndex(  self.rushfx )
        FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
        ProjectileManager:DestroyLinearProjectile(projectile)
    end)

 

end

function arash_independent_action:StopPhysics(unit)
	unit:OnPreBounce(nil)
	unit:SetBounceMultiplier(0)
	unit:PreventDI(false)
	unit:SetPhysicsVelocity(Vector(0,0,0))
	unit:SetGroundBehavior (PHYSICS_GROUND_NOTHING)
    ParticleManager:DestroyParticle(  self.rushfx , true)
    ParticleManager:ReleaseParticleIndex(  self.rushfx )
end

function arash_independent_action:SecondAttack(unit, vLocation)
    local caster = self:GetCaster()
    self:StopPhysics(caster)
    local knockback1 = { should_stun = true,
		knockback_duration = 0.5,
		duration = 0.5,
		knockback_distance = self:GetSpecialValueFor("jump_back_distance"),
		knockback_height = 150,
		center_x = unit:GetAbsOrigin().x,
		center_y = unit:GetAbsOrigin().y,
		center_z = unit:GetAbsOrigin().z }
	caster:RemoveModifierByName("modifier_knockback")
	caster:AddNewModifier(caster, self, "modifier_knockback", knockback1)
    StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_END, rate=2.0})
    Timers:CreateTimer(0.2, function()
        if IsNotNull(unit) then
            if unit:IsAlive() then
    
                local projectile = {
                    Target = unit,
                    Ability = caster:FindAbilityByName("arash_mobility_boost_active"), -- да я насрал но мне лень делать иначе)
                    EffectName = "particles/arash/arash_base_attack.vpcf",
                    iMoveSpeed = 900,
                    level = 3,
                    vSpawnOrigin = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1")),
                    bDodgeable = true,
                    Source = caster,  
                    bDeleteOnHit = true,
                    bReplaceExisting = false,
                    flExpireTime = GameRules:GetGameTime() + 1,
                  
                }
                FATE_ProjectileManager:CreateTrackingProjectile(projectile)
            end
    
        end
    end)
    

end


function arash_independent_action:OnProjectileHit_ExtraData(hTarget, vLocation, table)
    if hTarget == nil then return end
    local caster = self:GetCaster()
    local damage = self:GetSpecialValueFor("damage")
    hTarget:EmitSound("Hero_Sniper.AssassinateDamage")
	self:StopPhysics(caster)
    giveUnitDataDrivenModifier(caster,  hTarget, "stunned", 1)
    DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
    Timers:RemoveTimer("arash_rush")
    if caster.ArashMobilityBoost then 
        caster:AddNewModifier(caster, self, "modifier_arash_mobility_boost", {duration =  caster.MasterUnit2:FindAbilityByName("arash_mobility_boost"):GetSpecialValueFor("recast_duration") or 0})
    end
    local sin = Physics:Unit( hTarget)
    hTarget:SetPhysicsFriction(0)
    hTarget:SetPhysicsVelocity(self.move_vector* 600)
    hTarget:SetNavCollisionType(PHYSICS_NAV_BOUNCE)
    Timers:CreateTimer("arash_pushback", {
        endTime = 0.4,
        callback = function()
            self:StopPhysics(hTarget)
            FindClearSpaceForUnit(target,  hTarget:GetAbsOrigin(), true)
        return
    end})
    hTarget:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
        Timers:RemoveTimer("arash_pushback")
        unit:EmitSound("muramasa_throw_impact")
        self:StopPhysics(hTarget)
        local impact_fx = ParticleManager:CreateParticle("particles/muramasa/muramasa_throw_impact.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(impact_fx, 0, hTarget:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(impact_fx)
        FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
      
    end)
    self:SecondAttack(hTarget,vLocation)
    return true
end
 

modifier_arash_mobility_boost = class({})

function modifier_arash_mobility_boost:OnDestroy()
    if not IsServer() then return end
    if self.caster:GetAbilityByIndex(2):GetName() == "arash_mobility_boost_active" then
        self.caster:SwapAbilities("arash_independent_action", "arash_mobility_boost_active", true, false)
    end
    
end


function modifier_arash_mobility_boost:OnCreated()
    self.caster = self:GetCaster()
    if not IsServer() then return end
    if self.caster:GetAbilityByIndex(2):GetName() == "arash_independent_action" then
        self.caster:SwapAbilities("arash_independent_action", "arash_mobility_boost_active", false, true)
    end
end


function modifier_arash_mobility_boost:IsDebuff()                                                             return false end
function modifier_arash_mobility_boost:IsPurgable()                                                           return false end
function modifier_arash_mobility_boost:IsPurgeException()                                                     return false end
function modifier_arash_mobility_boost:RemoveOnDeath()                                                        return true end
function modifier_arash_mobility_boost:IsHidden()															  return false end