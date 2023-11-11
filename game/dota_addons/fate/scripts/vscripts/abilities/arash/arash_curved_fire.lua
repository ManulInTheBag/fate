arash_curved_fire= class({})

function arash_curved_fire:CastFilterResultLocation(hLocation)
    local caster = self:GetCaster()
    if IsServer() and not IsInSameRealm(caster:GetAbsOrigin(), hLocation) then
        return UF_FAIL_CUSTOM
    elseif IsServer() and caster:FindModifierByName("modifier_arash_star_arrow") then
    	return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function arash_curved_fire:GetCustomCastErrorLocation(hLocation)
	local caster = self:GetCaster()
	if caster:FindModifierByName("modifier_arash_star_arrow") then
		return "#Star arrow active"
	end
    return "#Must be in same realm"
end

function arash_curved_fire:OnSpellStart()
    local caster = self:GetCaster()
    caster:EmitSound("Ability.Powershot.Alt")
    local point = self:GetCursorPosition()
    local castv = -(caster:GetAbsOrigin() - point):Normalized()
    local leftvec = Vector(-castv.y, castv.x, 0)
    local nDistance  = GetDistance(point, caster)
    local speed = self:GetSpecialValueFor("speed") --recalculating time to make sure all 3 arrows land together
    local fly_time = nDistance/speed
    if caster.ArashFallingStars then 
        self:ShootArrow(point  + 200*castv,fly_time, Vector(255,207,72),1, 1) -- root
        self:ShootArrow(point + castv * -100 +leftvec*192 ,fly_time, Vector(153,102,204), 1 ,2) -- lock
        self:ShootArrow(point + castv * -100 +leftvec*-192 ,fly_time, Vector(238,32,77), 1, 3) -- revoke

    else
        self:ShootArrow(point  + 200*castv,fly_time, Vector(255,255,255), 0, 4)
        self:ShootArrow(point + castv * -100 +leftvec*192 ,fly_time, Vector(255,255,255), 0, 4)
        self:ShootArrow(point + castv * -100 +leftvec*-192 ,fly_time, Vector(255,255,255), 0, 4)
    end

    caster:FindAbilityByName("arash_arrow_construction"):GetConstructionBuff()
end

