familiar_attack = class({})

function familiar_attack:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
    local hero = caster:GetPlayerOwner():GetAssignedHero()
    if target == caster:GetAbsOrigin() then
        target = caster:GetAbsOrigin() + caster:GetForwardVector()*100
    end
    local vector = (target - caster:GetAbsOrigin()):Normalized()
    vector.z = 0
    local speed = 1800
	hero.ServStat:useC()

	local tProjectile = {
        EffectName = "particles/zlodemon/c_scroll.vpcf" ,
        Ability = self,
        vSpawnOrigin = caster:GetAbsOrigin() + Vector(0,0,120),
        vVelocity = vector * speed,
        fDistance = 1100,
        fStartRadius = 128,
        fEndRadius = 128,
        Source = hero,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        bDeleteOnHit = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = 0,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        flExpireTime = GameRules:GetGameTime() + 0.1,
        --iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
    }
    local id = 0
    if not _G.projfix then
    	--id = FATE_ProjectileManager:CreateTrackingProjectile(tProjectile)
        caster.cScrollProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
    else
    	caster.cScrollProjectile  = ProjectileManager:CreateLinearProjectile(tProjectile)
    end
    self:SetRefCountsModifiers(true)
    caster:AddNewModifier(caster, self, "modifier_item_c_scroll_fix_cringe", {duration = 20})


end

---Linear version
function familiar_attack:OnProjectileHit(target, location, tData )
    if target == nil then
        return false
    end
    if (target:GetName() == "npc_dota_ward_base") then
        return false
    end
    if target:HasModifier("modifier_protection_from_arrows_active") then return end
    local hModifier = nil

    local caster = self:GetCaster()
    if IsSpellBlocked(target) then return true end
    DoDamage(caster, target, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
    target:EmitSound("Hero_EmberSpirit.FireRemnant.Explode")
    if not target:IsMagicImmune() then
        hModifier = target:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
    end
    Timers:CreateTimer(0.033,function()
        ProjectileManager:DestroyLinearProjectile(caster.cScrollProjectile )
    end)

    return true
end

---Target version (ya tut nasral maleha)
-- function item_c_scroll:OnProjectileHit(hTarget, vLocation, tData)
--     if hTarget == nil then
--         return 
--     end

--     local hModifier = nil

--     local caster = self:GetCaster()
-- 	local target = hTarget

-- 	if IsSpellBlocked(target) then return end
-- 	DoDamage(caster, target, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
-- 	target:EmitSound("Hero_EmberSpirit.FireRemnant.Explode")
-- 	if not target:IsMagicImmune() then
-- 		hModifier = target:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
-- 	end
    
-- end

LinkLuaModifier("modifier_item_c_scroll_fix_cringe", "items/c_scroll", LUA_MODIFIER_MOTION_NONE)

modifier_item_c_scroll_fix_cringe = modifier_item_c_scroll_fix_cringe or class({})

function modifier_item_c_scroll_fix_cringe:IsHidden() return true end
function modifier_item_c_scroll_fix_cringe:RemoveOnDeath() return true end
function modifier_item_c_scroll_fix_cringe:IsPurgable() return false end
function modifier_item_c_scroll_fix_cringe:IsPurgeException() return false end