semiramis_summon_basmu = class({})

function semiramis_summon_basmu:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_NO_TARGET
end

function semiramis_summon_basmu:OnSpellStart()
	local caster = self:GetCaster()
	local snek = nil

	if IsValidEntity(caster.SnekUnit) and caster.SnekUnit:IsAlive() then
		caster.SnekUnit:SetAbsOrigin(caster:GetAbsOrigin())
		caster.SnekUnit:Heal(caster.SnekUnit:GetMaxHealth(), nil)
		snek = caster.SnekUnit
	else
		snek = CreateUnitByName("semiramis_snek", caster:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber())		
	end	

	snek:SetMaxHealth(self:GetSpecialValueFor("snek_health"))
	snek:SetBaseDamageMin(self:GetSpecialValueFor("snek_damage"))
	snek:SetBaseDamageMax(self:GetSpecialValueFor("snek_damage"))
	snek:SetBaseMoveSpeed(self:GetSpecialValueFor("snek_movespeed"))

	snek:FindAbilityByName("semiramis_snek_spit_poison"):SetLevel(self:GetLevel())
	snek:FindAbilityByName("semiramis_snek_passive_poison"):SetLevel(self:GetLevel())

	snek:AddNewModifier(caster, nil, "modifier_kill", {duration = self:GetSpecialValueFor("duration")})

	caster.SnekUnit = snek
end