function arash_curved_fire:ShootArrow(vPoint, fly_time, color, buffed, colortype)
    local hCaster = self:GetCaster()
    local nCastRange = self:GetSpecialValueFor("range")
    --if GetDistance(vPoint, hCaster) > nCastRange then
        --vPoint = hCaster:GetAbsOrigin() + GetDirection(vPoint, hCaster) * nCastRange
    --end
    local nTeamNumber = hCaster:GetTeamNumber()
    local vDirection = GetDirection(vPoint, hCaster)
    local nDistance  = GetDistance(vPoint, hCaster)
    local nRadius       = self:GetSpecialValueFor("radius")
    local nVisionRadius = self:GetSpecialValueFor("radius") 
    local nSpeed        = nDistance/fly_time
    local nDamage       = self:GetSpecialValueFor("damage")
    local nStunDuration = self:GetSpecialValueFor("duration")
    local vSpawnLoc = hCaster:GetAttachmentOrigin(hCaster:ScriptLookupAttachment("attach_attack1"))
    local sParticle = "particles/arash/arash_curved_fire_projectile.vpcf" 
    local nParticle =  ParticleManager:CreateParticle(sParticle, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleShouldCheckFoW(nParticle, false)
    ParticleManager:SetParticleAlwaysSimulate(nParticle)
    ParticleManager:SetParticleControl(nParticle, 0, vSpawnLoc)
    ParticleManager:SetParticleControl(nParticle, 1, GetGroundPosition(vPoint, nil))
    ParticleManager:SetParticleControl(nParticle, 2, Vector(nSpeed, 0, 0))
    ParticleManager:SetParticleControl(nParticle, 6, Vector(1, 0, 0))
    ParticleManager:SetParticleControl(nParticle, 15, color)

    local tSpearProjectile =    {
                                EffectName   = "",
                                Source       = hCaster,
                                vSpawnOrigin = vSpawnLoc,
                                Ability = self,
                                vVelocity     = vDirection  * nSpeed ,
                                fDistance = nDistance,
                                --fStartRadius = 100,
                                --fEndRadius   = 100,

                                fExpireTime = 0,

                                --iUnitTargetTeam  = nABILITY_TARGET_TEAM,
                                --iUnitTargetFlags = nABILITY_TARGET_TYPE,
                                --iUnitTargetType  = nABILITY_TARGET_FLAGS,

                                --bIgnoreSource   = false,
                                bHasFrontalCone = true,

                                bDrawsOnMinimap   = true,
                                bVisibleToEnemies = true,

                                bProvidesVision   = true,
                                iVisionRadius     = nVisionRadius,
                                iVisionTeamNumber = nTeamNumber,

                                ExtraData         = {
                                                    nParticle = nParticle,
                                                    nDamage        = nDamage,
                                                    nRadius        = nRadius,
                                                    colortype = colortype,
                                                    isBuffed = buffed
                                                            }
                                    }
       local nSpearProjectile = ProjectileManager:CreateLinearProjectile(tSpearProjectile)

       

end

function arash_curved_fire:Explosion(vLocation, damage, radius, colortype, mod)
    local hCaster = self:GetCaster()
    local hEntities = FindUnitsInRadius(
                                            hCaster:GetTeamNumber(),
                                            vLocation,
                                            nil,
                                            radius,
                                            DOTA_UNIT_TARGET_TEAM_ENEMY,
                                            DOTA_UNIT_TARGET_ALL,
                                            DOTA_UNIT_TARGET_FLAG_NONE,
                                            FIND_ANY_ORDER,
                                            false
                                        )
    for _, hEntity in pairs(hEntities) do
        if IsNotNull(hEntity) then
            DoDamage(hCaster, hEntity, damage, self:GetAbilityDamageType(), DOTA_DAMAGE_FLAG_NONE, self, false)
            if colortype == 1 then
                giveUnitDataDrivenModifier(hCaster,hEntity , "rooted", self:GetSpecialValueFor("duration") * mod)
            end
            if colortype == 2 then
                giveUnitDataDrivenModifier(hCaster,hEntity , "locked", self:GetSpecialValueFor("duration") * mod)
            end
            if colortype == 3 then
                giveUnitDataDrivenModifier(hCaster,hEntity , "revoked", self:GetSpecialValueFor("duration") * mod)
            end
        end
    end
    local nImpactPFX =  ParticleManager:CreateParticle("particles/arash/arash_curved_fire_projectile_explosion.vpcf", PATTACH_WORLDORIGIN, nil)
                        ParticleManager:SetParticleShouldCheckFoW(nImpactPFX, false)
                        ParticleManager:SetParticleControl(nImpactPFX, 0, GetGroundPosition(vLocation, nil))
                        ParticleManager:SetParticleControl(nImpactPFX, 1, Vector(radius, radius, radius))
                        ParticleManager:SetParticleControl(nImpactPFX, 6, Vector(1, 0, 0))
                        local color = Vector(0,0,0) + (colortype == 3 and Vector(238,32,77) or Vector(0,0,0)) + (colortype == 2 and Vector(255,207,72) or Vector(0,0,0))+ (colortype == 1 and Vector(153,102,204) or Vector(0,0,0))+ (colortype == 4 and Vector(255,255,255) or Vector(0,0,0))
                        ParticleManager:SetParticleControl(nImpactPFX, 15, color)
                        ParticleManager:ReleaseParticleIndex(nImpactPFX)

end

function arash_curved_fire:OnProjectileHit_ExtraData(hTarget, vLocation, tExtraData)
    if IsServer() then
        if type(tExtraData.nParticle) == "number" then
            ParticleManager:DestroyParticle(tExtraData.nParticle, false)
            ParticleManager:ReleaseParticleIndex(tExtraData.nParticle)
        end
       self:Explosion(vLocation, tExtraData.nDamage,tExtraData.nRadius, tExtraData.colortype, 0.5 )
       --- SA buff
       if tExtraData.isBuffed == 1 then

        local timedExplosionFx =  ParticleManager:CreateParticle("particles/arash/arash_curved_fire_explosion_attribute.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleShouldCheckFoW(timedExplosionFx, false)
        ParticleManager:SetParticleControl(timedExplosionFx, 0, GetGroundPosition(vLocation, nil))
        ParticleManager:SetParticleControl(timedExplosionFx, 2, Vector(4, 0, 0))
        ParticleManager:SetParticleControl(timedExplosionFx, 6, Vector(1, 0, 0))
        local colortype = tExtraData.colortype
        local color = Vector(0,0,0) + (colortype == 3 and Vector(238,32,77) or Vector(0,0,0)) + (colortype == 2 and Vector(255,207,72) or Vector(0,0,0))+ (colortype == 1 and Vector(153,102,204) or Vector(0,0,0))+ (colortype == 4 and Vector(255,255,255) or Vector(0,0,0))
        ParticleManager:SetParticleControl(timedExplosionFx, 15, color)
            Timers:CreateTimer(2,function()
                self:Explosion(vLocation+ Vector(0,0,80),  tExtraData.nDamage * 0.5, tExtraData.nRadius, tExtraData.colortype, 0.5)
                ParticleManager:DestroyParticle(timedExplosionFx, true)
                ParticleManager:ReleaseParticleIndex(timedExplosionFx)
            end)
       end
        
    end
end
