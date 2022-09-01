diarmuid_warrior_charge = class({})

LinkLuaModifier("modifier_warrior_charge_attspd", "abilities/diarmuid/diarmuid_warrior_charge", LUA_MODIFIER_MOTION_NONE)

function diarmuid_warrior_charge:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local target_flag = DOTA_UNIT_TARGET_FLAG_NONE
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function diarmuid_warrior_charge:GetCooldown(iLevel)
	if self:GetCaster():HasModifier("modifier_rampant_warrior") then
		return self:GetSpecialValueFor("combo_cd")
	elseif self:GetCaster():HasModifier("modifier_double_spearmanship_active") then
		return self:GetSpecialValueFor("doublespear_cd")
	else
		return self:GetSpecialValueFor("cooldown")
	end
end

function diarmuid_warrior_charge:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if IsSpellBlocked(target) then return end -- Linken effect checker

	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
	if((target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > self:GetSpecialValueFor("cast_range_checker")) then
		self:EndCooldown()
		return
	end
	caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 100) 
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

	StartAnimation(caster, {duration=0.35, activity=ACT_DOTA_CAST_ABILITY_1_END, rate=2})
	

	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage")
	local duration = self:GetSpecialValueFor("duration")

	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
    	DoDamage(caster, v, damage, DAMAGE_TYPE_PHYSICAL, 0, self, false)
	end

	--target:AddNewModifier(caster, v, "modifier_stunned", {Duration = 0.75})

	target:AddNewModifier(caster, v, "modifier_rooted", {Duration = duration})
	caster:PerformAttack(target, true, true, true, true, false, false, false)

	if caster:HasModifier("modifier_doublespear_active") or caster:HasModifier("modifier_rampant_warrior") then 
		local doubleTarget = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(doubleTarget) do
	    	DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end

		caster:PerformAttack(target, true, true, true, true, false, false, false)
	end

	caster:AddNewModifier(caster, self, "modifier_warrior_charge_attspd", { duration = 2.0 })

	--particle
	caster:EmitSound("Hero_Huskar.Life_Break")
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_sven/sven_storm_bolt_projectile_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin())
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
	end)
end

function diarmuid_warrior_charge:ReduceCooldown()
	local remainingCooldown = self:GetCooldownTimeRemaining()

	if remainingCooldown > 1 then		
		self:EndCooldown()
		self:StartCooldown(math.max(1, remainingCooldown - 1))
	end
end

modifier_warrior_charge_attspd = class({})

function modifier_warrior_charge_attspd:GetModifierAttackSpeedBonus_Constant()
	return 200
end

function modifier_warrior_charge_attspd:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_warrior_charge_attspd:IsHidden() 
	return true 
end