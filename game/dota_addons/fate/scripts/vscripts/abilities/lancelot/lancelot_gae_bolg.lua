-- lancelot_gae_bolg — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/lancelot/lancelot_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lancelot_gae_bolg = class({})

-- Логика перенесена из scripts/vscripts/lancelot_ability.lua, scripts/vscripts/lancer_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local GBAttachEffect, OnGBTargetHit, OnKnightUsed, ArsenalReturnMana, PlayHeartBreakEffect, PlayNormalGBEffect, OnKnightClosed

GBAttachEffect = function(keys)
	local caster = keys.caster
	local GBCastFx = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(GBCastFx, 1, caster:GetAbsOrigin()) -- target effect location
	ParticleManager:SetParticleControl(GBCastFx, 2, caster:GetAbsOrigin()) -- circle effect location
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( GBCastFx, false )
	end)

	if keys.ability == caster:FindAbilityByName("lancer_5th_gae_bolg") then
		caster:EmitSound("Lancer.GaeBolg")
	elseif keys.ability == caster:FindAbilityByName("lancelot_gae_bolg") then 
		caster:EmitSound("Lancelot.Growl_Local" )
	end
	if keys.caster:GetName() == "npc_dota_hero_sven" then
		EmitZlodemonTrueSoundEveryone("moskes_lanc_gae")
	end
end

OnGBTargetHit = function(keys)
	ArsenalReturnMana(keys.caster)
	if IsSpellBlocked(keys.target, keys.caster) then return end -- Linken effect checker
	if keys.caster:GetAbilityByIndex(2):GetAbilityName() == "lancer_5th_wesen_gae_bolg" then return end -- laziest fix of my lyfe

	local caster = keys.caster
	local casterName = caster:GetName()
	local target = keys.target
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	if caster.IsHeartSeekerAcquired == true then keys.HBThreshold = keys.HBThreshold + caster:GetAttackDamage()*ATTR_HEARTSEEKER_AD_RATIO end

	-- Check if caster is lancer(not lancelot)
	if casterName == "npc_dota_hero_phantom_lancer" then
		local runeAbil = caster:FindAbilityByName("lancer_5th_rune_of_flame")
		local healthDamagePct = runeAbil:GetLevelSpecialValueFor("ability_bonus_damage", runeAbil:GetLevel()-1)
		if caster.IsGaeBolgImproved == true then
		healthDamagePct = healthDamagePct * 2
		end
		keys.Damage = keys.Damage + target:GetHealth()*healthDamagePct/100
	else
		if keys.caster:GetName() ~= "npc_dota_hero_sven" then
			StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_CAST_ABILITY_1, rate=3})
		end
	end

	giveUnitDataDrivenModifier(caster, target, "can_be_executed", 0.033)
	if caster.ImproveKnightOfOwner then 
		DoDamage(caster, target, keys.Damage, DAMAGE_TYPE_PURE, 0, keys.ability, false)
	else
		DoDamage(caster, target, keys.Damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	end

	--target:AddNewModifier(caster, target, "modifier_stunned", {Duration = 1.0})
	if target:GetHealth() < keys.HBThreshold then
		PlayHeartBreakEffect(ability, caster, target)
	end  -- check for HB

	-- if Gae Bolg is improved, do 3 second dot over time
	--[[if caster.IsGaeBolgImproved == true then 
		local dotCount = 0
		Timers:CreateTimer(function() 
			if dotCount == 3 then return end
			DoDamage(caster, target, target:GetMaxHealth()/30, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
			dotCount = dotCount + 1
			return 1.0 
		end)
	end]]

	--[[
	-- if Heart Seeker attribute is acquired, check for HB condition every 0.3 seconds
	if caster.IsHeartSeekerAcquired == true then
		local dotCount = 0
		Timers:CreateTimer(function() 
			if dotCount == 10 then return end
			if target:GetHealth() < keys.HBThreshold then 
				if target:GetHealth() ~= 0 then 
					PlayHeartBreakEffect(target)

				end 
				target:Kill(keys.ability, caster) 
			end 
			dotCount = dotCount + 1
			return 0.3
		end)
	end]]
	if ability:GetAbilityName() == "lancer_5th_gae_bolg" then
		StartAnimation(caster, {duration=0.3, activity=ACT_DOTA_ATTACK, rate=3})
	end
	-- Add dagon particle
	local dagon_particle = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf",  PATTACH_ABSORIGIN_FOLLOW, keys.caster)
	ParticleManager:SetParticleControlEnt(dagon_particle, 1, keys.target, PATTACH_POINT_FOLLOW, "attach_hitloc", keys.target:GetAbsOrigin(), false)
	local particle_effect_intensity = 600
	ParticleManager:SetParticleControl(dagon_particle, 2, Vector(particle_effect_intensity))
	target:EmitSound("Hero_Lion.Impale")
	PlayNormalGBEffect(target)
	-- Blood splat
	local splat = ParticleManager:CreateParticle("particles/generic_gameplay/screen_blood_splatter.vpcf", PATTACH_EYES_FOLLOW, target)

	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( dagon_particle, false )
		ParticleManager:DestroyParticle( splat, false )
	end)
end

OnKnightUsed = function(keys)
        local caster = keys.caster
        local ply = caster:GetPlayerOwner()
        local ability = keys.ability

        if not caster.KnightLevel and not caster.ArsenalLevel then
                OnKnightClosed(keys)
                caster:FindAbilityByName("lancelot_knight_of_honor"):StartCooldown(ability:GetCooldown(ability:GetLevel()))
        end
end

ArsenalReturnMana = function(caster)
    if caster:GetName() == "npc_dota_hero_sven" and caster.ArsenalLevel == 2 then
        caster:GiveMana(caster:FindAbilityByName("lancelot_knight_of_honor_arsenal"):GetSpecialValueFor("mana_return"))
    end
end

PlayHeartBreakEffect = function(ability, killer, target)
	if target:HasModifier("modifier_avalon") then return end
	local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(culling_kill_particle)

	local hb = ParticleManager:CreateParticle("particles/custom/lancer/lancer_heart_break_txt.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl( hb, 0, target:GetAbsOrigin())

	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
		ParticleManager:DestroyParticle( hb, false )
	end)
	target:Execute(ability, killer, { bExecution = true })
end

PlayNormalGBEffect = function(target)
	local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(culling_kill_particle)
	
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
	end)
