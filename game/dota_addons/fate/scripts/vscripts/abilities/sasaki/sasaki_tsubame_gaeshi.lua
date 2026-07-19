sasaki_tsubame_gaeshi = class({})

LinkLuaModifier("modifier_exhausted", "abilities/sasaki/modifiers/modifier_exhausted", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ganryu_armor_shred", "abilities/sasaki/modifiers/modifier_ganryu_armor_shred", LUA_MODIFIER_MOTION_NONE)

function sasaki_tsubame_gaeshi:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" or caster:HasModifier("modifier_tsubame_mai") then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function sasaki_tsubame_gaeshi:GetCustomCastErrorTarget()
	if self:GetCaster():HasModifier("modifier_tsubame_mai") then
		return "Че самый умный, хуесос"
	else
    	return "#Invalid_Target"
	end
end

--[[function sasaki_tsubame_gaeshi:GetCastPoint()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_ganryu_attribute") then
		return 0.7
	else
		return 0.7
	end
end]]

function sasaki_tsubame_gaeshi:OnAbilityPhaseStart()
	local caster = self:GetCaster()	
	local target = self:GetCursorTarget()

	if caster:FindAbilityByName("sasaki_heart_of_harmony"):GetAutoCastState() then
		caster:RemoveModifierByName("modifier_heart_of_harmony")
	end

	--kim names the strike on the windup; the combo skips this phase entirely, so it stays silent there
	if caster:HasModifier("modifier_hero_selection_skin") then
		if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
			EmitGlobalSound("kim_tg")
		end
	end
	--EmitGlobalSound("FA.TGReady")
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="moskes_hiken_ready"})

			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		else
			if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber ~= 2 then --kim stays silent on the windup
					CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="patrick_hiken"})
				end
			else
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="FA.TGReady"})
			end
			
		end

	end)
	local diff = target:GetAbsOrigin() - caster:GetAbsOrigin()
	local firstImpactIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl(firstImpactIndex, 0, caster:GetAbsOrigin() + diff/2)
    ParticleManager:SetParticleControl(firstImpactIndex, 1, Vector(600,0,150))
    ParticleManager:SetParticleControl(firstImpactIndex, 2, Vector(0.4,0,0))

    return true
end

function sasaki_tsubame_gaeshi:OnSpellStart()
	local target = self:GetCursorTarget()
	self:TsubameGaeshi(target, false)
end

function sasaki_tsubame_gaeshi:TsubameGaeshi(target, doPierceSpellBlock)
	local caster = self:GetCaster()
	--local target = self:GetCursorTarget()
	local enhanced = false
	local delay = 0.2
	local delay_per_slash = 0.2
	local split_damage = self:GetSpecialValueFor("damage_split")
	local final_damage = self:GetSpecialValueFor("damage_final")
	local combined_damage = self:GetSpecialValueFor("damage_combined")

	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="hanzo_katana"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)
	if not doPierceSpellBlock then 
		if IsSpellBlocked(target, caster)  then return end
	end

	if caster.IsGanryuAcquired then
		split_damage = split_damage + caster:GetAverageTrueAttackDamage(caster)*0.35
		final_damage = final_damage + caster:GetAverageTrueAttackDamage(caster)*0.7
		--giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.5)
	end

	--caster:SetMana(0)
	
	if caster:HasModifier("modifier_hero_selection_skin") then
		if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber ~= 2 then --kim already named the strike on the windup
			EmitGlobalSound("patrick_tg")
		end
	else
		EmitGlobalSound("FA.TG")
	end
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="moskes_hiken_tg"})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		else
			if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber ~= 2 then --kim already named the strike on the windup
					CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="patrick_tg"})
				end
			else
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="FA.TG"})
			end
			
		end

	end)
	if caster:HasModifier("modifier_hero_selection_skin") and caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
		EmitGlobalSound("kim_sfx_chop")
	else
		EmitGlobalSound("FA.CHOP")
	end
	StartAnimation(caster, {duration=delay + delay_per_slash * 2, activity= ACT_DOTA_CAST_ABILITY_4 , rate=2.5})

	caster:AddNewModifier(caster, nil, "modifier_phased", {duration = 1.0})
	giveUnitDataDrivenModifier(caster, caster, "dragged", 1.0)
	giveUnitDataDrivenModifier(caster, caster, "revoked", 1.0)

	local particle = ParticleManager:CreateParticle("particles/custom/false_assassin/tsubame_gaeshi/slashes.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin()) 

	Timers:CreateTimer(delay, function()
		if caster:IsAlive() and target:IsAlive() then
			if caster.IsGanryuAcquired then
				--giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.5)
			end

			if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2 then
					EmitGlobalSound("kim_owarida")
				end
			end

			--if enhanced then
			--	self:PerformSlash(caster, target, 1, 3)
			--else
				self:PerformSlash(caster, target, split_damage, 2, true)
			--end
		else
			ParticleManager:DestroyParticle(particle, true)
		end
	return end)

	delay = delay + delay_per_slash

	Timers:CreateTimer(delay, function()  
		if caster:IsAlive() and target:IsAlive() then
			--if enhanced then
			--	self:PerformSlash(caster, target, 1, 3)
			--else
				self:PerformSlash(caster, target, split_damage, 2, true)
			--end
		else
			ParticleManager:DestroyParticle(particle, true)
		end
	return end)

	delay = delay + delay_per_slash

	Timers:CreateTimer(delay, function()
		if caster:IsAlive() and target:IsAlive() then
			--if enhanced then
			--	self:PerformSlashk(caster, target, combined_damage, 1)
			--	target:AddNewModifier(caster, self, "modifier_stunned", { Duration = 1.5 })
			--else
				self:PerformSlash(caster, target, final_damage, 2, true)
			--end
		else
			ParticleManager:DestroyParticle(particle, true)
		end

		target:RemoveModifierByName("modifier_ganryu_armor_shred")
		return 
	end)
