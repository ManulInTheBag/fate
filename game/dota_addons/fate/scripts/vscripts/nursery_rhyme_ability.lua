LinkLuaModifier("modifier_qgg_oracle", "abilities/nr/modifier_qgg_oracle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_qgg_oracle_aura", "abilities/nr/modifier_qgg_oracle_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rhyme_flying_book", "abilities/nursery_rhyme/modifiers/modifier_flying_book.lua", LUA_MODIFIER_MOTION_NONE)

CCTable = {
	"silenced",
	"stunned",
	--"revoked",
	"locked",
	"rooted",
	"disarmed",
	"modifier_white_queens_enigma_dot",
	-- below are Dota 2 base modifiers that I might have been using previously
	"modifier_stunned",
	"modifier_disarmed",
	"modifier_silenced",
	--"modifier_enkidu_hold"
}

-- stores CC duration in script scope
CCDurationTable = {
	stunned = 0,
	silenced = 0,
	revoked = 0,
	locked = 0,
	rooted = 0,
	disarmed = 0
}

itemModifiers = {"modifier_b_scroll","modifier_a_scroll","modifier_healing_scroll","modifier_speed_gem","modifier_berserk_scroll","item_pot_regen"}

function OnShapeShiftStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local targetPoint = keys.ability:GetCursorPosition()
	local duration = keys.Duration
	local pid = caster:GetPlayerID()

	-- create illusion
	local illusion = CreateUnitByName(caster:GetUnitName(), caster:GetAbsOrigin(), true, caster, nil, caster:GetTeamNumber())
	illusion:SetPlayerID(pid) 

	illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = 0, incoming_damage = 100 })
	illusion:AddNewModifier(caster, caster:FindAbilityByName("nursery_rhyme_queens_glass_game"), "modifier_rhyme_flying_book", {})
	illusion:MakeIllusion()
	illusion:SetControllableByPlayer(pid, true)
	ability:ApplyDataDrivenModifier(caster, illusion, "modifier_nursery_rhyme_shapeshift_clone", {})
	caster.ShapeShiftIllusion = illusion
	caster.bIsSwapUsed = false 
	caster.ShapeShiftDest = targetPoint
	caster:SwapAbilities("nursery_rhyme_shapeshift", "nursery_rhyme_shapeshift_swap", false, true)

	--illusion:SetControllableByPlayer(pid, true)
	--print(illusion:GetOwner())
	illusion:SetOwner(caster) -- Attempt to change color of illusion on minimap but failed, worked for ZC but not for this. Wtf.
	--print(illusion:GetOwner():GetName())
	--print(illusion:IsClone(),illusion:IsConsideredHero(),illusion:IsControllableByAnyPlayer(),illusion:IsCreature(),illusion:IsCreep(),illusion:IsHero(),illusion:IsIllusion(),illusion:IsNeutralUnitType(),illusion:IsOwnedByAnyPlayer(),illusion:IsRealHero(),illusion:IsSummoned())

	illusion:MoveToPosition(targetPoint)
	
	--start of mimic function (work in progress)
	for i=1, (caster:GetLevel()-1) do
		illusion:HeroLevelUp(false)
	end

	for i = 1, #itemModifiers do
		if caster:HasModifier(itemModifiers[i]) then
			ability:ApplyDataDrivenModifier(caster, illusion, itemModifiers[i], {duration = caster:FindModifierByName(itemModifiers[i]):GetRemainingTime()})		
		end
	end

	for itemSlot=0,5 do
		local item = caster:GetItemInSlot(itemSlot)
		if item ~= nil then
			local itemName = item:GetName()
			local newItem = CreateItem(itemName, illusion, illusion)
			local currCharge = item:GetCurrentCharges()
			--illusion:AddItem(newItem)
			CreateItemAtSlot(illusion, itemName, itemSlot, currCharge, 1, 1)
		end
	end

	for abilitySlot=0,10 do
		if abilitySlot == 9 then goto skip9 end --skip presence_detection_passive
		local abilityCopy = caster:GetAbilityByIndex(abilitySlot)
		if abilityCopy ~= nil then 
			local abilityLevel = abilityCopy:GetLevel()
			local abilityName = abilityCopy:GetAbilityName()
			local illusionAbility = illusion:FindAbilityByName(abilityName)
			illusionAbility:SetLevel(abilityLevel)
		end
		::skip9::
	end

	illusion:SetBaseStrength(caster:GetBaseStrength())
	illusion:SetBaseIntellect(caster:GetBaseIntellect())
	illusion:SetBaseAgility(caster:GetBaseAgility())
	illusion:ModifyAgility(0) --do not remove this seemingly useless line; removing will result in -20 agi and I have no freaking idea why

	illusion:SetMaxHealth(caster:GetMaxHealth())
	illusion:SetHealth(caster:GetHealth())
	-- Only GetMaxMana but no SetMaxMana wth valve
	illusion:SetMana(caster:GetMana())

	illusion:SetBaseHealthRegen(caster:GetHealthRegen() - caster:GetStrength() * (0.03)) -- 0.03 being dota2's base hpregen/str
	illusion:SetBaseManaRegen(caster:GetManaRegen() + caster:GetIntellect() * (0.25 - 0.04)) -- 0.25 being fate's mpregen/int, 0.04 being dota2's
	illusion:SetPhysicalArmorBaseValue(caster:GetPhysicalArmorBaseValue()) -- 1/7 being dota2's base armor/agi

	illusion:SetBaseMoveSpeed(caster:GetBaseMoveSpeed()) --illusion shows 300 movespeed but actual movespeed is mimicked over.
	-- stuff not done: Setting illusion's max mana, bonus stats from leveling strAgiInt+2 
	-- end mimic

	local cloneFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_terrorblade/terrorblade_mirror_image.vpcf", PATTACH_CUSTOMORIGIN, nil );
	ParticleManager:SetParticleControl( cloneFx, 0, caster:GetAbsOrigin())
	Timers:CreateTimer( 0.7, function()
		ParticleManager:DestroyParticle( cloneFx, false )
		ParticleManager:ReleaseParticleIndex( cloneFx )
	end)
	caster:EmitSound("Hero_Terrorblade.ConjureImage")
	-- enable sub-ability that swaps position 
