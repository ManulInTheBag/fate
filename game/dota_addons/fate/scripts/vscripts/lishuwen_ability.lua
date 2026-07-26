ATTR_NSS_BONUS_DAMAGE = 150
ATTR_NSS_STACK_DAMAGE_PERCENTAGE = 10
ATTR_AGI_RATIO = 2.5
ATTR_MANA_REFUND = 200

LinkLuaModifier("modifier_berserk","abilities/lishuwen/modifiers/modifier_berserk", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_martial_arts_passive", "abilities/lishuwen/modifiers/modifier_martial_arts_passive", LUA_MODIFIER_MOTION_NONE)

function OnMartialStart(keys)
	local caster = keys.caster
	local target = keys.target
	local duration = keys.Duration
	if IsSpellBlocked(keys.target, caster) then return end -- Linken effect checker
	giveUnitDataDrivenModifier(caster, target, "silenced", duration)
	ApplyMarkOfFatality(caster, target)
	--[[if caster:GetName() == "npc_dota_hero_bloodseeker" then
		GrantCosmicOrbitResist(caster)
		if caster.bIsFuriousChainAcquired then
			GrantFuriousChainBuff(caster) 
		end
	end]]
    local pcMark = ParticleManager:CreateParticle("particles/econ/items/axe/axe_cinder/axe_cinder_battle_hunger_start.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
    ParticleManager:ReleaseParticleIndex(pcMark)
	target:EmitSound("Hero_Nightstalker.Void")
end

function ApplyMarkOfFatality(caster,target)
	local abil = caster:FindAbilityByName("lishuwen_martial_arts")

	SpawnAttachedVisionDummy(caster, target, abil:GetLevelSpecialValueFor("vision_radius", abil:GetLevel()-1 ), abil:GetLevelSpecialValueFor("duration", abil:GetLevel()-1 ), false)

	-- add new stack
	local currentStack = target:GetModifierStackCount("modifier_mark_of_fatality", abil)
	target:RemoveModifierByName("modifier_mark_of_fatality") 
	target:AddNewModifier(caster, abil, "modifier_mark_of_fatality", {}) 
	target:SetModifierStackCount("modifier_mark_of_fatality", abil, currentStack + 1)
end

function GrantFuriousChainBuff(caster)
	local abil = caster:FindAbilityByName("lishuwen_martial_arts")
	-- add new stack
	local currentStack = caster:GetModifierStackCount("modifier_furious_chain_buff", abil)
	caster:RemoveModifierByName("modifier_furious_chain_buff") 
	caster:AddNewModifier(caster, abil, "modifier_furious_chain_buff", {}) 
	caster:SetModifierStackCount("modifier_furious_chain_buff", abil, currentStack + 1)
end


function GrantCosmicOrbitResist(caster)
	return

	--[[local abil = caster:FindAbilityByName("lishuwen_cosmic_orbit")
	abil:ApplyDataDrivenModifier(caster, caster, "modifier_lishuwen_cosmic_orbit_momentary_resistance", {})
	caster:EmitSound("DOTA_Item.ArcaneBoots.Activate")]]
end

function OnBerserkStart(keys)
    local caster = keys.caster
    if caster.bIsDualClassAcquired ~= true then
        keys.ability:EndCooldown()
        SendErrorMessage(caster:GetPlayerOwnerID(), "#Attribute_Not_Earned")
        return
    end

    if IsRevoked(caster) then
        keys.ability:EndCooldown()
        SendErrorMessage(caster:GetPlayerOwnerID(), "#Revoked_Error")
        return
    end
    --[[GrantCosmicOrbitResist(caster)
	if caster.bIsFuriousChainAcquired then
		GrantFuriousChainBuff(caster) 
	end]]
   	caster:AddNewModifier(caster, keys.ability, "modifier_berserk", {Duration = keys.Duration})
    HardCleanse(caster)
    caster:EmitSound("DOTA_Item.MaskOfMadness.Activate")
    local dispel = ParticleManager:CreateParticle( "particles/units/heroes/hero_abaddon/abaddon_death_coil_explosion.vpcf", PATTACH_ABSORIGIN, caster )
    ParticleManager:SetParticleControl( dispel, 1, caster:GetAbsOrigin())
    -- Destroy particle after delay
    Timers:CreateTimer( 2.0, function()
        ParticleManager:DestroyParticle( dispel, false )
        ParticleManager:ReleaseParticleIndex( dispel )
    end)
end


function OnCosmicOrbitStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	GrantCosmicOrbitResist(caster)
	LishuwenCheckCombo(caster, ability)
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_lishuwen_cosmic_orbit", {})
	caster:EmitSound("Hero_Sven.WarCry")
end

function OnCosmicOrbitAttackLanded(keys)
	local caster = keys.caster
	local ability = keys.ability
	if caster.nBaseAttackCount == nil then
		caster.nBaseAttackCount = 0
	end


	if caster.nBaseAttackCount == 3 then
		if not caster:HasModifier("modifier_lishuwen_cosmic_orbit_silence_cooldown") then
			keys.Duration = 1.5
			OnMartialStart(keys)
			caster.nBaseAttackCount = 0
			keys.ability:ApplyDataDrivenModifier(caster, caster, "modifier_lishuwen_cosmic_orbit_silence_cooldown", {}) 
		end
	else
		caster.nBaseAttackCount = caster.nBaseAttackCount + 1
	end
end

function OnNSSCastStart(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if target:GetName() == "npc_dota_ward_base" then
		caster:Interrupt()
		return
	end
    local windupFx = ParticleManager:CreateParticle( "particles/custom/lishuwen/lishuwen_no_second_strike_windup.vpcf", PATTACH_ABSORIGIN, caster )
    ParticleManager:SetParticleControl( windupFx, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl( windupFx, 3, caster:GetAbsOrigin())

    Timers:CreateTimer(keys.CastDelay, function()
		ParticleManager:DestroyParticle( windupFx, false )
		ParticleManager:ReleaseParticleIndex( windupFx )
    end)
end

function OnNSSStart(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	caster.ProcDamage = keys.ProcDamage
	caster.ProcStunDuration = keys.ProcStunDuration
	target.IsNSSProcReady = true
	if caster:HasModifier("modifier_berserk") then
		keys.ability:EndCooldown()
		caster:SetMana(caster:GetMana()+keys.ability:GetManaCost(1))
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Cannot_Be_Cast_Now")
		return			
	end
	if IsSpellBlocked(keys.target, caster) then return end

	GrantCosmicOrbitResist(caster)
	if caster.bIsMartialArtsImproved then
		ApplyMarkOfFatality(caster, target)
	end
	-- do damage and apply CC
	local damage = keys.Damage
	if caster.bIsCirculatoryShockAcquired then
		damage = damage + ATTR_NSS_BONUS_DAMAGE
	end
	if caster.bIsFuriousChainAcquired then
		damage = damage + caster:GetAgility() * ATTR_AGI_RATIO
		GrantFuriousChainBuff(caster) 
		if target:HasModifier("modifier_mark_of_fatality") then
			caster:SetMana(caster:GetMana()+ATTR_MANA_REFUND)
		end
	end
	DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, 0, keys.ability, false)
	target:AddNewModifier(caster, target, "modifier_stunned", {Duration = keys.StunDuration})
	
	if caster.bIsCirculatoryShockAcquired then
		target:AddNewModifier(caster, target, "modifier_silence", {Duration = keys.SilenceDuration})
	end
	ability:ApplyDataDrivenModifier(caster, target, "modifier_no_second_strike_delay_indicator", {})
	-- apply delay indicator

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_no_second_strike_anim", {})
	EmitGlobalSound("Lishuwen.NoSecondStrike")
    local groundFx1 = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_ABSORIGIN, target )
    ParticleManager:SetParticleControl( groundFx1, 1, target:GetAbsOrigin())
    local groundFx2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_fallback_mid.vpcf", PATTACH_ABSORIGIN, target )
    ParticleManager:SetParticleControl( groundFx2, 1, target:GetAbsOrigin())
    ParticleManager:SetParticleControlOrientation(groundFx1, 0, RandomVector(3), Vector(0,1,0), Vector(1,0,0))
    ParticleManager:SetParticleControlOrientation(groundFx2, 0, RandomVector(3), Vector(0,1,0), Vector(1,0,0))
    local firstStrikeFx = ParticleManager:CreateParticle("particles/custom/lishuwen/lishuwen_no_second_strike_hit.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl( firstStrikeFx, 0, target:GetAbsOrigin())
end

function OnNSSTakeDamage(keys)
	local caster = keys.caster
	local target = keys.unit
	local ability = keys.ability
	local attacker = keys.attacker
	local damage = keys.ProcDamage
	local stunDuration = keys.ProcStunDuration

	if attacker:GetName() == "npc_dota_hero_bloodseeker" and target.IsNSSProcReady then
		target.IsNSSProcReady = false
		target:AddNewModifier(caster, target, "modifier_stunned", {Duration = stunDuration})
		DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, 0, keys.ability, false)
		Timers:CreateTimer(caster.ProcStunDuration + 0.3, function()
			target.IsNSSProcReady = true
		end)

		target:EmitSound("hero_bloodseeker.rupture.cast")
	end
end

function OnNSSDelayFinished(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local damage = 0

	if caster.bIsCirculatoryShockAcquired ~= true then return end --If without circulatory shock attribute, no damage at end of open_wound_duration (3.5s).
	--[[local damage = target:GetMana() * keys.DelayedDamagePercentage/100
	if target:GetName() == "npc_dota_hero_juggernaut" or target:GetName() == "npc_dota_hero_shadow_shaman" then
		damage = (target:GetMaxHealth() - target:GetHealth()) * keys.DelayedDamagePercentage/100
	end]]

	if target:HasModifier("modifier_mark_of_fatality") then
		local abil = caster:FindAbilityByName("lishuwen_martial_arts")
		local currentStack = target:GetModifierStackCount("modifier_mark_of_fatality", abil)
		damage = (target:GetMaxHealth() - target:GetHealth()) * ATTR_NSS_STACK_DAMAGE_PERCENTAGE * currentStack/100
	end
	print("dealt "	.. damage .. " damage")
	--target:SetMana(target:GetMana() - damage)
	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	--target:AddNewModifier(caster, target, "modifier_stunned", {Duration = keys.DelayedStunDuration})

	local manaBurnFx = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_mana_burn.vpcf", PATTACH_ABSORIGIN, target)
	target:EmitSound("Hero_NyxAssassin.ManaBurn.Target")
	-- do damage and apply CC
end

vectors = {
	Vector(500, 500, 500),
	Vector(-500,-500,300),
	Vector(500,-500,400),
	Vector(-300, 400, 500),
	Vector(0,-500, 500),
	Vector(300, 0, 400),
	Vector(500, 500, 500),
	Vector(-500,-500,300),
	Vector(-300, 400, 500),
	Vector(500, 500, 500),
	Vector(-500,-500,300),
	Vector(500,-500,400),
	Vector(-300, 400, 500),
	Vector(0,-500, 500),
	Vector(0,0, 0)
}
--vectorsV2[i] = vectors[i]-vectors[i-1], if i-1==0, then vectors[i-1] == (0,0,0), vectors sum up to 0 for V2.
vectorsV2 = {
	Vector(500, 500, 500),
	Vector(-1000,-1000,-200),
	Vector(1000,0,100),
	Vector(-800, 900, 100),
	Vector(300,-900, 0),
	Vector(300, 500, -100),
	Vector(200, 500, 100),
	Vector(-1000,-1000,-200),
	Vector(200, 900, 200),
	Vector(800, 100, 0),
	Vector(-1000,-1000,-200),
	Vector(1000,0,100),
	Vector(-800, 900, 100),
	Vector(300,-900, 0),
	Vector(0,500, -500)
}

function LishuwenCheckCombo(caster, ability)
    if caster:GetStrength() >= 19.1 and caster:GetAgility() >= 19.1 and caster:GetIntellect() >= 19.1 then
        --[[if ability == caster:FindAbilityByName("lishuwen_concealment") then
            QUsed = true
            Qtime = GameRules:GetGameTime()
            Timers:CreateTimer({
                endTime = 4,
                callback = function()
                QUsed = false
            end
            })
        else]]
    	if ability == caster:FindAbilityByName("lishuwen_cosmic_orbit") and caster:FindAbilityByName("lishuwen_raging_dragon_strike"):IsCooldownReady() and caster:FindAbilityByName("lishuwen_tiger_strike"):IsCooldownReady() and caster:GetAbilityByIndex(2):GetName() == "lishuwen_tiger_strike" then
            caster:SwapAbilities("lishuwen_raging_dragon_strike", "lishuwen_tiger_strike", true, false) 
            Timers:CreateTimer('raging_dragon_timer',{
                endTime = 5,
                callback = function()
                if not caster.bIsCurrentDSCycleFinished and caster.bIsCurrentDSCycleStarted then
                	local abil = caster:FindAbilityByName("lishuwen_raging_dragon_strike")
                	ReduceCooldown(abil, abil:GetCooldown(1)*0.75)
                	caster:RemoveModifierByName("modifier_raging_dragon_strike_cooldown")
                	caster:AddNewModifier(caster, abil, "modifier_raging_dragon_strike_cooldown", {duration = abil:GetCooldown(abil:GetLevel())*0.25})
					local masterabil = caster.MasterUnit2:FindAbilityByName("lishuwen_raging_dragon_strike")
					masterabil:EndCooldown()
					masterabil:StartCooldown(masterabil:GetCooldown(1)*0.25)            	
                end	
				local currentAbil = caster:GetAbilityByIndex(2)	
				caster:SwapAbilities("lishuwen_tiger_strike",currentAbil:GetAbilityName() , true, false)
				caster.bIsCurrentDSCycleStarted = false
            end
            })
        end
    end
end

