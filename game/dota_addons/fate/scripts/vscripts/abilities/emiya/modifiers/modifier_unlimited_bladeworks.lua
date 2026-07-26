modifier_unlimited_bladeworks = class({})

function modifier_unlimited_bladeworks:OnDestroy()
	if IsServer() then
		-- на смерти/зачистке раунда хэндлы родителя и способности могут быть уже мертвы
		local parent = self:GetParent()
		if not IsNotNull(parent) then return end
		if not parent.IsUBWActive then return end
		-- сброс флага делает сам EndUBW: он же гасит повторный вызов из OnOwnerDied

		local ability = self:GetAbility()
		if not IsNotNull(ability) then return end
		ability:EndUBW()
	end
end
 

 
function modifier_unlimited_bladeworks:OnAttackFinished(args)
	if not IsServer() then return end
    if args.attacker ~= self:GetParent() then return end
	if(args.target == nil) then return end
	local target = args.target
	local caster = self:GetCaster()
	local vCasterOrigin = caster:GetAbsOrigin()
	local vForwardVector =  caster:GetForwardVector()
	vOrigin = vCasterOrigin + vForwardVector*-50  + Vector(0,0,350)   
	local leftvec = Vector(-vForwardVector.y, vForwardVector.x, 0)
	local random2 = RandomInt(0,1) -- whether weapon will spawn on left or right side of hero
		if random2 == 0 then 
			vOrigin = vOrigin + leftvec * RandomInt(100,500)
		else 
			vOrigin = vOrigin -leftvec * RandomInt(100,500)
		end
		self.info = {
			Target = target,
			vSourceLoc = vOrigin + vForwardVector * -RandomInt(200,700), 
			Ability = self:GetAbility(),
			bHasFrontalCone = false,
			bReplaceExisting = false,
			bIsAttack = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			iUnitTargetType = DOTA_UNIT_TARGET_OTHER + DOTA_UNIT_TARGET_ALL,
			EffectName = "particles/emiya/emiya_attack_projectile.vpcf",
			iMoveSpeed = 3500,
			fExpireTime = GameRules:GetGameTime() + 0.5,
			bDeleteOnHit = true,
			ExtraData = {
			  targetIndex = target:entindex(),
	  
			  }
		  }   
	FATE_ProjectileManager:CreateTrackingProjectile(self.info) 
end
 

function modifier_unlimited_bladeworks:OnCreated()
	if IsServer() then
		self:GetParent():Heal(self:GetAbility():GetSpecialValueFor("bonus_health") + (self:GetParent():HasModifier("modifier_shroud_of_martin") and self:GetParent():GetIntellect()*0 or 0), self:GetParent())
	end
end

function modifier_unlimited_bladeworks:DeclareFunctions()
	return { --MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, 
			 --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			 --MODIFIER_PROPERTY_HEALTH_BONUS, MODIFIER_EVENT_ON_ATTACK_FINISHED}
}
end

function modifier_unlimited_bladeworks:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_unlimited_bladeworks:IsPurgable()
    return true
end

function modifier_unlimited_bladeworks:IsDebuff()
    return false
end

function modifier_unlimited_bladeworks:RemoveOnDeath()
    return true
end

function modifier_unlimited_bladeworks:GetTexture()
    return "custom/archer_5th_ubw"
end

-- function modifier_unlimited_bladeworks:GetModifierHealthBonus()
-- 	return self:GetAbility():GetSpecialValueFor("bonus_health") --+ (self:GetParent():HasModifier("modifier_shroud_of_martin") and self:GetParent():GetIntellect()*0 or 0)
-- end

-- function modifier_unlimited_bladeworks:GetModifierPhysicalArmorBonus()
-- 	return self:GetAbility():GetSpecialValueFor("bonus_armor")
-- end

-- function modifier_unlimited_bladeworks:GetModifierMagicalResistanceBonus()
-- 	return self:GetAbility():GetSpecialValueFor("bonus_mr")
-- end