function OnEveningStart(keys)
    local caster = keys.caster
    local ability = keys.ability

    ability:ApplyDataDrivenModifier(caster, caster, "modifier_kinghassan_eveningbell", {})

    caster:EmitSound("Hero_OgreMagi.FireShield.Target")
    KHCheckCombo(caster,ability)
end 

function EveningOnTakeDamage(keys)
	local caster = keys.caster
	local ability = keys.ability
	local currentHealth = caster:GetHealth()
	local revive_health = ability:GetSpecialValueFor("revive_health")
	local revive_time = ability:GetSpecialValueFor("revive_time")

	if currentHealth <= 0 and caster.IsAbyssAcquired and IsRevivePossible(caster) and not caster:HasModifier("modifier_kinghassan_revive_cooldown") then
		caster:SetHealth(revive_health)
		if not caster:HasModifier("modifier_kinghassan_revive") then 
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_kinghassan_revive", {})
			HardCleanse(caster)
			giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.1)

	    	caster:EmitSound("KingHassan.Rencar")

			local reviveFx = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(reviveFx, 3, caster:GetAbsOrigin())

			local PI1 = FxCreator("particles/custom/vlad/vlad_bc_cast.vpcf", PATTACH_CENTER_FOLLOW, caster,0, nil)
		  	ParticleManager:SetParticleControlEnt(PI1, 2, caster, PATTACH_CENTER_FOLLOW, nil, caster:GetAbsOrigin(), false)
		  	ParticleManager:SetParticleControlEnt(PI1, 3, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), false)

			Timers:CreateTimer(revive_time, function()
				FxDestroyer(PI1, false)
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_kinghassan_revive_cooldown", {})
				--caster:RemoveModifierByName("modifier_kinghassan_eveningbell")
				ParticleManager:DestroyParticle(reviveFx, false)
				ParticleManager:ReleaseParticleIndex( reviveFx)
			end)
		end
	end
end

