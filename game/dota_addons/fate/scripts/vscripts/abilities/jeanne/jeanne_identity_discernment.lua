-- jeanne_identity_discernment — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/jeanne/jeanne_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

jeanne_identity_discernment = class({})

LinkLuaModifier("modifier_identity_discernment", "abilities/jeanne/jeanne_identity_discernment", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/jeanne_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnIDPing, OnIDRespawn

OnIDPing = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local duration = 1.5
	--keys.Duration
	local delay = 0

	if caster.ServStat.radiantWin <= caster.ServStat.direWin and caster:GetTeam() == DOTA_TEAM_GOODGUYS or caster.ServStat.radiantWin >= caster.ServStat.direWin and caster:GetTeam() == DOTA_TEAM_BADGUYS then
		duration = 5        	
		--SpawnAttachedVisionDummy(caster, playerHero, 200, duration, true)
	end


	GameRules:SendCustomMessage("#identity_discernment_alert", 0, 0)
    LoopOverPlayers(function(player, playerID, playerHero)
    	--print("looping through " .. playerHero:GetName())
        if playerHero:GetTeamNumber() ~= caster:GetTeamNumber() and playerHero:IsAlive() then
        	--print("looping through " .. playerHero:GetName())
        	delay = delay + 0.15
        	Timers:CreateTimer(delay, function()
        		MinimapEvent( caster:GetTeamNumber(), caster, playerHero:GetAbsOrigin().x, playerHero:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 2)
        	end)
        	-- Score is updated at end of round in addon_game_mode.lua. Since I'm already tracking score over there, I may as well use it...
        	
        	playerHero:AddNewModifier(caster, ability, "modifier_jeanne_vision", { Duration = duration })
        end
     end)
end

OnIDRespawn = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	-- reset CD
	ability:EndCooldown()
	--print("asdasd")
end


function jeanne_identity_discernment:GetIntrinsicModifierName()
	return "modifier_identity_discernment"
end

function jeanne_identity_discernment:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: jeanne_ability / OnIDPing
	OnIDPing({
		caster = caster,
		ability = self,
		target = caster,
		Duration = self:GetSpecialValueFor("saint_vision_duration")
	})
end

modifier_identity_discernment = class({})

function modifier_identity_discernment:IsHidden() return true end

function modifier_identity_discernment:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_RESPAWN,
	}
end

function modifier_identity_discernment:OnRespawn(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: jeanne_ability / OnIDRespawn
	OnIDRespawn({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end
