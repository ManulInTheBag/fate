karna_recast_dash = class({})
LinkLuaModifier("modifier_karna_self_pause","abilities/karna/karna_new_abilities/karna_spin", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_karna_self_pause_2","abilities/karna/karna_new_abilities/karna_spin", LUA_MODIFIER_MOTION_NONE)
 


function karna_recast_dash:OnSpellStart()
	
	local caster = self:GetCaster()
	self.bArmorRestore = false
	self.bArmorActive = caster:FindModifierByName("modifier_karna_buff_melee")
	self.armor_modifier = caster:FindModifierByName("modifier_karna_armor") 
	StartAnimation(caster, {duration=0.5, activity=ACT_DOTA_CAST_ABILITY_2_END, rate=1.1})
	local ability = self
	caster:FindAbilityByName("karna_spin_2"):StartCooldown(1)
	caster:EmitSound("karna_new_karna_too_slow")
	local vector = (self:GetCursorPosition() - caster:GetAbsOrigin()):Normalized()
	local proj = 
	{
		Ability = ability,
        EffectName = "",
        iMoveSpeed = 1200,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = 600,
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
		vVelocity = vector * 1200
	}
	--self.rushfx = ParticleManager:CreateParticle("particles/karna/karna_dash_cone.vpcf", PATTACH_ABSORIGIN_FOLLOW  , caster )
	--ParticleManager:SetParticleControl(self.rushfx, 0, caster:GetAbsOrigin())
	vector.z = 0
	caster:SetForwardVector(vector)
	local projectile = ProjectileManager:CreateLinearProjectile(proj)
	caster:AddNewModifier(caster, self, "modifier_karna_self_pause_2", {Duration = 0.5}) 
	--giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.5)
	caster:EmitSound("Hero_PhantomLancer.Doppelwalk") 
	local sin = Physics:Unit(caster)
	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(vector * 1200)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

	Timers:CreateTimer("karna_dash", {
		endTime = 0.5,
		callback = function()
		caster:OnPreBounce(nil)
		caster:SetBounceMultiplier(0)
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
 
	return end
	})

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		Timers:RemoveTimer("karna_dash")
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		ProjectileManager:DestroyLinearProjectile(projectile)
		caster:RemoveModifierByName("pause_sealenabled")
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
 
	end)
end

function karna_recast_dash:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local buff_ability = caster:FindAbilityByName("karna_buff_melee")
	local bMartialArts = caster.ManaBurstAttribute
	--giveUnitDataDrivenModifier(caster, hTarget, "rooted", duration)
	--giveUnitDataDrivenModifier(caster, hTarget, "locked", duration)

	hTarget:EmitSound("Hero_Sniper.AssassinateDamage")
	if not self.bArmorRestore and  self.bArmorActive ~= nil then 
		self.armor_modifier:RestoreArmorPercentage(self:GetSpecialValueFor("armor_restore_percentage"))
		self.bArmorRestore = true
	end
	DoDamage(caster, hTarget, damage, self:GetAbilityDamageType(), 0, self, false)
	if bMartialArts then 
		if hTarget:HasModifier("modifier_karna_ucm_sa_stacking") then
			local stacks = hTarget:GetModifierStackCount("modifier_karna_ucm_sa_stacking", caster)
			if stacks == 4 then 
				DoDamage(caster, hTarget, caster:GetIntellect() * 1.5, self:GetAbilityDamageType(), 0, self, false)
				giveUnitDataDrivenModifier(caster, hTarget, "stunned",  0.5)
				hTarget:RemoveModifierByName("modifier_karna_ucm_sa_stacking")
			else
				hTarget:AddNewModifier(caster, self, "modifier_karna_ucm_sa_stacking", { Duration = 2})	
				hTarget:FindModifierByName("modifier_karna_ucm_sa_stacking"):SetStackCount(stacks + 1)
			end
		else
			hTarget:AddNewModifier(caster, self, "modifier_karna_ucm_sa_stacking", { Duration = 2})	
			hTarget:FindModifierByName("modifier_karna_ucm_sa_stacking"):SetStackCount(1)
		end
	end
	ApplyAirborne(caster, hTarget, 0.5)--self:GetAbility():GetSpecialValueFor("airborne_duration"))
	if caster:HasModifier("modifier_karna_buff_melee") then
		buff_ability:ApplyBurnStacks(hTarget)
	end

end