-- astolfo_la_black_luna — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/astolfo/astolfo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

astolfo_la_black_luna = class({})

LinkLuaModifier("modifier_la_black_luna", "abilities/astolfo/astolfo_la_black_luna", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_la_black_luna_deaf", "abilities/astolfo/astolfo_la_black_luna", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_la_black_luna_slow", "abilities/astolfo/astolfo_la_black_luna", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_la_black_luna_slow1", "abilities/astolfo/astolfo_la_black_luna", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_la_black_luna_slow2", "abilities/astolfo/astolfo_la_black_luna", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_astolfo_mute1", "abilities/astolfo/astolfo_la_black_luna", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_astolfo_mute2", "abilities/astolfo/astolfo_la_black_luna", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_la_black_luna_unstoppable", "abilities/astolfo/modifiers/modifier_la_black_luna_unstoppable", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_protection_from_arrows_active", "abilities/cu_chulain/modifiers/modifier_protection_from_arrows_active", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/astolfo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnHornCast, OnHornStart, OnHornInterrupted, OnHornThink, AstolfoCheckCombo

OnHornCast = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	if caster:HasModifier("modifier_hippogriff_ride_ascended") then 
		caster:Stop()
		return 
	end 
	caster:EmitSound("Astolfo_Luna_" .. RandomInt(1, 2))
	StartAnimation(caster, {duration=4.6, activity=ACT_DOTA_CAST_ABILITY_3_END, rate=1.0})
	--StartAnimation(caster, {duration=0.55, activity=ACT_DOTA_CAST_ABILITY_ROT, rate=1.0})
end

OnHornStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local radius = keys.Radius
	local silenceRadius = keys.SilenceRadius
	if caster:HasModifier("modifier_hippogriff_ride_ascended") then 
		ability:EndCooldown()
		caster:GiveMana(ability:GetManaCost(1)) 
		caster:Stop()
		return 
	end
	caster.AstolfoSimpleFix = false
	caster.rape_count = 1
	caster:AddNewModifier(caster, self, "modifier_protection_from_arrows_active", { Duration =  1})
	AstolfoCheckCombo(caster, ability)
	caster.currentHornManaCost = ability:GetManaCost(ability:GetLevel())
	caster:AddNewModifier(caster, ability, "modifier_la_black_luna", {})
	caster:AddNewModifier(caster, ability, "modifier_la_black_luna_unstoppable", {})

	local silenceTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, silenceRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(silenceTargets) do
		if not v:IsMagicImmune() then 
			-- apply silence
			giveUnitDataDrivenModifier(caster, v, "silenced", 0.5)
		end
    end

    if caster.IsDeafeningBlastAcquired then
    	ProjectileManager:ProjectileDodge(caster)

    	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
	    for k,v in pairs(targets) do
	    	if v:GetName() ~= "npc_dota_ward_base" then
		    	DoDamage(caster, v, 350, DAMAGE_TYPE_MAGICAL, 0, ability, false)
		    	if not IsKnockbackImmune(v) then
					giveUnitDataDrivenModifier(caster, v, "drag_pause", 0.5)
					v:AddNewModifier(caster, keys.ability, "modifier_astolfo_mute1", {})
					v:AddNewModifier(caster, ability, "modifier_la_black_luna_slow1", {})
					
					local pushback = Physics:Unit(v)
					v:PreventDI()
					v:SetPhysicsFriction(0)
					v:SetPhysicsVelocity((v:GetAbsOrigin() -  caster:GetAbsOrigin()):Normalized() * 250)
					v:SetNavCollisionType(PHYSICS_NAV_NOTHING)
					v:FollowNavMesh(false)

					Timers:CreateTimer(0.5, function()  
						v:PreventDI(false)
						v:SetPhysicsVelocity(Vector(0,0,0))
						v:OnPhysicsFrame(nil)
						FindClearSpaceForUnit(v, v:GetAbsOrigin(), true)
						return 
					end)
				end
			end
		end
    end

	--StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_3_END, rate=1.0})
	--caster:StopAnimation()
	--StartAnimation(caster, {duration=4.1, activity=ACT_DOTA_CAST_ABILITY_3_END, rate=1.0})
	-- if not debug_mode then 
	-- 	Attachments:AttachProp(caster, "attach_horn", "models/astolfo/astolfo_horn.vmdl")
	-- end
    LoopOverPlayers(function(player, playerID, playerHero)
    	--print("looping through " .. playerHero:GetName())
        if playerHero:GetTeamNumber() == caster:GetTeamNumber() then
        	-- apply legion horn vsnd on their client
        	CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Astolfo.Horn"})
        	--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        else
        	-- apply legion horn + silencer vsnd on their client
        	CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Hero_Silencer.GlobalSilence.Effect"})
        end
    end)

    local shockwaveIndex = ParticleManager:CreateParticle("particles/custom/astolfo/la_black_luna/la_black_luna_shockwave.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl( shockwaveIndex, 0, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl( shockwaveIndex, 1, Vector(500,0,0))
    ParticleManager:SetParticleControl( shockwaveIndex, 2, Vector(radius,0,0))
end

OnHornInterrupted = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:RemoveModifierByName("modifier_protection_from_arrows_active")
	caster:RemoveModifierByName("modifier_la_black_luna_unstoppable")
	if caster.rape_count == 5 and not keys.caster.AstolfoSimpleFix  then
		local rapeTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(rapeTargets) do
			v:AddNewModifier(caster, ability, "modifier_la_black_luna_slow2", {})
			v:AddNewModifier(caster, keys.ability, "modifier_astolfo_mute2", {})
			DoDamage(caster, v, 300 + caster:GetStrength() * 7, DAMAGE_TYPE_PURE, 0, ability, false)
			local shockwaveIndex = ParticleManager:CreateParticle("particles/custom/astolfo/la_black_luna/la_black_luna_shockwave.vpcf", PATTACH_CUSTOMORIGIN, nil)
   			ParticleManager:SetParticleControl( shockwaveIndex, 0, caster:GetAbsOrigin())
    		ParticleManager:SetParticleControl( shockwaveIndex, 1, Vector(500,0,0))
    		ParticleManager:SetParticleControl( shockwaveIndex, 2, Vector(radius,0,0))
    	end
		keys.caster.AstolfoSimpleFix = true
    end
	
	CustomGameEventManager:Send_ServerToAllClients("stop_horn_sound", {})
	caster:RemoveModifierByName("modifier_la_black_luna")
	-- if not debug_mode then 
	-- 	local prop = Attachments:GetCurrentAttachment(caster, "attach_horn")
	-- 	if not prop:IsNull() then prop:RemoveSelf() end
	-- end
	caster:StopAnimation()
	StartAnimation(caster, {duration=0.01, activity=ACT_DOTA_ATTACK, rate=1.0})	
end

OnHornThink = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local slowRadius = keys.Radius
	local damageRadius = keys.DamageRadius
	local silenceRadius = keys.SilenceRadius
	local damage = keys.Damage

	if caster.IsDeafeningBlastAcquired then
    	ProjectileManager:ProjectileDodge(caster)
    	damage = damage + 50
    	caster.rape_count = caster.rape_count + 1
    end

    local deafTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 20000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for k,v in pairs(deafTargets) do
		v:AddNewModifier(caster, ability, "modifier_la_black_luna_deaf", {})
    end

    local slowTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, slowRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(slowTargets) do
		if not IsImmuneToSlow(v) then
			v:AddNewModifier(caster, ability, "modifier_la_black_luna_slow", {})
		end
    end

    local damageTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, damageRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(damageTargets) do
		-- apply damage
		DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
    end

    local silenceTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, silenceRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(silenceTargets) do
		-- apply silence
		--giveUnitDataDrivenModifier(caster, v, "silenced", 0.15)
    end

end

AstolfoCheckCombo = function(caster, ability)
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
		if ability == caster:FindAbilityByName("astolfo_la_black_luna") then
			caster:SwapAbilities("astolfo_hippogriff_vanish", "astolfo_hippogriff_ride", false, true)
			Timers:CreateTimer({
				endTime = 2,
				callback = function()
				caster:SwapAbilities("astolfo_hippogriff_vanish", "astolfo_hippogriff_ride", true, false)
			end
			})
		end
	end
end


function astolfo_la_black_luna:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	-- DD RunScript: astolfo_ability / OnHornCast
	OnHornCast({ caster = caster, ability = self, target = caster })
	return true
end

function astolfo_la_black_luna:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: astolfo_ability / OnHornStart
	OnHornStart({
		caster = caster,
		ability = self,
		target = caster,
		Slow = self:GetSpecialValueFor("slow_amount"),
		Radius = self:GetSpecialValueFor("radius"),
		DamageRadius = self:GetSpecialValueFor("damage_radius"),
		Damage = self:GetSpecialValueFor("damage"),
		SilenceRadius = self:GetSpecialValueFor("silence_radius")
	})
end

function astolfo_la_black_luna:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	-- DD RunScript: astolfo_ability / OnHornInterrupted
	OnHornInterrupted({ caster = caster, ability = self })
	if bInterrupted then
		-- DD RunScript: astolfo_ability / OnHornInterrupted
		OnHornInterrupted({ caster = caster, ability = self })
	end
end

modifier_la_black_luna = class({})


function modifier_la_black_luna:OnCreated(kv)
	if not IsServer() then return end
	self:StartIntervalThink(0.5)
end

function modifier_la_black_luna:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_la_black_luna:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: astolfo_ability / OnHornThink
	OnHornThink({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent(),
		Radius = self:GetAbility():GetSpecialValueFor("radius"),
		DamageRadius = self:GetAbility():GetSpecialValueFor("damage_radius"),
		Damage = self:GetAbility():GetSpecialValueFor("damage"),
		SilenceRadius = self:GetAbility():GetSpecialValueFor("silence_radius")
	})
end

modifier_la_black_luna_deaf = class({})

function modifier_la_black_luna_deaf:IsDebuff() return true end

function modifier_la_black_luna_deaf:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.53" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.53, true)
	end
end

function modifier_la_black_luna_deaf:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_la_black_luna_slow = class({})

function modifier_la_black_luna_slow:IsDebuff() return true end

function modifier_la_black_luna_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_la_black_luna_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_amount")
end

function modifier_la_black_luna_slow:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.53" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.53, true)
	end
end

function modifier_la_black_luna_slow:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_la_black_luna_slow1 = class({})

function modifier_la_black_luna_slow1:IsDebuff() return true end

function modifier_la_black_luna_slow1:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_la_black_luna_slow1:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_amount1")
end

function modifier_la_black_luna_slow1:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.0, true)
	end
end

function modifier_la_black_luna_slow1:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_la_black_luna_slow2 = class({})

function modifier_la_black_luna_slow2:IsDebuff() return true end

function modifier_la_black_luna_slow2:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_la_black_luna_slow2:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_amount2")
end

function modifier_la_black_luna_slow2:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "2.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(2.0, true)
	end
end

function modifier_la_black_luna_slow2:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_astolfo_mute1 = class({})

function modifier_astolfo_mute1:IsDebuff() return true end

function modifier_astolfo_mute1:CheckState()
	return {
		[MODIFIER_STATE_MUTED] = true,
	}
end

function modifier_astolfo_mute1:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.5" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.5, true)
	end
end

function modifier_astolfo_mute1:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_astolfo_mute2 = class({})

function modifier_astolfo_mute2:IsDebuff() return true end

function modifier_astolfo_mute2:CheckState()
	return {
		[MODIFIER_STATE_MUTED] = true,
	}
end

function modifier_astolfo_mute2:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.5" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.5, true)
	end
end

function modifier_astolfo_mute2:OnRefresh(kv)
	self:OnCreated(kv)
end