end

function sasaki_tsubame_gaeshi:PerformSlash(caster, target, damage, soundQueue, enhanced)
	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
	caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 100) 

	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))
	ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))

	local flag = DOTA_DAMAGE_FLAG_NONE
	if enhanced == true and caster.IsGanryuAcquired then
		flag = DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY
	end

	local isKim = caster:HasModifier("modifier_hero_selection_skin")
				  and caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 2

	if soundQueue == 1 then
		target:EmitSound("Tsubame_Focus")
		target:RemoveModifierByName("modifier_master_intervention")
	elseif soundQueue == 2 then
		target:RemoveModifierByName("modifier_master_intervention")
		if isKim then
			target:EmitSound("kim_sfx_slash_" .. math.random(1,3))
		else
			target:EmitSound("Tsubame_Slash_" .. math.random(1,3))
		end
	else
		target:EmitSound("Hero_Juggernaut.PreAttack")
	end

	if  not flag == DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY then return end

	if caster.IsGanryuAcquired then
		target:AddNewModifier(caster, self, "modifier_ganryu_armor_shred", { Duration = 1})
		--print(target:GetPhysicalArmorValue(false))
		DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, flag, self, false)
	else 
		DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, flag, self, false)
	end	
end

function sasaki_tsubame_gaeshi:PerformSlashk(caster, target, damage, soundQueue)
	local diff = (target:GetAbsOrigin() - caster:GetAbsOrigin() ):Normalized() 
	caster:SetAbsOrigin(target:GetAbsOrigin() - diff * 100) 

	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl(slashIndex, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))
	ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))
	local hb = ParticleManager:CreateParticle("particles/custom/lancer/lancer_heart_break_txt.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl( hb, 0, target:GetAbsOrigin())

	Timers:CreateTimer( 3.0, function()			
		ParticleManager:DestroyParticle( hb, false )
	end)

	local flag = DOTA_DAMAGE_FLAG_NONE

	if soundQueue == 1 then 
		target:EmitSound("Tsubame_Focus")
		target:RemoveModifierByName("modifier_master_intervention")
	elseif soundQueue == 2 then
		target:EmitSound("Tsubame_Slash_" .. math.random(1,3))
	else
		target:EmitSound("Hero_Juggernaut.PreAttack")
	end

	if   not flag == DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY then return end

	if caster.IsGanryuAcquired then
		target:AddNewModifier(caster, self, "modifier_ganryu_armor_shred", { Duration = 1})
		--print(target:GetPhysicalArmorValue(false))
		DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, flag, self, false)
	else 
		DoDamage(caster, target, damage, DAMAGE_TYPE_PURE, flag, self, false)
	end	
end