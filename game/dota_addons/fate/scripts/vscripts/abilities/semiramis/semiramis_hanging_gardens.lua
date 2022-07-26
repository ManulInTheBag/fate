semiramis_hanging_gardens = class({})

function semiramis_hanging_gardens:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	caster:EmitSound("semiramis_hanginggardens_cast_" .. math.random(1,2))
	
	return true
end

function semiramis_hanging_gardens:OnSpellStart()
	local caster = self:GetCaster()

	EmitGlobalSound("semiramis_hanginggardens_complete_1")

	local garden = nil

	if IsValidEntity(caster.HangingGardens) and caster.HangingGardens:IsAlive() then
		caster.HangingGardens:SetAbsOrigin(caster:GetAbsOrigin())	
		caster.HangingGardens:Heal(caster.HangingGardens:GetMaxHealth(), nil)	
		garden = caster.HangingGardens
	else
		garden = CreateUnitByName("semiramis_hanging_gardens", caster:GetAbsOrigin(), true, nil, nil, caster:GetTeamNumber())		
	end	

	garden:SetMaxHealth(self:GetSpecialValueFor("garden_health"))
	garden:SetBaseDamageMin(self:GetSpecialValueFor("garden_damage"))
	garden:SetBaseDamageMax(self:GetSpecialValueFor("garden_damage"))
	garden:SetBaseMoveSpeed(self:GetSpecialValueFor("garden_movespeed"))

	if caster.AerialGardenAttribute then
		garden:FindAbilityByName("hanging_gardens_summon_skeletons"):SetLevel(2)
		garden:FindAbilityByName("hanging_gardens_mass_recall"):SetLevel(2)
		garden:FindAbilityByName("hanging_gardens_bombard"):SetLevel(2)

		garden:AddNewModifier(caster, nil, "modifier_kill", { Duration = self:GetSpecialValueFor("duration") })
	end	

	caster.HangingGardens = garden

	local rocks = ParticleManager:CreateParticle( "particles/custom/semiramis/hanghing_gardens_rocks.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( self.particle, 0, garden:GetAbsOrigin())
	ParticleManager:SetParticleControl( self.particle, 1, garden:GetAbsOrigin())	
end