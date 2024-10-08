-----------------------------
--    May King    --
-----------------------------

robin_may_king = class({})

LinkLuaModifier("modifier_robin_may_king_invis", "abilities/robin/modifiers/modifier_robin_may_king_invis", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_robin_yew_bow_combo_window", "abilities/robin/modifiers/modifier_robin_yew_bow_combo_window", LUA_MODIFIER_MOTION_NONE)

function robin_may_king:OnSpellStart()
	local ability = self
	local caster = ability:GetCaster()

	caster:EmitSound("Hero_BountyHunter.WindWalk")
	
	caster:EmitSound("robin_may_king")

	caster:AddNewModifier(caster, self, "modifier_robin_may_king_invis", {fadeDelay = self:GetSpecialValueFor("fade_delay"),
													    		duration = self:GetSpecialValueFor("duration")

	})
	
		--[[local team = 0
		if caster:GetTeam() == DOTA_TEAM_GOODGUYS then 
			team = DOTA_TEAM_BADGUYS 
		else 
			team = DOTA_TEAM_GOODGUYS
		end]]
		--local units = FindUnitsInRadius(enemyTeamNumber, caster:GetAbsOrigin(), nil, 2500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
		local units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		for i=1, #units do
			print(units[i]:GetUnitName())
			if units[i]:GetUnitName() == "ward_familiar" or units[i]:GetUnitName() ==  "sentry_familiar" then
				caster:PerformAttack(units[i], true, true, true, true, false, false, true)
				Timers:CreateTimer(0.1, function()
					caster:PerformAttack(units[i], true, true, true, true, false, false, true)
				end)
				Timers:CreateTimer(0.2, function()
					caster:PerformAttack(units[i], true, true, true, true, false, false, true)
				end)

			end
		end
		
	self:CheckCombo()
end

function robin_may_king:CheckCombo()
	local caster = self:GetCaster()

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect(true) >= 29.1 then
		if caster:FindAbilityByName("robin_yew_bow"):IsCooldownReady() 
		and caster:FindAbilityByName("robin_yew_tree_combo"):IsCooldownReady() then
			caster:AddNewModifier(caster, self, "modifier_robin_yew_bow_combo_window", { Duration = 5 })
		end
	end
end


function robin_may_king:OnOwnerDied()
	local caster = self:GetCaster()

	caster.IsInMarble = false
end