end

-- check if there is a valid target around clone
function OnShapeShiftEnd(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	caster:RemoveModifierByName("modifier_phased")
    EmitSoundOnLocationWithCaster(target:GetAbsOrigin(), "Hero_Terrorblade.Metamorphosis", target)
	local cloneKillFx = ParticleManager:CreateParticle( "particles/generic_gameplay/illusion_killed.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl( cloneKillFx, 0, target:GetAbsOrigin()+Vector(0,0,100) )
	local explosionFx = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_thunder_strike_bolt.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(explosionFx, 0, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(explosionFx, 1, target:GetAbsOrigin())
    ParticleManager:SetParticleControl(explosionFx, 2, target:GetAbsOrigin())
    caster:SwapAbilities("nursery_rhyme_shapeshift", "nursery_rhyme_shapeshift_swap", true, false)
end

LinkLuaModifier("modifier_white_queen_slow", "abilities/nursery_rhyme/modifiers/modifier_white_queen_slow", LUA_MODIFIER_MOTION_NONE)

--[[
Iterative function that shoots chain lightning to eligible target until bounce > count
]]
--[[
slow applier when attribute is acquired
]]
function OnGlassGameStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local radius = keys.Radius
	local instantHeal = keys.InstantHeal
	local instantHealPct = keys.InstantHealPct

	NRCheckCombo(caster, ability)

	--[[if caster.bIsQGGImproved then
		instantHeal = instantHeal + caster:GetIntellect() * 4 
		instantHealPct = 20
	end]]

	-- give caster heal aura modifier
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_queens_glass_game", {})
	--[[if caster.bIsQGGImproved then
		--print("applied aura")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_queens_glass_game_link_aura", {})
		Timers:CreateTimer(0.6, function()
			if caster:IsChanneling() then
				caster:AddNewModifier(caster, ability, "modifier_qgg_oracle_aura", { Duration = -1 })
				ParticleManager:SetParticleControl(caster.aoeFx2, 3, Vector(0,0,0))
			end
		end)
	end]]

	local cooldown_reduc = ability:GetSpecialValueFor("cooldown_reduc")

	-- find team units in radius and grant them instant heal
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		--local missingHealth = (v:GetMaxHealth() - v:GetHealth()) * instantHealPct/100
		local totalHeal = instantHeal
		--[[if caster.bIsQGGImproved then
			v:GiveMana(totalHeal / 2)
		end]]
		v:ApplyHeal(totalHeal, caster)

		if v ~= caster and v:IsHero() then 
			for j=0, 5 do 
				local ability = v:GetAbilityByIndex(j)
				if ability ~= nil then
					rCooldown = ability:GetCooldownTimeRemaining()
					ability:EndCooldown()
					ability:StartCooldown(rCooldown - cooldown_reduc)
				else 
					break
				end
			end
		end

		local healFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_chen/chen_hand_of_god.vpcf", PATTACH_CUSTOMORIGIN, nil );
		ParticleManager:SetParticleControl( healFx, 0, v:GetAbsOrigin() + Vector(0,0,50))
		v:EmitSound("Item.GuardianGreaves.Target")
	end

	local shineFx = ParticleManager:CreateParticle( "particles/items_fx/aegis_respawn_aegis_starfall.vpcf", PATTACH_CUSTOMORIGIN, nil );
	ParticleManager:SetParticleControl( shineFx, 0, caster:GetAbsOrigin())
	EmitGlobalSound("NR.Chronosphere")
	--EmitGlobalSound("NR.GlassGame.Begin")
	caster:EmitSound("NR.Tick")
	--[[local SacFx = ParticleManager:CreateParticle("particles/custom/caster/sacrifice/caster_sacrifice_indicator.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( SacFx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl( SacFx, 1, Vector(radius,0,0))]]

	--[[if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if caster:FindAbilityByName("nursery_rhyme_story_for_somebodys_sake"):IsCooldownReady() 
			and caster:GetAbilityByIndex(4):GetName() == "nursery_rhyme_nameless_forest"
			and not caster:HasModifier("modifier_alice_tea_party_cd") 
			and (GameRules:GetGameTime() < 60 + _G.RoundStartTime) then
			caster:SwapAbilities("nursery_rhyme_nameless_forest", "nursery_rhyme_story_for_somebodys_sake", false, true)
			Timers:CreateTimer({
				endTime = 2,
				callback = function()
					caster:SwapAbilities("nursery_rhyme_nameless_forest", "nursery_rhyme_story_for_somebodys_sake", true, false)
				end
			})
		end
	end]]
end

function OnGlassGameEnd(keys)
	local caster = keys.caster
	local ability = keys.ability

	caster:RemoveModifierByName("modifier_queens_glass_game")
	if caster.bIsQGGImproved then
		caster:RemoveModifierByName("modifier_queens_glass_game_link_aura")
		caster:RemoveModifierByName("modifier_qgg_oracle_aura")
	end
	caster:StopSound("NR.Tick")
end

function OnGlassGameThink(keys)
	local caster = keys.caster
	local ability = keys.ability
	local manaCost = keys.ManaCost * caster:GetMaxMana() / 100
	
	--print(manaCost)
	if  manaCost > caster:GetMana() then 
		caster:Stop() -- stop channeling
	else
		caster:SetMana(caster:GetMana() - manaCost)
	end
end

function CreateGlassGameEffect(keys)
	local caster = keys.caster
	local ability = keys.ability

	caster.aoeFx = ParticleManager:CreateParticle( "particles/custom/nursery_rhyme/queens_glass_game/queens_glass_game_aoe.vpcf", PATTACH_CUSTOMORIGIN, nil );
	ParticleManager:SetParticleControl( caster.aoeFx, 0, caster:GetAbsOrigin())
	caster.aoeFx2 = ParticleManager:CreateParticle( "particles/custom/nursery_rhyme/queens_glass_game/queens_glass_game_bookswirl.vpcf", PATTACH_CUSTOMORIGIN, nil );
	ParticleManager:SetParticleControl( caster.aoeFx2, 1, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(caster.aoeFx2, 3, Vector(1,1,1)) --allow rotations and gravity
end

function RemoveGlassGameEffect(keys)
	local caster = keys.caster
	local ability = keys.ability

	ParticleManager:DestroyParticle( caster.aoeFx, false )
	ParticleManager:ReleaseParticleIndex( caster.aoeFx )
	caster.aoeFx = nil
		
	ParticleManager:DestroyParticle( caster.aoeFx2, false )
	ParticleManager:ReleaseParticleIndex( caster.aoeFx2 )
	caster.aoeFx2 = nil
end


function OnGlassGameAuraApplied(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	if not target.reincarnation_particle then target.reincarnation_particle = ParticleManager:CreateParticle("particles/custom/berserker/reincarnation/regen_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, target) end
end

function OnGlassGameAuraEnd(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	ParticleManager:DestroyParticle(target.reincarnation_particle, false)
	target.reincarnation_particle = nil
end

--[[
Round finish mechanics 
]]
function PingLocationForEnemies(keys)
	local caster = keys.caster
	local ability = keys.ability

	--[[if _G.LaPucelleActivated == true then
	end]]
	if caster.nNRComboQuoteCount == 3 then
		GameRules:SendCustomMessage("<font color='#FF0000'>This story will go on forever.</font>", 0, 0)
		--EmitGlobalSound("Hero_Wisp.Tether.Stop")
		EmitGlobalSound("Nursery_Rhyme_Combo_1")
		local blueScreenFx = ParticleManager:CreateParticle("particles/custom/screen_lightblue_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
	elseif caster.nNRComboQuoteCount == 4 then
		GameRules:SendCustomMessage("<font color='#FF0000'>As long as the slender fingers return to the first page,</font>", 0, 0)
		--EmitGlobalSound("Hero_Wisp.Tether.Stop")
		EmitGlobalSound("Nursery_Rhyme_Combo_2")
		local blueScreenFx = ParticleManager:CreateParticle("particles/custom/screen_lightblue_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
	elseif caster.nNRComboQuoteCount == 5 then
		GameRules:SendCustomMessage("<font color='#FF0000'>As if picking up the next volume.</font>", 0, 0)
		--EmitGlobalSound("Hero_Wisp.Tether.Stop")
		EmitGlobalSound("Nursery_Rhyme_Combo_3")
		local blueScreenFx = ParticleManager:CreateParticle("particles/custom/screen_lightblue_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
	end
	caster.nNRComboQuoteCount = caster.nNRComboQuoteCount+1

    LoopOverPlayers(function(player, playerID, playerHero)
    	if playerHero:GetTeamNumber() ~= caster:GetTeamNumber() and player and playerHero then
    		MinimapEvent( playerHero:GetTeamNumber(), playerHero, caster:GetAbsOrigin().x, caster:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING, 2 )
    	end
    end)	
end

function NRCheckCombo(caster, ability)
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if ability == caster:FindAbilityByName("nursery_rhyme_queens_glass_game") and caster:FindAbilityByName("nursery_rhyme_story_for_somebodys_sake"):IsCooldownReady() and (GameRules:GetGameTime() < 60 + _G.RoundStartTime) then
			caster:SwapAbilities("nursery_rhyme_queens_glass_game", "nursery_rhyme_story_for_somebodys_sake", false, true)
			Timers:CreateTimer({
				endTime = 2,
				callback = function()
				caster:SwapAbilities("nursery_rhyme_queens_glass_game", "nursery_rhyme_story_for_somebodys_sake", true, false)
			end
			})
		end
	end
end


--[[
function OnShapeShiftStart(keys)
	local caster = keys.caster
	local ability = keys.ability
end

function OnShapeShiftStart(keys)
	local caster = keys.caster
	local ability = keys.ability
end]]

--[[
        "DOTA_Tooltip_Ability_nursery_rhyme_attribute_forever_together"		"Forever Together"
        "DOTA_Tooltip_Ability_nursery_rhyme_attribute_forever_together_Description"		"I Am You, and You Are Me causes target to be slowed 
        and take damage continuously if it is looking away from its doppelganger. Also, improves Shapeshift's max duration and slow, and reduces its cooldown."
        ]]

-- Восстановлено: DD-блок nursery_rhyme_white_queens_enigma зовёт эти три
-- функции через RunScript, а sweep_monoliths счёл их без потребителей.
function OnEnigmaStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local targetPoint = keys.ability:GetCursorPosition()

	local enigmaProjectile = 
	{
		Ability = ability,
        EffectName = "particles/units/heroes/hero_tusk/tusk_ice_shards_projectile.vpcf",
        iMoveSpeed = 1500,
        vSpawnOrigin = caster:GetAbsOrigin(),
        fDistance = 900,
        fStartRadius = 200,
        fEndRadius = 200,
        Source = caster,
        bHasFrontalCone = true,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
        fExpireTime = GameRules:GetGameTime() + 2.0,
		bDeleteOnHit = true,
		vVelocity = caster:GetForwardVector() * 1500,
		bProvidesVision = true,
		iVisionTeamNumber = caster:GetTeamNumber(),
		iVisionRadius = 300
	}	

	local projectile = ProjectileManager:CreateLinearProjectile(enigmaProjectile)
	caster:EmitSound("Hero_Tusk.IceShards.Projectile")
	--caster:EmitSound("Hero_Tusk.IceShards.Cast")
	Timers:CreateTimer(1.0, function()
		caster:StopSound("Hero_Tusk.IceShards.Projectile")
	end)
end

function OnEnigmaHit(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local BaseStunDuration = keys.DefaultStunDuration
	local NumOfCC = keys.CCNum
	
	local allEffects = {
		"silenced",
		"stunned",
		"locked",
		"rooted",
		"disarmed"
	}

	local effects = {
		"silenced",
		"stunned",
		"locked",
		"rooted",
		"disarmed"
	}

	for i=#effects, 1, -1 do
		print(target:HasModifier(effects[i]))
		if target:HasModifier(effects[i]) then
			table.remove(effects, i)
		end
	end

	local tableToUse = effects
	for i=1, NumOfCC do
		if #tableToUse == 0 then
			tableToUse = allEffects
			if not target:HasModifier("modifier_white_queens_enigma_checker") then
				--giveUnitDataDrivenModifier(caster, target, "revoked", keys.revoked)
				ability:ApplyDataDrivenModifier(caster, target, "modifier_white_queens_enigma_checker", {})
			end
		end
		local index = math.random(#tableToUse)
		local effect = tableToUse[index]
		giveUnitDataDrivenModifier(caster, target, effect, keys[effect])
		table.remove(tableToUse, index)
	end

	--target:AddNewModifier(caster, ability, "modifier_stunned", { Duration = 0.5 })
	--target:AddNewModifier(caster, ability, "modifier_white_queen_slow",  { Duration = 5 })
	--giveUnitDataDrivenModifier(caster, target, "rooted", ability:GetSpecialValueFor("root_duration"))
	--giveUnitDataDrivenModifier(caster, target, "locked", ability:GetSpecialValueFor("lock_duration"))

	--ability:ApplyDataDrivenModifier(caster, target, "modifier_white_queens_enigma_dot", {})
	SpawnAttachedVisionDummy(caster, target, 300, 3, false)
	DoDamage(caster, target, ability:GetSpecialValueFor("damage"), DAMAGE_TYPE_PHYSICAL, 0, ability, false)

	local iceFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_winter_wyvern/wyvern_cold_embrace_buff_model.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl( iceFx, 0, target:GetAbsOrigin() + Vector(0,0,100) )
	Timers:CreateTimer(BaseStunDuration, function()
		ParticleManager:DestroyParticle( iceFx, false )
		ParticleManager:ReleaseParticleIndex( iceFx )
		return nil
	end)
	target:EmitSound("Hero_Tusk.IceShards")
end

function OnEnimgaTick(keys)
	--DoDamage(keys.caster, keys.target, keys.Damage/8/100 * keys.target:GetMaxHealth(), DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
end
