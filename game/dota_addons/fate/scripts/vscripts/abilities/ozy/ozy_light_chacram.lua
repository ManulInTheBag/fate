ozy_light_chacram = class({})

function ozy_light_chacram:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

    if target == caster:GetAbsOrigin() then
        target = caster:GetAbsOrigin() + caster:GetForwardVector()*100
    end
    local vector = (target - caster:GetAbsOrigin()):Normalized()
    vector.z = 0
    local speed = 1800
	local tProjectile = {
        EffectName = "particles/ozy/ozy_chacram.vpcf" ,
        Ability = self,
        vSpawnOrigin = caster:GetAbsOrigin() + Vector(0,0,120),
        vVelocity = vector * speed,
        fDistance = 1100,
        fStartRadius = 128,
        fEndRadius = 128,
        Source = self:GetCaster(),
        bHasFrontalCone = false,
        bReplaceExisting = false,
        bDeleteOnHit = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = 0,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        flExpireTime = GameRules:GetGameTime() + 0.1,
        --iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
    }

 
    caster.cScrollProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)

end

---Linear version
function ozy_light_chacram:OnProjectileHit(target, location, tData )
    if target == nil then
        return false
    end
    if (target:GetName() == "npc_dota_ward_base") then
        return false
    end
    if target:HasModifier("modifier_protection_from_arrows_active") then return end
    local hModifier = nil

    local caster = self:GetCaster()
    if IsSpellBlocked(target, caster) then return true end
    DoDamage(caster, target, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
    target:EmitSound("Hero_EmberSpirit.FireRemnant.Explode")
    if not target:IsMagicImmune() then
       giveUnitDataDrivenModifier(caster, target, "locked", self:GetSpecialValueFor("duration"))
    end
    Timers:CreateTimer(0.033,function()
        ProjectileManager:DestroyLinearProjectile(caster.cScrollProjectile )
    end)

    return true
end
