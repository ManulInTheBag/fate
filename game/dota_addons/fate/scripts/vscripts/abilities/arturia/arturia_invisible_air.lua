arturia_invisible_air = class({})
modifier_invisible_air_bonus_damage = class({})

LinkLuaModifier("modifier_invisible_air_bonus_damage", "abilities/arturia/arturia_invisible_air", LUA_MODIFIER_MOTION_NONE)

function arturia_invisible_air:OnSpellStart()
	local hCaster = self:GetCaster()

	local tProjectile = 
	{
		Ability = self,
        EffectName = "",
        iMoveSpeed = 1575,
        vSpawnOrigin = hCaster:GetOrigin(),
        fDistance = 525,
        fStartRadius = 175,
        fEndRadius = 175,
        Source = hCaster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 1.0,
		bDeleteOnHit = true,
		vVelocity = hCaster:GetForwardVector() * 1575
	}

	local nProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
	giveUnitDataDrivenModifier(hCaster, hCaster, "pause_sealenabled", 0.31)

	local phys = Physics:Unit(hCaster)
	hCaster:SetPhysicsFriction(0)
	hCaster:SetPhysicsVelocity(hCaster:GetForwardVector() * 1575)
	hCaster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

	local fBonusAttack = self:GetSpecialValueFor("bonus_attack")
	if hCaster.IsChivalryAcquired then
		fBonusAttack = fBonusAttack + 100
	end

	hCaster:AddNewModifier(hCaster, self, "modifier_invisible_air_bonus_damage", { Duration = 2.0,
																				   BonusDamage = fBonusAttack })

	Timers:CreateTimer("saber_dash", {
		endTime = 0.31,
		callback = function()
		hCaster:OnPreBounce(nil)
		hCaster:SetBounceMultiplier(0)
		hCaster:PreventDI(false)
		hCaster:SetPhysicsVelocity(Vector(0,0,0))
		hCaster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(hCaster, hCaster:GetAbsOrigin(), true)
	return end
	})

	hCaster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("saber_dash")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		hCaster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end)
end

function arturia_invisible_air:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local hCaster = self:GetCaster()
	local fDamage = self:GetSpecialValueFor("damage")

	DoDamage(hCaster, hTarget, fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)

	Timers:RemoveTimer("saber_dash")
	hCaster:OnPreBounce(nil)
	hCaster:SetBounceMultiplier(0)
	hCaster:PreventDI(false)
	hCaster:SetPhysicsVelocity(Vector(0,0,0))
	hCaster:RemoveModifierByName("pause_sealenabled")
	FindClearSpaceForUnit(hCaster, hCaster:GetAbsOrigin(), true)

	if hCaster.IsChivalryAcquired then
		hTarget:AddNewModifier(hCaster, self, "modifier_stunned", { Duration = 1.0 })
	end
end

function modifier_invisible_air_bonus_damage:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			 --MODIFIER_EVENT_ON_ATTACK_LANDED
			  }
end

if IsServer() then
	function modifier_invisible_air_bonus_damage:OnCreated(args)
		self.BonusDamage = args.BonusDamage
		CustomNetTables:SetTableValue("sync","invis_air", { bonus_damage = self.BonusDamage })
	end

	function modifier_invisible_air_bonus_damage:OnAttackLanded(args)
		if args.attacker == self:GetParent() then
			self:Destroy()
		end
	end
end

function modifier_invisible_air_bonus_damage:GetModifierPreAttack_BonusDamage()
	if IsServer() then
		return self.BonusDamage
	elseif IsClient() then
		local bonus_damage = CustomNetTables:GetTableValue("sync","invis_air").bonus_damage
        return bonus_damage 
	end
end

function modifier_invisible_air_bonus_damage:IsHidden()
	return true
end