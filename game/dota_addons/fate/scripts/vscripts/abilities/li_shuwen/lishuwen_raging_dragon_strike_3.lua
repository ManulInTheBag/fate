-- lishuwen_raging_dragon_strike_3 — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/li_shuwen/li_shuwen_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lishuwen_raging_dragon_strike_3 = class({})

LinkLuaModifier("modifier_raging_dragon_strike_3_anim", "abilities/li_shuwen/lishuwen_raging_dragon_strike_3", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/lishuwen_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDragonStrike3Start, OnDragonStrike1ProjectileHit, ApplyMarkOfFatality

OnDragonStrike3Start = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local count = keys.Count
	--GrantCosmicOrbitResist(caster)
	caster.bIsCurrentDSCycleFinished = true
	Timers:RemoveTimer('raging_dragon_timer')
	caster:SwapAbilities("lishuwen_tiger_strike","lishuwen_raging_dragon_strike_3", true, false) 
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

	if #targets == 0 then 
    		local abil = caster:FindAbilityByName("lishuwen_raging_dragon_strike")
    		ReduceCooldown(abil, abil:GetCooldown(1)*0.75)
    		caster:RemoveModifierByName("modifier_raging_dragon_strike_cooldown")
    		caster:AddNewModifier(caster, abil, "modifier_raging_dragon_strike_cooldown", {duration = abil:GetCooldown(abil:GetLevel())*0.25})
		local masterabil = caster.MasterUnit2:FindAbilityByName("lishuwen_raging_dragon_strike")
		masterabil:EndCooldown()
		masterabil:StartCooldown(masterabil:GetCooldown(1)*0.25)    
		return 
	end

	keys.Damage = keys.Damage + caster:GetAverageTrueAttackDamage(caster) * 0.2

	print (keys.Damage)

	local endpoint = nil
	local counter = 0

	--[[if caster.bIsFuriousChainAcquired then
		keys.Damage = keys.Damage + caster:GetAgility() * ATTR_AGI_RATIO
		GrantFuriousChainBuff(caster) 
	end]]
	-- knock them up and create counter
	for k,v in pairs(targets) do
		v.nDragonStrikeComboCount = 0
		ApplyAirborne(caster, v, keys.KnockupDuration)
	end

	giveUnitDataDrivenModifier(keys.caster, keys.caster, "jump_pause", keys.KnockupDuration)

	local dummy = CreateUnitByName("godhand_res_locator", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
	dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	dummy:AddNewModifier(caster, nil, "modifier_phased", {duration=2})
	dummy:AddNewModifier(caster, nil, "modifier_kill", {duration=2})

	Timers:CreateTimer(0.2, function()
		if counter == 15 then 
			local position = caster:GetAbsOrigin()
			local dummyPosition = dummy:GetAbsOrigin()
			if not IsInSameRealm(position, dummyPosition) then
				position = dummyPosition
			end
			FindClearSpaceForUnit(caster, position, true)
			return 
		end

		local target = nil

        for i=1, 50 do
			local curIndex = math.random(#targets)
			if targets[curIndex].nDragonStrikeComboCount < 15 then
				targets[curIndex].nDragonStrikeComboCount = targets[curIndex].nDragonStrikeComboCount + 1
				target = targets[curIndex]
				break
			end
		end
		--[[for k,v in pairs(targets) do
			if v.nDragonStrikeComboCount < 8 then
				v.nDragonStrikeComboCount = v.nDragonStrikeComboCount + 1
				target = v
			end
		end]]
		
		if target ~= nil then
			--print(target:GetName() .. counter)
			DoCompositeDamage(caster, target, keys.Damage, DAMAGE_TYPE_COMPOSITE, 0, keys.ability, false)
			ApplyMarkOfFatality(caster, target)
			caster:FindAbilityByName("lishuwen_no_second_strike"):AddShock(target, 1)
		end



		--newpoint = Vector(startpoint.x + RandomInt(1,600), startpoint.y + RandomInt(1, 600), startpoint.y+500)
		caster:AddNewModifier(caster, ability, "modifier_raging_dragon_strike_3_anim", {})
		local currentpoint = caster:GetAbsOrigin()
		local newpoint = currentpoint+vectorsV2[counter+1]*0.5
		caster:SetAbsOrigin(newpoint)
		local trailFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_ember_spirit/ember_spirit_sleightoffist_trail.vpcf", PATTACH_CUSTOMORIGIN, caster )
		ParticleManager:SetParticleControl( trailFx, 1, currentpoint )
		ParticleManager:SetParticleControl( trailFx, 0, newpoint )

		if target ~= nil then
		    local groundFx = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_f_fallback_low.vpcf", PATTACH_ABSORIGIN, target )
		    ParticleManager:SetParticleControl( groundFx, 1, target:GetAbsOrigin())
	   	end
		caster:EmitSound("Hero_Tusk.WalrusPunch.Target")
		counter = counter + 1
		return 0.08
	end)

	caster:EmitSound("Hero_Earthshaker.Pick")
	--EmitGlobalSound("Lishuwen.Shout")
	local soundQueue = math.random(1,3)

	if caster:HasModifier("modifier_berserk") then
		EmitGlobalSound("RYOOH")
		EmitZlodemonTrueSoundEveryone("moskes_li_combo_bers")
	else
		EmitGlobalSound("Lishuwen_Combo_3_" .. soundQueue)
		EmitZlodemonTrueSoundEveryone("moskes_li_combo".. math.random(1,2))
	end
	LoopOverPlayers(function(player, playerID, playerHero)
    	--print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
        	-- apply legion horn vsnd on their client
        	CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Pchela"})
        	--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)

    local groundFx1 = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_ABSORIGIN, caster )
    ParticleManager:SetParticleControl( groundFx1, 1, caster:GetAbsOrigin())
    local groundFx2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_ABSORIGIN, caster )
    ParticleManager:SetParticleControl( groundFx2, 1, caster:GetAbsOrigin())
    ParticleManager:SetParticleControlOrientation(groundFx1, 0, RandomVector(3), Vector(0,1,0), Vector(1,0,0))
    ParticleManager:SetParticleControlOrientation(groundFx2, 0, RandomVector(3), Vector(0,1,0), Vector(1,0,0))
    local firstStrikeFx = ParticleManager:CreateParticle("particles/custom/lishuwen/lishuwen_third_hit.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl( firstStrikeFx, 0, caster:GetAbsOrigin())
end

OnDragonStrike1ProjectileHit = function(keys)
	local caster = keys.caster
	local target = keys.target 
	table.insert(caster.targetTable,target)
end

ApplyMarkOfFatality = function(caster,target)
	local abil = caster:FindAbilityByName("lishuwen_martial_arts")

	SpawnAttachedVisionDummy(caster, target, abil:GetLevelSpecialValueFor("vision_radius", abil:GetLevel()-1 ), abil:GetLevelSpecialValueFor("duration", abil:GetLevel()-1 ), false)

	-- add new stack
	local currentStack = target:GetModifierStackCount("modifier_mark_of_fatality", abil)
	target:RemoveModifierByName("modifier_mark_of_fatality") 
	target:AddNewModifier(caster, abil, "modifier_mark_of_fatality", {}) 
	target:SetModifierStackCount("modifier_mark_of_fatality", abil, currentStack + 1)
end


function lishuwen_raging_dragon_strike_3:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: lishuwen_ability / OnDragonStrike3Start
	OnDragonStrike3Start({
		caster = caster,
		ability = self,
		target = caster,
		KnockupDuration = self:GetSpecialValueFor("third_strike_knockup_duration"),
		Damage = self:GetSpecialValueFor("third_strike_aerial_damage"),
		Count = self:GetSpecialValueFor("third_strike_aerial_hit_count"),
		SlamDamage = self:GetSpecialValueFor("third_strike_slam_damage")
	})
end

function lishuwen_raging_dragon_strike_3:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: lishuwen_ability / OnDragonStrike1ProjectileHit
	OnDragonStrike1ProjectileHit({ caster = caster, ability = self, target = target })
	return false
end

modifier_raging_dragon_strike_3_anim = class({})

function modifier_raging_dragon_strike_3_anim:IsHidden() return true end
function modifier_raging_dragon_strike_3_anim:GetOverrideAnimation() return ACT_DOTA_ATTACK_EVENT end

function modifier_raging_dragon_strike_3_anim:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}
end

function modifier_raging_dragon_strike_3_anim:GetOverrideAnimationRate()
	return 3.0
end

function modifier_raging_dragon_strike_3_anim:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.14" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.14, true)
	end
end

function modifier_raging_dragon_strike_3_anim:OnRefresh(kv)
	self:OnCreated(kv)
end
