heracles_courage = class({})

LinkLuaModifier("modifier_courage_self_buff", "abilities/heracles/modifiers/modifier_courage_self_buff", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_courage_enemy_debuff", "abilities/heracles/modifiers/modifier_courage_enemy_debuff", LUA_MODIFIER_MOTION_NONE)

function heracles_courage:GetAOERadius()
	local hDivinity = self:GetCaster():FindAbilityByName("pepeg_divinity")
	return self:GetSpecialValueFor("radius")+(hDivinity:GetLevel() > 1 and self:GetCaster():GetStrength() * 2 or 0)
end

function heracles_courage:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local radius = self:GetAOERadius()
	local active_radius = self:GetSpecialValueFor("active_radius")
	local lazy_counter = 1
	local active_damage = self:GetSpecialValueFor("damage")
	local active_stun = self:GetSpecialValueFor("stun_duration")
	if(caster.MEacquired == true) then
		local cd = caster:FindAbilityByName("heracles_nine_lives"):GetCooldownTimeRemaining()
		caster:FindAbilityByName("heracles_nine_lives"):EndCooldown()
		if(cd > 0 ) then
			caster:FindAbilityByName("heracles_nine_lives"):StartCooldown(cd -15)
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

	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.zlodemon == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_herc_w"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
	caster:EmitSound("Hero_Axe.Berserkers_Call")
	if caster:HasModifier("modifier_hero_selection_skin") then
		if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
			caster:EmitSound("barbatos_attack1")
		else
			caster:EmitSound("Heracles_Roar_" .. math.random(1,6))
		end
	else
		caster:EmitSound("Heracles_Roar_" .. math.random(1,6))
	end
	

	-- Reduce Nine Lives cooldown if applicable
	--[[if caster.IsEternalRageAcquired then
		ReduceCooldown(caster:FindAbilityByName("heracles_nine_lives"), 5)
	end]]
	local targetsActive = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, active_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targetsActive) do            
        DoDamage(caster, v, active_damage, self:GetAbilityDamageType(), 0, self, false)
        v:AddNewModifier(caster, self, "modifier_stunned", {Duration = active_stun, })     
    end 
	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "heracles_w_slam_sfx", caster)
	ScreenShake(caster:GetOrigin(), 15, 0.5, 0.5, 2000, 0, true)
 	local particle = ParticleManager:CreateParticle("particles/zlodemon/herc_ground_slam.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin() + caster:GetForwardVector() * 50)
	Timers:CreateTimer(0.5, function()
        ParticleManager:DestroyParticle(particle, false)
        ParticleManager:ReleaseParticleIndex(particle)
    end)
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 then
		if caster.QUsed and caster:FindAbilityByName("berserker_5th_madmans_roar"):IsCooldownReady() then
			caster:AddNewModifier(caster, self, "modifier_heracles_combo_window", { Duration = 3 })
		end
	end
end