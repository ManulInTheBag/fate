item_c_scroll = class({})

function item_c_scroll:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	caster.ServStat:useC()

	local tProjectile = {
        Target = target,
        Source = caster,
        Ability = self,
        level = 3,
        EffectName = "particles/units/heroes/hero_lina/lina_base_attack.vpcf",
        iMoveSpeed = 1200,
        vSourceLoc = caster:GetAbsOrigin(),
        bDodgeable = true,
        bIsAttack = true,
        flExpireTime = GameRules:GetGameTime() + 10,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2,
    }
    local id = 0
    if not _G.projfix then
    	id = FATE_ProjectileManager:CreateTrackingProjectile(tProjectile)
    else
    	ProjectileManager:CreateTrackingProjectile(tProjectile)
    end

    self:SetRefCountsModifiers(true)
    caster:AddNewModifier(caster, self, "modifier_item_c_scroll_fix_cringe", {duration = 20})
    self:SpendCharge(1)
end

function item_c_scroll:OnProjectileHit(hTarget, vLocation, tData)
    if hTarget == nil then
        return 
    end

    local hModifier = nil

    local caster = self:GetCaster()
	local target = hTarget

	if IsSpellBlocked(target) then return end
	DoDamage(caster, target, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
	target:EmitSound("Hero_EmberSpirit.FireRemnant.Explode")
	if not target:IsMagicImmune() then
		hModifier = target:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
	end
end

LinkLuaModifier("modifier_item_c_scroll_fix_cringe", "items/c_scroll", LUA_MODIFIER_MOTION_NONE)

modifier_item_c_scroll_fix_cringe = modifier_item_c_scroll_fix_cringe or class({})

function modifier_item_c_scroll_fix_cringe:IsHidden() return true end
function modifier_item_c_scroll_fix_cringe:RemoveOnDeath() return true end
function modifier_item_c_scroll_fix_cringe:IsPurgable() return false end
function modifier_item_c_scroll_fix_cringe:IsPurgeException() return false end