function OnReviveBurst(keys)
	local caster = keys.caster
	local ability = keys.ability
	local revive_damage = ability:GetSpecialValueFor("revive_damage") / 100
	local revive_radius = ability:GetSpecialValueFor("revive_radius")
	local void_health = caster:GetMaxHealth() - caster:GetHealth()
	local resExp = ParticleManager:CreateParticle("particles/custom/berserker/god_hand/stomp.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, revive_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do 
		DoDamage(caster, v, void_health * revive_damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	end
end

function OnHassanKill(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.unit


	if target:IsHero() then 
		stack = caster:GetModifierStackCount("modifier_kinghassan_stack", caster) or 0
		caster:SetModifierStackCount("modifier_kinghassan_stack", caster, stack + 1)
	end 
end

function OnFaithReady(keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_kinghassan_faith_passive", {})
end

function OnBodyAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster.HeroUnit

	if not MasterCannotUpgrade(hero, caster, keys.ability, hero.IsBodyAcquired) then

		hero.IsBodyAcquired = true

		UpgradeAttribute(hero, "kinghassan_flames_of_gehenna", "kinghassan_flames_of_gehenna_upgrade" , true)

		hero.DSkill = "kinghassan_flames_of_gehenna_upgrade"

		NonResetAbility(hero)

		-- UpgradeAttribute(hero, "kinghassan_azrael", "kinghassan_azrael_upgraded", true)
		-- Set master 1's mana 
		local master = hero.MasterUnit
		master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	end
end

function OnOldManOfTheMountainAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster.HeroUnit

	if not MasterCannotUpgrade(hero, caster, keys.ability, hero.IsOldManOfTheMountainAcquired) then

		hero.IsOldManOfTheMountainAcquired = true

		UpgradeAttribute(hero, "kinghassan_azrael", "kinghassan_azrael_upgrade" , true)
		UpgradeAttribute(hero, "kinghassan_dreadful_slash", "kinghassan_dreadful_slash_upgrade" , true)

		hero.WSkill = "kinghassan_dreadful_slash_upgrade"
		hero.RSkill = "kinghassan_azrael_upgrade"

		NonResetAbility(hero)

		-- UpgradeAttribute(hero, "kinghassan_azrael", "kinghassan_azrael_upgraded", true)
		-- Set master 1's mana 
		local master = hero.MasterUnit
		master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	end
end

function OnPresenceAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster.HeroUnit

	if not MasterCannotUpgrade(hero, caster, keys.ability, hero.IsPresenceAcquired) then

		if hero:HasModifier("modifier_ambush_think") then 
			hero:RemoveModifierByName("modifier_ambush_think")
		end

		hero.IsPresenceAcquired = true

		UpgradeAttribute(hero, "kinghassan_death_arrival", "kinghassan_death_arrival_upgrade", false)
		UpgradeAttribute(hero, "kinghassan_death_approaching", "kinghassan_death_approaching_upgrade", true)

		hero.QSkill = "kinghassan_death_approaching_upgrade"

		NonResetAbility(hero)

		-- Set master 1's mana 
		local master = hero.MasterUnit
		master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	end
end

function OnAbyssAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster.HeroUnit

	if not MasterCannotUpgrade(hero, caster, keys.ability, hero.IsAbyssAcquired) then

		if hero:HasModifier("modifier_combo_window") then 
			hero:RemoveModifierByName("modifier_combo_window")
		end

		hero.IsAbyssAcquired = true

		UpgradeAttribute(hero, "kinghassan_evening_bell", "kinghassan_evening_bell_upgrade", true)

		hero.ESkill = "kinghassan_evening_bell_upgrade"

		NonResetAbility(hero)

		-- Set master 1's mana 
		local master = hero.MasterUnit
		master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	end
end

function OnBoundaryAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster.HeroUnit

	if not MasterCannotUpgrade(hero, caster, keys.ability, hero.IsBoundaryAcquired) then

		if hero:HasModifier("modifier_combo_window") then 
			hero:RemoveModifierByName("modifier_combo_window")
		end

		hero.IsBoundaryAcquired = true

		hero:SwapAbilities("fate_empty1", "kinghassan_beheader", false, true)
		UpgradeAttribute(hero, "kinghassan_combo", "kinghassan_combo_upgrade", false)

		hero:FindAbilityByName("kinghassan_stack"):SetLevel(1)

		hero.FSkill = "kinghassan_beheader"

		NonResetAbility(hero)

		-- Set master 1's mana 
		local master = hero.MasterUnit
		master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	end
end

function OnFaithAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster.HeroUnit

	if not MasterCannotUpgrade(hero, caster, keys.ability, hero.IsFaithAcquired) then

		hero.IsFaithAcquired = true

		hero:FindAbilityByName("kinghassan_faith"):SetLevel(1)

		-- Set master 1's mana 
		local master = hero.MasterUnit
		master:SetMana(master:GetMana() - keys.ability:GetManaCost(keys.ability:GetLevel()))
	end
end

function OnFlamesThink(keys)
	local caster = keys.caster
	local ability = keys.ability 
	local target = keys.target
	local damage = ability:GetSpecialValueFor("damage")
	if string.match(ability:GetAbilityName(), "flame") and caster.IsBodyAcquired then 
		local bonus_str = ability:GetSpecialValueFor("bonus_dps_str") * caster:GetStrength()
		damage = damage + bonus_str
	end

	if target:IsAlive() then
		DoDamage(caster, target, damage * 0.2, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	end
end
 
function OnFlamesHeal(keys)
	local caster = keys.caster
	local ability = keys.ability 
	local heal = ability:GetSpecialValueFor("heal")
	if string.match(ability:GetAbilityName(), "flame") and caster.IsBodyAcquired then 
		local bonus_str = ability:GetSpecialValueFor("bonus_heal_str") * caster:GetStrength()
		heal = heal + bonus_str
	end
	caster:Heal(heal * 0.2, caster)
end

function OnFlamesStart(keys)
	local caster = keys.caster      
	local ability = keys.ability

    caster:EmitSound("KingHassan.Dokoda") 
    ability:ApplyDataDrivenModifier(caster, caster, "modifier_kinghassan_flame_cooldown", {Duration = ability:GetCooldown(1)})
    local particle = ParticleManager:CreateParticle("particles/kinghassan/raze/hassanraze.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_flame_gehena_aura", {})
    KHCheckCombo(caster,ability)

end

function OnSlashStart(keys)
	local caster = keys.caster      
	local ability = keys.ability
	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage")
	local stun = ability:GetSpecialValueFor("stun")

	caster:EmitSound("Hero_Axe.CounterHelix_Blood_Chaser")
	giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.2)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_kinghassan_dread_slash", {})

	local spin = ParticleManager:CreateParticle("particles/custom/kinghassan/ka_spin.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(spin, 0, caster:GetAbsOrigin() + Vector(0,0,50))
	ParticleManager:SetParticleControl(spin, 1, Vector(radius - 70,0,0))

	Timers:CreateTimer(0.2, function()
		ParticleManager:DestroyParticle(spin, true)
		ParticleManager:ReleaseParticleIndex(spin)
	end)
	
	local enemies = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	for k,v in pairs(enemies) do
		DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
		v:AddNewModifier(caster, ability, "modifier_stunned", {Duration = stun})
	end


end

function KHCheckCombo(caster, ability)
    if math.ceil(caster:GetStrength()) >= 25 and math.ceil(caster:GetAgility()) >= 25 and math.ceil(caster:GetIntellect()) >= 25 then 
        if string.match(ability:GetAbilityName(), caster.DSkill) then
			caster.DUsed = true
			caster.DTime = GameRules:GetGameTime()
			if caster.DTimer ~= nil then 
				Timers:RemoveTimer(caster.DTimer)
				caster.DTimer = nil
			end
			caster.DTimer = Timers:CreateTimer(5.0, function()
				caster.DUsed = false
			end)
		else
			if string.match(ability:GetAbilityName(), caster.ESkill) and caster:FindAbilityByName(caster.RSkill):IsCooldownReady() and not caster:HasModifier("modifier_kinghassan_combo_cooldown") then 
				if caster.DUsed == true then 
					local newTime =  GameRules:GetGameTime()
					local duration = 5 - (newTime - caster.DTime)
					ability:ApplyDataDrivenModifier(caster, caster, "modifier_combo_window", {duration = duration})
				end
			end
		end
    end
end

function OnComboWindow(keys)
	local caster = keys.caster
	if caster.IsBoundaryAcquired then
		caster:SwapAbilities(caster.RSkill, "kinghassan_combo_upgrade", false, true)
	else
		caster:SwapAbilities(caster.RSkill, "kinghassan_combo", false, true)
	end
end

function OnComboWindowBroken(keys)
	local caster = keys.caster
	if caster.IsBoundaryAcquired then
		caster:SwapAbilities(caster.RSkill, "kinghassan_combo_upgrade", true, false)
	else
		caster:SwapAbilities(caster.RSkill, "kinghassan_combo", true, false)
	end
end

function OnComboWindowDeath(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_combo_window")
end




function OnComboCast(keys)
	local caster = keys.caster 
	local target = keys.target
	local ability = keys.ability
	local damage = ability:GetSpecialValueFor("damage")
	local reduced_cd = ability:GetSpecialValueFor("reduced_cd")

	local masterCombo = caster.MasterUnit2:FindAbilityByName("kinghassan_combo")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(ability:GetCooldown(1))
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_kinghassan_combo_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
	caster:RemoveModifierByName("modifier_combo_window")

	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 9)
	StartAnimation(caster, {duration=1, activity=ACT_DOTA_CAST_ABILITY_2, rate=0.8})

	EmitGlobalSound("KingHassan.BellSFX")

	local ult = caster:FindAbilityByName(caster.RSkill)
	ult:StartCooldown(ult:GetCooldown(ult:GetLevel()))

	if not target:IsRealHero() then 
	   	local hero = target:GetOwner()
	   	if IsValidEntity(hero) and IsMountedHero(hero) then 
	   		target = hero 
	   	end
    end

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_kinghassan_combo_cast", {})	    
	local particle = ParticleManager:CreateParticle("particles/kinghassan/combo/comboareadarknew.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())

	Timers:CreateTimer(0.5, function()
		GameRules:SendCustomMessage("<font color='#58ACFA'>" .. FindName(caster:GetName()) .. "</font> announced <font color='#58ACFA'>" .. FindName(target:GetName()) .. "</font> must be killed.", 0, 0)
		FreezeAnimation(caster,7)
	end)	

	Timers:CreateTimer(1.4, function()
		if caster:HasModifier("modifier_kinghassan_combo_cast") and caster:IsAlive() and target:IsAlive() then
			EmitGlobalSound("KingHassan.Combo")
			ability:ApplyDataDrivenModifier(caster, target, "modifier_kinghassan_death_announce", {})
	 		
	 		local fear = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 20000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
			for k,v in pairs(fear) do
				if IsInSameRealm(v:GetAbsOrigin(), caster:GetAbsOrigin()) then 
					ability:ApplyDataDrivenModifier(caster, v, "modifier_kinghassan_combo_fear", {Duration = 6.6})	
				end
			end
		else
			caster:RemoveModifierByName("pause_sealdisabled")
		end
	end)	

	Timers:CreateTimer(3.5, function()
		if caster:HasModifier("modifier_kinghassan_combo_cast") and caster:IsAlive() and target:IsAlive() then
			EmitGlobalSound("KingHassan.BellSFX")
			local dread = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 20000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
			for k,v in pairs(dread) do
				if IsInSameRealm(v:GetAbsOrigin(), caster:GetAbsOrigin()) then 
					ability:ApplyDataDrivenModifier(caster, v, "modifier_kinghassan_combo_dread", {Duration = 4.5})	
				end
			end
		else
			StopGlobalSound("KingHassan.Combo")
			caster:RemoveModifierByName("pause_sealdisabled")
		end
	end)

	Timers:CreateTimer(6.5, function()
		if caster:HasModifier("modifier_kinghassan_combo_cast") and caster:IsAlive() and target:IsAlive() then
			EmitGlobalSound("KingHassan.BellSFX")
			giveUnitDataDrivenModifier(caster, caster, "jump_pause", 1.5)
			local revive_block = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 20000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
			for k,v in pairs(revive_block) do
				if IsInSameRealm(v:GetAbsOrigin(), caster:GetAbsOrigin()) then 
					ability:ApplyDataDrivenModifier(caster, v, "modifier_kinghassan_combo_revive_lock", {Duration = 2.5})	
				end
			end
		else
			StopGlobalSound("KingHassan.Combo")
			caster:RemoveModifierByName("pause_sealdisabled")
		end
	end)

	Timers:CreateTimer(8, function()
		if caster:HasModifier("modifier_kinghassan_combo_cast") and caster:IsAlive() and target:IsAlive() then
			local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
			caster:SetAbsOrigin(target:GetAbsOrigin() - diff*100) 
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

			EmitGlobalSound("KingHassan.ComboSlashSFX")
			EmitGlobalSound("KingHassan.AzraelCut")


		    local particle = ParticleManager:CreateParticle("particles/kinghassan/combo/comboslashfromult.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster) --STILL QUESTIONABLE
		    ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
		    
			DoDamage(caster, target , damage, DAMAGE_TYPE_MAGICAL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, ability, false)
			if caster.IsBoundaryAcquired then 
				local execute = ability:GetSpecialValueFor("bonus_hb") / 100 
				local stack = caster:GetModifierStackCount("modifier_kinghassan_stack", caster) or 0
				if target:GetHealthPercent() < execute * stack and not target:IsMagicImmune() then 
					target:Execute(ability, caster, { bExecution = true })
					local hb = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, target)
					ParticleManager:SetParticleControl( hb, 4, target:GetAbsOrigin())

					Timers:CreateTimer( 2.0, function()
						ParticleManager:DestroyParticle( hb, false )
						ParticleManager:ReleaseParticleIndex(hb)
					end)
				end
			end
		else
			StopGlobalSound("KingHassan.Combo")
		end
	end)
end

function OnComboTargetDeath(keys)
	local caster = keys.caster 
	caster:RemoveModifierByName("pause_sealdisabled")
	caster:RemoveModifierByName("jump_pause")
	caster:RemoveModifierByName("modifier_kinghassan_combo_cast")
end

function OnComboDebuffThink(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target 
	local damage = ability:GetSpecialValueFor("dps")

	DoDamage(caster, target , damage/4, DAMAGE_TYPE_MAGICAL, 0, ability, false)
end

--[[function KHExecuteOnHit(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target 
	local stacksneeded = ability:GetSpecialValueFor("hits_needed")
	local stun_duration = ability:GetSpecialValueFor("stun")
	local damage = ability:GetSpecialValueFor("extra_damage")

	local stack = caster:GetModifierStackCount("modifier_kinghassan_passive", caster) or 0
	caster:SetModifierStackCount("modifier_kinghassan_passive", caster, stack + 1)

	if stack >= stacksneeded then
    	caster:EmitSound("KingHassan.Execute")
	    local particle = ParticleManager:CreateParticle("particles/econ/events/new_bloom/pig_death_pop.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())

		DoDamage(caster, target , damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
		target:AddNewModifier(caster, ability, "modifier_stunned", { Duration = stun_duration })
		caster:SetModifierStackCount("modifier_kinghassan_passive", caster,0)
	end
end]]

kinghassan_beheader = class({})
LinkLuaModifier("modifier_beheader_cooldown", "abilities/king_hassan/king_hassan_abilities", LUA_MODIFIER_MOTION_NONE)

function kinghassan_beheader:GetCastRange(vLocation, hTarget)
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_ambush") then 
		local blink = caster:GetAbilityByIndex(0):GetSpecialValueFor("range")
		return blink
	else
		return self:GetSpecialValueFor("range")
	end
end

function kinghassan_beheader:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local target = self:GetCursorTarget()
	local stun = ability:GetSpecialValueFor("stun")
	local damage = ability:GetSpecialValueFor("damage")
	local stackdamage = ability:GetSpecialValueFor("damage_per_stack")

	caster:AddNewModifier(caster, ability, "modifier_beheader_cooldown", { Duration = ability:GetCooldown(1)})

	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 100)
	FindClearSpaceForUnit( caster, caster:GetAbsOrigin(), true )	

	if IsSpellBlocked(target) then 
		caster:EmitSound("Hero_Axe.Culling_Blade_Fail ")
		return 
	end -- Linken effect checker

	local stack = caster:GetModifierStackCount("modifier_kinghassan_stack", caster) or 0

	caster:EmitSound("Hero_Axe.Culling_Blade_Success")

	caster:EmitSound("KingHassan.Shine")

	StartAnimation(caster, {duration=1, activity=ACT_DOTA_ATTACK_EVENT, rate=0.8})

	local particle = ParticleManager:CreateParticle("particles/econ/items/axe/ti9_jungle_axe/ti9_jungle_axe_culling_blade_cast_arc.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster) --STILL QUESTIONABLE
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    local particle = ParticleManager:CreateParticle("particles/econ/items/axe/ti9_jungle_axe/ti9_jungle_axe_culling_blade_boost_streak.vpcf", PATTACH_ABSORIGIN_FOLLOW, target) --STILL QUESTIONABLE
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    local particle = ParticleManager:CreateParticle("particles/econ/items/dragon_knight/dk_immortal_dragon/dragon_knight_dragon_tail_embers_iron_dragon.vpcf", PATTACH_ABSORIGIN_FOLLOW, target) --STILL QUESTIONABLE
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())

    DoDamage(caster, target , damage + stack * stackdamage, DAMAGE_TYPE_MAGICAL, 0, ability, false)

    target:AddNewModifier(caster, ability, "modifier_stunned", { Duration = stun })

    Timers:CreateTimer(0.1, function()
    	if not target:IsAlive() then 
    		ability:EndCooldown()
    		caster:RemoveModifierByName("modifier_beheader_cooldown")
    	end
    end)

end

modifier_beheader_cooldown = class({})

function modifier_beheader_cooldown:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_beheader_cooldown:IsHidden()
  return false
end

function modifier_beheader_cooldown:IsDebuff()
  return true
end

function modifier_beheader_cooldown:RemoveOnDeath()
  return false
end

function OnKHBeheaderHit(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local stun_duration = ability:GetSpecialValueFor("stun")
	local damage = ability:GetSpecialValueFor("damage")
	local stackdamage = ability:GetSpecialValueFor("damage_per_stack")

	if IsSpellBlocked(keys.target) then return end -- Linken effect checker

	local stack = caster:GetModifierStackCount("modifier_kinghassan_stack", caster) or 0

   	caster:EmitSound("KingHassan.Shine")

	StartAnimation(caster, {duration=1, activity=ACT_DOTA_ATTACK_EVENT, rate=0.8})

    local particle = ParticleManager:CreateParticle("particles/econ/items/axe/ti9_jungle_axe/ti9_jungle_axe_culling_blade_cast_arc.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster) --STILL QUESTIONABLE
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    local particle = ParticleManager:CreateParticle("particles/econ/items/axe/ti9_jungle_axe/ti9_jungle_axe_culling_blade_boost_streak.vpcf", PATTACH_ABSORIGIN_FOLLOW, target) --STILL QUESTIONABLE
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
    local particle = ParticleManager:CreateParticle("particles/econ/items/dragon_knight/dk_immortal_dragon/dragon_knight_dragon_tail_embers_iron_dragon.vpcf", PATTACH_ABSORIGIN_FOLLOW, target) --STILL QUESTIONABLE
    ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())

	if caster.IsBoundaryAcquired then
    	DoDamage(caster, target , damage + stack * stackdamage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	else
   	 	DoDamage(caster, target , damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	end

	Timers:CreateTimer(0.2, function()
		target:AddNewModifier(caster, ability, "modifier_stunned", { Duration = stun_duration })
	end)

end

function OnKHAmbushStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local fade_delay = ability:GetSpecialValueFor("fade_delay")

    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze_column.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)   
    ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin()) 
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_dragon_knight/dragon_knight_loadout.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin())
    caster:EmitSound("KingHassan.WSFX")

	--Timers:CreateTimer(fade_delay, function()
		if caster:IsAlive() then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_ambush", {})
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_ambush_think", {})
		end
	--end)
end

function OnAmbushWindow(keys)
	local caster = keys.caster
	if caster.IsPresenceAcquired then
		caster:SwapAbilities(caster.QSkill, "kinghassan_death_arrival_upgrade", false, true)
	else
		caster:SwapAbilities(caster.QSkill, "kinghassan_death_arrival", false, true)
	end
end

function OnAmbushBroken(keys)
	local caster = keys.caster

	if caster.IsPresenceAcquired then
		caster:SwapAbilities("kinghassan_death_arrival_upgrade" , caster.QSkill, false, true)
	else
		caster:SwapAbilities("kinghassan_death_arrival", caster.QSkill, false, true)
	end
end

function OnAmbushDeath(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_ambush")
	caster:RemoveModifierByName("modifier_ambush_think")
end

function OnKHArrival(keys)
	local caster = keys.caster
    local ability = keys.ability
    keys.targetpoint = ability:GetCursorPosition()

    caster:RemoveModifierByName("modifier_ambush")
	caster:RemoveModifierByName("modifier_ambush_think")

	OnKHBlink(keys)

    --[[if caster.IsPresenceAcquired then 
    	if target == nil then 
    		keys.targetpoint = ability:GetCursorPosition()
    		OnKHBlink(keys)
    	else
    		local range = ability:GetSpecialValueFor("range")
    		local damage = ability:GetSpecialValueFor("damage")
    		local stun = ability:GetSpecialValueFor("stun")
    		if (caster:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() < range then 
    			caster:EmitSound("Hero_EmberSpirit.FireRemnant.Cast")
    			local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
				caster:SetAbsOrigin(target:GetAbsOrigin() - diff*100) 
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
				DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, ability, false)
				target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun})
			else
				keys.targetpoint = target:GetAbsOrigin()
				OnKHBlink(keys)
			end
    	end
    else
    	keys.targetpoint = ability:GetCursorPosition()
    	OnKHBlink(keys)
    end]]
end

function OnKHBlink(keys)
    local hCaster = keys.caster
    local ability = keys.ability
    local targetpoint = keys.targetpoint



    local particle = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/pa_crimson_witness_2021/pa_crimson_witness_blur_ambient_fleks.vpcf", PATTACH_ABSORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControl(particle, 3, hCaster:GetAbsOrigin())
    local particle = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_death_black_steam.vpcf", PATTACH_ABSORIGIN_FOLLOW, hCaster)
    ParticleManager:SetParticleControl(particle, 3, hCaster:GetAbsOrigin())

    hCaster:EmitSound("Hero_EmberSpirit.FireRemnant.Cast")
    local tParams = {
        sInEffect = "particles/units/heroes/hero_dragon_knight/dragon_knight_loadout.vpcf",   --NAGASIREN MIRROR IMAGE AND BLACKFOGS
        sOutEffect = "particles/units/heroes/hero_dragon_knight/dragon_knight_loadout.vpcf"
    }

	local fRange = ability:GetSpecialValueFor("range")
 	AbilityBlink(hCaster,targetpoint, fRange, tParams)


	Timers:CreateTimer( 0.1, function()
    	local particle = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/pa_crimson_witness_2021/pa_crimson_witness_blur_ambient_fleks.vpcf", PATTACH_ABSORIGIN_FOLLOW, hCaster)
    	ParticleManager:SetParticleControl(particle, 3, hCaster:GetAbsOrigin())
    	local particle = ParticleManager:CreateParticle("particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_death_black_steam.vpcf", PATTACH_ABSORIGIN_FOLLOW, hCsaster)
    	ParticleManager:SetParticleControl(particle, 3, hCaster:GetAbsOrigin())
	end
	)
end

function OnAzraelCast(keys)

	local caster = keys.caster
	local ability = keys.ability
	local targetPoint = ability:GetCursorPosition()
	local width = ability:GetSpecialValueFor("width")
	local cast_delay = ability:GetSpecialValueFor("cast_delay")
	local range = ability:GetSpecialValueFor("length")
	local speed = ability:GetSpecialValueFor("speed")

	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 1.5)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_azrael_cast", {})
    caster:EmitSound("KingHassan.Azrael")

	StartAnimation(caster, {duration=1.7, activity=ACT_DOTA_ATTACK, rate=0.60})

	local azrael = 
	{
		Ability = keys.ability,
        EffectName = "",
        iMoveSpeed = 9999,
        vSpawnOrigin = caster:GetOrigin(),
        fDistance = range - width + 50,
        fStartRadius = width,
        fEndRadius = width,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        fExpireTime = GameRules:GetGameTime() + 3.0,
		bDeleteOnHit = false,
		vVelocity = caster:GetForwardVector() * 9999
	}

	Timers:CreateTimer(0.35, function()
	FreezeAnimation(caster,0.8)
	end)

    local particle = ParticleManager:CreateParticle("particles/kinghassan/azrael/hassanultarea.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, targetPoint + Vector(0,0,50))

	Timers:CreateTimer( cast_delay - 0.05, function()
		UnfreezeAnimation(caster)
		if caster:IsAlive() then
			azrael.vSpawnOrigin = caster:GetAbsOrigin() 
			azrael.vVelocity = caster:GetForwardVector() * speed
			local projectile = ProjectileManager:CreateLinearProjectile(azrael)
			ParticleManager:SetParticleControl(projectile, 2, GetRotationPoint(caster:GetAbsOrigin(), range ,caster:GetAnglesAsVector().x))

			ScreenShake(caster:GetOrigin(), 5, 0.1, 2, 20000, 0, true)

				
					-- Create Particle for projectile
			local casterFacing = caster:GetForwardVector()
			local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
			dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
			dummy:SetForwardVector(casterFacing)
					
			local excalFxIndex = ParticleManager:CreateParticle( "particles/kinghassan/azrael/hassanult.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, dummy )
			ParticleManager:SetParticleControl(excalFxIndex, 4, Vector(width * 4,6,4))
			caster:EmitSound("KingHassan.AzraelCut")

			Timers:CreateTimer( 0.5, function()
				ParticleManager:DestroyParticle( excalFxIndex, false )
				ParticleManager:ReleaseParticleIndex( excalFxIndex )
				Timers:CreateTimer( 0.2, function()
					if IsValidEntity(dummy) then
						dummy:RemoveSelf()
					end
					return nil
				end)
				return nil
			end)
			return 
		end
		return nil
	end)
end

function OnAzraelHit(keys)
	local caster = keys.caster
	local target = keys.target 
	local ability = keys.ability 
	local stun_duration = ability:GetSpecialValueFor("stun")
	local damage = ability:GetSpecialValueFor("damage")

	if not IsValidEntity(target) or target:IsNull() then return end

	if target == nil then return end

	if caster.IsOldManOfTheMountainAcquired then
		local bonus_agi = ability:GetSpecialValueFor("bonus_agi") * caster:GetAgility()
		DoDamage(caster, target, bonus_agi , DAMAGE_TYPE_PURE, 0, ability, false) 			
	end

	DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, ability, false)
	target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun_duration})
end