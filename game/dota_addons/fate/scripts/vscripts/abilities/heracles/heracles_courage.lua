heracles_courage = class({})

LinkLuaModifier("modifier_courage_self_buff", "abilities/heracles/modifiers/modifier_courage_self_buff", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_courage_enemy_debuff", "abilities/heracles/modifiers/modifier_courage_enemy_debuff", LUA_MODIFIER_MOTION_NONE)

function heracles_courage:GetAOERadius()
	return self:GetSpecialValueFor("radius")+(self:GetCaster().IsDivinityImproved and self:GetCaster():GetStrength()*3 or 0)
end

function heracles_courage:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local radius = self:GetAOERadius()
	print (radius)
	local lazy_counter = 0
	if(caster.MEacquired == true) then
		local cd = caster:FindAbilityByName("heracles_nine_lives"):GetCooldownTimeRemaining()
		caster:FindAbilityByName("heracles_nine_lives"):EndCooldown()
		if(cd > 0 ) then
			caster:FindAbilityByName("heracles_nine_lives"):StartCooldown(cd -5)
		end
	end
	-- Apply stackable speed buff
	--[[local currentStack = caster:GetModifierStackCount("modifier_courage_self_buff", self)
	if modifier then 
		currentStack = modifier:GetStackCount()	
	end]]

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	local targets1 = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)

	for k,v in pairs(targets) do
		--if not IsFacingUnit(v, caster, 90) then
			v:AddNewModifier(caster, self, "modifier_courage_enemy_debuff", { Duration = self:GetSpecialValueFor("enemy_duration") })
			if caster:HasModifier("modifier_heracles_berserk") then
				v:AddNewModifier(caster, self, "modifier_disarmed", {duration = 2})
			end
		--end
	end
	for k,v in pairs(targets1) do
		lazy_counter = lazy_counter + 1
	end

	local modifier = caster:AddNewModifier(caster, self, "modifier_courage_self_buff", { Duration = self:GetSpecialValueFor("duration"), Stacks = lazy_counter })

	RemoveSlowEffect(caster)

	caster:EmitSound("Hero_Axe.Berserkers_Call")
	caster:EmitSound("Heracles_Roar_" .. math.random(1,6))

	-- Reduce Nine Lives cooldown if applicable
	--[[if caster.IsEternalRageAcquired then
		ReduceCooldown(caster:FindAbilityByName("heracles_nine_lives"), 5)
	end]]
	if caster:GetStrength() >= 39.1 and caster:GetAgility() >= 39.1 then
		if caster.QUsed and caster:FindAbilityByName("berserker_5th_madmans_roar"):IsCooldownReady() then
			caster:AddNewModifier(caster, self, "modifier_heracles_combo_window", { Duration = 3 })
		end
	end
end