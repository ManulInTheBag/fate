karna_slashes = class({})

function karna_slashes:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function karna_slashes:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("karna_brahmastra_new"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("karna_brahmastra_new"):SetLevel(self:GetLevel())
    end

end

function karna_slashes:CastFilterResultLocation(location)
    local caster = self:GetCaster()
    if IsServer() and  (caster:FindModifierByName("modifier_karna_self_pause") or caster:FindModifierByName("modifier_karna_self_pause_2")) then
        return UF_FAIL_CUSTOM
    else
        return UF_SUCESS
    end
end

function karna_slashes:GetCustomCastErrorLocation()
	return "Performing other ability"
end

--phase start 0.2
function karna_slashes:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=0.6, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.4})
end

function karna_slashes:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
end

 

function karna_slashes:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local ability = self
	local origin = caster:GetAbsOrigin()
	local distance = (targetPoint - origin):Length2D()
	local forward = (targetPoint - origin):Normalized()
	local time = 0.8
	local aoe_radius = self:GetSpecialValueFor("radius")
	local aoe_damage = self:GetSpecialValueFor("damage")
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.4)  
	local buff_ability = caster:FindAbilityByName("karna_buff_melee")
	if caster:HasModifier("modifier_hero_selection_skin") then
		caster:EmitSound("karna_new_fire_2")
		caster:EmitSound("aemis_human_w")
	else
		caster:EmitSound("karna_new_fire_2")
		caster:EmitSound("karna_new_karna_hit_3")
	end
	local saBool1 = false
	local saBool2 = false
	local bMartialArts = caster.ManaBurstAttribute
	local armor_modifier = caster:FindModifierByName("modifier_karna_armor") 
	local bArmorRestore = false
	local bArmorRestore2 = false
	local bArmorActive = caster:FindModifierByName("modifier_karna_buff_melee")
	Timers:CreateTimer(0.0, function()

		--local particle = ParticleManager:CreateParticle("particles/karna/karna_spin_slash.vpcf", PATTACH_ABSORIGIN, caster)
		--ParticleManager:ReleaseParticleIndex(particle)
	if not caster:IsAlive() then return end
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				local origin_diff = v:GetAbsOrigin() - caster:GetAbsOrigin()
  				local origin_diff_norm = origin_diff:Normalized()
   				if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
					DoDamage(caster, v, aoe_damage, self:GetAbilityDamageType(), 0, self, false)
					if not bArmorRestore and  bArmorActive ~= nil then 
						armor_modifier:RestoreArmorPercentage(5)
						bArmorRestore = true
					end
					if bMartialArts then 
						if v:HasModifier("modifier_karna_ucm_sa_stacking") then
							local stacks = v:GetModifierStackCount("modifier_karna_ucm_sa_stacking", caster)
							if stacks == 4 then 
								DoDamage(caster, v, caster:GetIntellect() * 1.5, self:GetAbilityDamageType(), 0, self, false)
								giveUnitDataDrivenModifier(caster, v, "stunned",  0.5)
								v:RemoveModifierByName("modifier_karna_ucm_sa_stacking")
							else
								v:AddNewModifier(caster, self, "modifier_karna_ucm_sa_stacking", { Duration = 2})	
								v:FindModifierByName("modifier_karna_ucm_sa_stacking"):SetStackCount(stacks + 1)
							end
						else
							v:AddNewModifier(caster, self, "modifier_karna_ucm_sa_stacking", { Duration = 2})	
							v:FindModifierByName("modifier_karna_ucm_sa_stacking"):SetStackCount(1)
						end
					end
					if caster:HasModifier("modifier_karna_buff_melee") then
						buff_ability:ApplyBurnStacks(v)
					end
					if not saBool1 then
						if caster.UncrownedAttribute then
							armor_modifier:RestoreArmorPercentage(10)
						end
						saBool1 = true
					end
				end
			end
		end
	
	
	end)
	Timers:CreateTimer(0.35, function()
	if caster:HasModifier("modifier_hero_selection_skin") then
		caster:EmitSound("karna_new_fire_2")
	else
		caster:EmitSound("karna_new_fire_2")
		caster:EmitSound("karna_new_karna_hit_3")
	end

	end)
	Timers:CreateTimer(0.4, function()
		--local particle = ParticleManager:CreateParticle("particles/karna/karna_spin_slash_2.vpcf", PATTACH_ABSORIGIN, caster)
		--ParticleManager:ReleaseParticleIndex(particle)

		if not caster:IsAlive() then return end
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				local origin_diff = v:GetAbsOrigin() - caster:GetAbsOrigin()
				local origin_diff_norm = origin_diff:Normalized()
				if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
				    DoDamage(caster, v, aoe_damage, self:GetAbilityDamageType(), 0, self, false)
				if not bArmorRestore2 and  bArmorActive ~= nil then 
					armor_modifier:RestoreArmorPercentage(5)
					bArmorRestore2 = true
				end
					if bMartialArts then 
						if v:HasModifier("modifier_karna_ucm_sa_stacking") then
							local stacks = v:GetModifierStackCount("modifier_karna_ucm_sa_stacking", caster)
							if stacks == 4 then 
								DoDamage(caster, v, caster:GetIntellect() * 1.5, self:GetAbilityDamageType(), 0, self, false)
								giveUnitDataDrivenModifier(caster, v, "stunned",  0.5)
								v:RemoveModifierByName("modifier_karna_ucm_sa_stacking")
							else
								v:AddNewModifier(caster, self, "modifier_karna_ucm_sa_stacking", { Duration = 2})	
								v:FindModifierByName("modifier_karna_ucm_sa_stacking"):SetStackCount(stacks + 1)
							end
						else
							v:AddNewModifier(caster, self, "modifier_karna_ucm_sa_stacking", { Duration = 2})	
							v:FindModifierByName("modifier_karna_ucm_sa_stacking"):SetStackCount(1)
						end
					end
					if caster:HasModifier("modifier_karna_buff_melee") then
						buff_ability:ApplyBurnStacks(v)
					end
					if  not saBool2 then
						if caster.UncrownedAttribute then
							armor_modifier:RestoreArmorPercentage(10)
						end
						saBool2 = true
					end
			  	end
			end
		end
		if saBool1 == true and saBool2 == true and caster.ManaBurstAttribute then
			if self:GetCooldownTimeRemaining() > 1 then
				self:EndCooldown()
				self:StartCooldown(1)
			end
		end

	
	end)


end
