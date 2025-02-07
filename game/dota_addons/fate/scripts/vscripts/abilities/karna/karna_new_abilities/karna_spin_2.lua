karna_spin_2 = class({})

 
LinkLuaModifier("modifier_karna_self_pause","abilities/karna/karna_new_abilities/karna_spin", LUA_MODIFIER_MOTION_NONE)

function karna_spin_2:OnSpellStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=0.9, activity=ACT_DOTA_CAST_ABILITY_1_END, rate=1})
	local ability = self
	local origin = caster:GetAbsOrigin()
	local aoe_radius = self:GetSpecialValueFor("radius")
	local aoe_damage = self:GetSpecialValueFor("damage")
	--caster:RemoveModifierByName("pause_sealenabled")
	caster:AddNewModifier(caster, self, "modifier_karna_self_pause", {Duration = 1.2}) 
	caster:FindAbilityByName("karna_recast_dash"):StartCooldown(1)
	local buff_ability = caster:FindAbilityByName("karna_buff_melee")
	Timers:CreateTimer(0.18, function()

		if not caster:IsAlive() then return end
		caster:EmitSound("karna_new_fire_2")
		caster:EmitSound("karna_new_karna_hit_2")
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				DoDamage(caster, v, aoe_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
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
				DoDamage(caster, v, aoe_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
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
				DoDamage(caster, v, aoe_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				if caster:HasModifier("modifier_karna_buff_melee") then
					buff_ability:ApplyBurnStacks(v)
				end

			end
		end
		

	
	end)
	Timers:CreateTimer(0.72, function()
		if not caster:IsAlive() then return end
		caster:EmitSound("karna_new_fire_2")
		caster:EmitSound("karna_new_karna_hit_2")
		local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, aoe_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
		for k,v in pairs(targets) do
			if v:GetName() ~= "npc_dota_ward_base" then
				DoDamage(caster, v, aoe_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
				if caster:HasModifier("modifier_karna_buff_melee") then
					buff_ability:ApplyBurnStacks(v)
				end

			end
		end
		

	
	end)

end
