karna_spin_2 = class({})

 
LinkLuaModifier("modifier_karna_self_pause","abilities/karna/karna_new_abilities/karna_spin", LUA_MODIFIER_MOTION_NONE)

function karna_spin_2:OnSpellStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=0.9, activity=ACT_DOTA_CAST_ABILITY_1_END, rate=1})
	local ability = self
	local origin = caster:GetAbsOrigin()
	local aoe_radius = self:GetSpecialValueFor("radius")
	local aoe_damage = self:GetSpecialValueFor("damage")
	local bMartialArts = caster.ManaBurstAttribute
	local bArmorRestore = false
	local bArmorRestore1 = false
	local bArmorRestore2 = false
	local bArmorRestore3 = false
	local bArmorActive = caster:FindModifierByName("modifier_karna_buff_melee")
	local armor_modifier = caster:FindModifierByName("modifier_karna_armor") 
	--caster:RemoveModifierByName("pause_sealenabled")
	caster:AddNewModifier(caster, self, "modifier_karna_self_pause", {Duration = 0.8}) 
	caster:FindAbilityByName("karna_recast_dash"):StartCooldown(1)
	local buff_ability = caster:FindAbilityByName("karna_buff_melee")
	Timers:CreateTimer(0.18, function()

		if not caster:IsAlive() then return end
		caster:EmitSound("karna_new_fire_2")
		caster:EmitSound("karna_new_karna_hit_2")
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
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
	
			end
		end
	
	
	end)

	Timers:CreateTimer(0.45, function()
		if not caster:IsAlive() then return end

		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				DoDamage(caster, v, aoe_damage, self:GetAbilityDamageType(), 0, self, false)
				if not bArmorRestore1 and  bArmorActive ~= nil then 
					armor_modifier:RestoreArmorPercentage(5)
					bArmorRestore1 = true
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

			end
		end
		

	
	end)

	Timers:CreateTimer(0.55, function()
		if not caster:IsAlive() then return end
		caster:EmitSound("karna_new_fire_2")
		caster:EmitSound("karna_new_karna_hit_2")
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
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

			end
		end
		

	
	end)
	Timers:CreateTimer(0.72, function()
		if not caster:IsAlive() then return end
		if caster:HasModifier("modifier_hero_selection_skin") then
			caster:EmitSound("karna_new_fire_2")
			caster:EmitSound("aemis_human_q")
		else
			caster:EmitSound("karna_new_fire_2")
			caster:EmitSound("karna_new_karna_hit_2")
		end
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				DoDamage(caster, v, aoe_damage, self:GetAbilityDamageType(), 0, self, false)
				if not bArmorRestore3 and  bArmorActive ~= nil then 
					armor_modifier:RestoreArmorPercentage(5)
					bArmorRestore3 = true
				end
				if bMartialArts then 
					if v:HasModifier("modifier_karna_ucm_sa_stacking") then
						local stacks = v:GetModifierStackCount("modifier_karna_ucm_sa_stacking", caster)
						if stacks == 4 then 
							DoDamage(caster, v, caster:GetIntellect() * 1.5, self:GetAbilityDamageType(), 0, self, false)
							giveUnitDataDrivenModifier(caster, v, "stunned",  0.5)
							v:RemoveModifierByName("modifier_karna_ucm_sa_stacking")
						else
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

			end
		end
		

	
	end)

end
