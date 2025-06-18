cu_chulain_rune_of_frost = class({})

function cu_chulain_rune_of_frost:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=0.2, activity=ACT_DOTA_ICE_VORTEX, rate=2.0})
	self.sound = "cu_rune_of_frost_cast_"..math.random(1,2)
	caster:EmitSound(self.sound) 
end

function cu_chulain_rune_of_frost:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
	caster:StopSound(self.sound) 
end
function cu_chulain_rune_of_frost:GetManaCost(iLevel)
	if self:GetCaster():HasModifier("modifier_celtic_rune_attribute") then
		return 0
	else
		return 150
	end
end

function cu_chulain_rune_of_frost:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_celtic_rune_attribute") then
		cooldown = cooldown - (cooldown * 0.75)
	end

	return cooldown
end

function cu_chulain_rune_of_frost:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local vector = (self:GetCursorPosition() - caster:GetAbsOrigin()):Normalized()
	vector.z = 0
	local speed = self:GetSpecialValueFor("range") * 2
	--giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.2)
	local blastFx = ParticleManager:CreateParticle("particles/cu_chulain/cu_rune_of_frost.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( blastFx, 0, caster:GetAbsOrigin() + caster:GetForwardVector() * 25)
	ParticleManager:SetParticleControl( blastFx, 1, speed * vector)
	ParticleManager:SetParticleControl( blastFx, 2,Vector(self:GetSpecialValueFor("radius"),self:GetSpecialValueFor("radius"),self:GetSpecialValueFor("radius")))
	ParticleManager:ReleaseParticleIndex(blastFx)
	local soundRandom = RandomFloat(0, 1)
	if soundRandom > 0.5 then
		caster:EmitSound("cu_rune_of_frost") 
	end

	local qdProjectile = 
	{
		Ability = ability,
        EffectName = "",
        iMoveSpeed = speed,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = self:GetSpecialValueFor("range")-200,
        fStartRadius =  self:GetSpecialValueFor("radius"),
        fEndRadius =  self:GetSpecialValueFor("radius"),
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = false,
		vVelocity = vector * speed
	}


	caster:SetForwardVector(vector)
	local projectile = ProjectileManager:CreateLinearProjectile(qdProjectile)

	if not caster:HasModifier("modifier_celtic_rune_attribute") then
		local ability = caster:FindAbilityByName("cu_chulain_rune_magic")
		ability:CloseSpellbook(self:GetCooldown(self:GetLevel()))		
	end

	
end

function cu_chulain_rune_of_frost:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local duration = self:GetSpecialValueFor("slow_duration")

	--giveUnitDataDrivenModifier(caster, hTarget, "rooted", duration)
	--giveUnitDataDrivenModifier(caster, hTarget, "locked", duration)

	--hTarget:EmitSound("Hero_Sniper.AssassinateDamage")
	DoDamage(caster, hTarget, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	hTarget:AddNewModifier(caster, self,"modifier_cu_frost_slow", {duration = self:GetSpecialValueFor("slow_duration")})

end

LinkLuaModifier("modifier_cu_frost_slow", "abilities/cu_chulain/cu_chulain_rune_of_frost", LUA_MODIFIER_MOTION_NONE)


 
modifier_cu_frost_slow = class({})

function modifier_cu_frost_slow:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}

	return funcs
end

function modifier_cu_frost_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_power")
end

function modifier_cu_frost_slow:IsHidden()
	return false 
end
function modifier_cu_frost_slow:IsDebuff()
	return true
end
