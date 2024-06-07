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

    self:SpendCharge()
	if self:GetCurrentCharges() < 1 then
		caster:TakeItem(self)
	end
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
		hModifier = target:AddNewModifier(self, caster, "modifier_stunned", {Duration = self:GetSpecialValueFor("stun_duration")})
	end

	if self:GetCurrentCharges() < 1 then
		Timers:CreateTimer(tostring(self:entindex()),
		{
        	--useOldStyle = true,
         	endTime = 0,
         	callback = function()
            	if IsNotNull(self) then
					if not IsNotNull(hModifier)
						or hModifier:GetAbility() ~= self then
						UTIL_Remove(self)
					end
					return 0.01
             	end
        	end
     	})
	end
end