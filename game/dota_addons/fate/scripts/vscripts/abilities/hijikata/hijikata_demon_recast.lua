hijikata_demon_recast = class({})


function hijikata_demon_recast:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("hijikata_demon"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("hijikata_demon"):SetLevel(self:GetLevel())
    end

end


--phase start 0.3
function hijikata_demon_recast:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=0.7, activity=ACT_DOTA_CAST_ABILITY_ROT, rate=0.9})
end

function hijikata_demon_recast:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
end

 

function hijikata_demon_recast:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	local origin = caster:GetAbsOrigin()
	local distance = (targetPoint - origin):Length2D()
	local forward = (targetPoint - origin):Normalized()
	local aoe_radius = self:GetSpecialValueFor("radius")
	local aoe_damage = self:GetSpecialValueFor("damage")
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.4)  
	local part1 = false
	local part2 = false

	if caster:GetAbilityByIndex(1):GetName() == "hijikata_demon_recast"  then
		caster:SwapAbilities("hijikata_demon", "hijikata_demon_recast", true, false)
	end
	Timers:CreateTimer(0.1, function()

	if not caster:IsAlive() then return end
		EmitSoundOn("hijikata_attack_1", caster)
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				local origin_diff = v:GetAbsOrigin() - caster:GetAbsOrigin()
  				local origin_diff_norm = origin_diff:Normalized()
   				if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
					if not part1 then
						DoCleaveAttack(caster, v, self, caster:GetAverageTrueAttackDamage(hCaster), 500, 500, 500, "particles/hijikata/hijikata_cleave.vpcf")
						part1 = true
					end
					DoDamage(caster, v, aoe_damage, self:GetAbilityDamageType(), 0, self, false)
					if caster.IsShinsengumiAcquired then
						DoDamage(caster, v, caster:GetAverageTrueAttackDamage(hCaster) * 0.5, self:GetAbilityDamageType(), 0, self, false)
					end
					
				end
			end
		end
		if #targets > 0 then
			if caster:GetHealth() < caster:GetMaxHealth() then
				caster:Heal(self:GetSpecialValueFor("heal")/100 * caster:GetMaxHealth(), caster)
			 end
		end

	
	
	end)

	Timers:CreateTimer(0.3, function()
		EmitSoundOn("hijikata_attack_1", caster)
		if not caster:IsAlive() then return end
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				local origin_diff = v:GetAbsOrigin() - caster:GetAbsOrigin()
				local origin_diff_norm = origin_diff:Normalized()
				if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
					if not part2 then
						DoCleaveAttack(caster, v, self, caster:GetAverageTrueAttackDamage(hCaster), 500, 500, 500, "particles/hijikata/hijikata_cleave.vpcf")
						part2 = true
					end
				    DoDamage(caster, v, aoe_damage, self:GetAbilityDamageType(), 0, self, false)
					if caster.IsShinsengumiAcquired then
						DoDamage(caster, v, caster:GetAverageTrueAttackDamage(hCaster)* 0.5, self:GetAbilityDamageType(), 0, self, false)
					end
			  	end
			end
		end
		
		if #targets > 0 then
			if caster:GetHealth() < caster:GetMaxHealth() then
				caster:Heal(self:GetSpecialValueFor("heal")/100 * caster:GetMaxHealth(), caster)
			 end
		end

	
	end)


end