end

OnKnightClosed = function(keys)
        local caster = keys.caster
        caster.IsKnightOpen = false
        local a1 = caster:GetAbilityByIndex(0)
        local a2 = caster:GetAbilityByIndex(1)
        local a3 = caster:GetAbilityByIndex(2)
        local a4 = caster:GetAbilityByIndex(3)
        local a5 = caster:GetAbilityByIndex(4)
        local a6 = caster:GetAbilityByIndex(5)
        -- if knight attribute is not taken, caster.KnightLevel~=nil is false and therefore kills off queueing a 2nd skill. 
        caster:SwapAbilities(a1:GetName(), "lancelot_minigun", false ,true) 
        caster:SwapAbilities(a2:GetName(), "lancelot_parry", false, true) 
        caster:SwapAbilities(a3:GetName(), "lancelot_knight_of_honor", false, true)
        if caster.nukeAvail == true then 
            caster:SwapAbilities(a4:GetName(), "lancelot_nuke", false, true) 
        elseif caster:HasAbility("lancelot_blessing_of_fairy") then 
            caster:SwapAbilities(a4:GetName(), "lancelot_blessing_of_fairy", false, true) 
        else 
            caster:SwapAbilities(a4:GetName(), "fate_empty1", false, true) 
        end
        caster:SwapAbilities(a5:GetName(), "lancelot_arms_mastership", false, true) 
        
        if caster:HasModifier("modifier_arondite") then
            caster:SwapAbilities(a6:GetName(), "lancelot_arondight_overload", false, true )     
        else
            caster:SwapAbilities(a6:GetName(), "lancelot_arondite", false, true )     
        end
end


function lancelot_gae_bolg:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: lancer_ability / GBAttachEffect
	GBAttachEffect({ caster = caster, ability = self, target = target })
	return true
end

function lancelot_gae_bolg:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: lancer_ability / OnGBTargetHit
	OnGBTargetHit({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage"),
		HBThreshold = self:GetSpecialValueFor("heartbreak_threshold")
	})
	-- DD RunScript: lancelot_ability / OnKnightUsed
	OnKnightUsed({ caster = caster, ability = self, target = target })
	EmitSoundOn("Hero_Lion.Impale", caster)
end
