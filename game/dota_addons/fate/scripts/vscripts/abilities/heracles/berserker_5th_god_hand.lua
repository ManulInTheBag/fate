-- berserker_5th_god_hand — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/heracles/heracles_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

berserker_5th_god_hand = class({})

LinkLuaModifier("modifier_berserk_god_hand", "abilities/heracles/berserker_5th_god_hand", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_god_hand_stock", "abilities/heracles/berserker_5th_god_hand", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_god_hand_debuff", "abilities/heracles/berserker_5th_god_hand", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_tracker", "abilities/heracles/modifiers/modifier_death_tracker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heracles_heal_disable", "abilities/heracles/modifiers/modifier_heracles_heal_disable", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/berserker_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnGodHandDeath

OnGodHandDeath = function(keys)
	local caster = keys.caster
	local newRespawnPos = caster:GetOrigin()
	local ply = caster:GetPlayerOwner()
	local radius = 600

	local dummy = CreateUnitByName("godhand_res_locator", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
	dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	dummy:AddNewModifier(caster, nil, "modifier_phased", {duration=1.0})
	dummy:AddNewModifier(caster, nil, "modifier_kill", {duration=1.1})


	--print("God Hand activated")
	Timers:CreateTimer({
		endTime = 1,
		callback = function()
		--print(caster.bIsGHReady)
		--if IsTeamWiped(caster) == false and caster.GodHandStock > 0 and caster.bIsGHReady and _G.CurrentGameState == "FATE_ROUND_ONGOING" then
		print(caster:HasModifier("modifier_god_hand_stock"))
		if IsTeamWiped(caster) == false and caster:HasModifier("modifier_god_hand_stock") and _G.CurrentGameState == "FATE_ROUND_ONGOING" then
		
			--Timers:CreateTimer(30.0, function() caster.bIsGHReady = true end)
			if caster:HasModifier("modifier_hero_selection_skin") then
				if caster:FindModifierByName("modifier_hero_selection_skin").skinNumber == 3 then
					EmitGlobalSound("matthias_res") 
				else
					EmitGlobalSound("Berserker.Roar") 
				end
			else
				EmitGlobalSound("Berserker.Roar") 
			end
			LoopOverPlayers(function(player, playerID, playerHero)
				--print("looping through " .. playerHero:GetName())
				if playerHero.zlodemon == true then
					-- apply legion horn vsnd on their client
					CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_herc_revive"})
					--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
				end
			end)
			local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			--caster.GodHandStock = caster.GodHandStock - 1
			--GameRules:SendCustomMessage("<font color='#FF0000'>----------!!!!!</font> Remaining God Hand stock : " .. caster.GodHandStock , 0, 0)
			caster:SetRespawnPosition(dummy:GetAbsOrigin())
			RemoveDebuffsForRevival(caster)
			caster:RespawnHero(false,false)

			--[[
			caster:RemoveModifierByName("modifier_god_hand_stock")
			if caster.GodHandStock > 0 then
				caster:AddNewModifier(caster, keys.ability, "modifier_god_hand_stock", {})
				caster:SetModifierStackCount("modifier_god_hand_stock", caster, caster.GodHandStock)
			end
			]]
			-- Apply revive damage
			local resExp = ParticleManager:CreateParticle("particles/custom/berserker/god_hand/stomp.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(particle, 3, caster:GetAbsOrigin())
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			-- DebugDrawCircle(caster:GetAbsOrigin(), Vector(255,0,0), 0.5, radius, true, 0.5)
			for k,v in pairs(targets) do
		        DoDamage(caster, v, 500 + caster:GetStrength(), DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
		        --caster:AddNewModifier(caster, keys.ability, "modifier_herc_gh_reduc", {duration = 1})
			end	

			-- Apply penalty
			caster:AddNewModifier(caster, keys.ability, "modifier_god_hand_debuff", {}) 
			caster:AddNewModifier(caster, keys.ability, "modifier_heracles_heal_disable", { duration = 1 })
			if not caster.IsGodHandAcquired then
				caster:SetHealth(caster:GetMaxHealth()*0.25)
			else
				caster:SetHealth(caster:GetMaxHealth()*0.6)
				caster:FindAbilityByName("heracles_berserk"):EnterBerserk(1)
				--caster:FindAbilityByName("heracles_berserk"):EndCooldown()
			end
			-- Remove Gae Buidhe modifier
			caster:RemoveModifierByName("modifier_god_hand_stock")
			caster:RemoveModifierByName("modifier_gae_buidhe")
			-- Reset godhand stock
			--caster.ReincarnationDamageTaken = 0
			--UpdateGodhandProgress(caster)
		else
			--caster.DeathCount = (caster.DeathCount or 0) + 1
			-- RespawnPos ставится в OnHeroInGame только на раундах 0/1 и чётных:			-- у героя, заспавненного читом посреди нечётного раунда, он nil,			-- и краш здесь обрывал колбэк -> счётчик смертей не выставлялся			if caster.RespawnPos then				caster:SetRespawnPosition(caster.RespawnPos)			end
			caster.MasterUnit:AddNewModifier(caster, nil, "modifier_death_tracker", { Deaths = caster.DeathCount })
		end
		--caster:SetRespawnPosition(Vector(7000, 2000, 320)) need to set the respawn base after reviving
	end
	})	

end


function berserker_5th_god_hand:GetIntrinsicModifierName()
	return "modifier_berserk_god_hand"
end

function berserker_5th_god_hand:OnSpellStart()
	local caster = self:GetCaster()
	-- (DD-событие было пустым)
end

modifier_berserk_god_hand = class({})

function modifier_berserk_god_hand:IsHidden() return true end

function modifier_berserk_god_hand:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_berserk_god_hand:OnDeath(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: berserker_ability / OnGodHandDeath
	OnGodHandDeath({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker
	})
end

modifier_god_hand_stock = class({})

function modifier_god_hand_stock:IsHidden() return false end
function modifier_god_hand_stock:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_PERMANENT end

modifier_god_hand_debuff = class({})

function modifier_god_hand_debuff:IsDebuff() return true end
function modifier_god_hand_debuff:GetEffectName() return "particles/custom/berserker/god_hand/debuff.vpcf" end
function modifier_god_hand_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_god_hand_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	}
end

function modifier_god_hand_debuff:GetModifierBonusStats_Strength()
	return -50
end

function modifier_god_hand_debuff:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "7" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(7, true)
	end
end

function modifier_god_hand_debuff:OnRefresh(kv)
	self:OnCreated(kv)
end
