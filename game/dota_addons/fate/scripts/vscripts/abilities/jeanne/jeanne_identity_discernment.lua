-- Jeanne: Identity Discernment (full lua port of the old datadriven version).
-- Pings every living enemy hero on the minimap and reveals them briefly;
-- the cooldown is refunded when Jeanne respawns (once-per-life mechanic).
jeanne_identity_discernment = class({})

LinkLuaModifier("modifier_identity_discernment", "abilities/jeanne/jeanne_identity_discernment", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_vision", "abilities/jeanne/modifiers/modifier_jeanne_vision", LUA_MODIFIER_MOTION_NONE)

function jeanne_identity_discernment:GetIntrinsicModifierName()
	return "modifier_identity_discernment"
end

function jeanne_identity_discernment:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("saint_vision_duration")
	local delay = 0

	-- losing team gets the longer reveal
	if caster.ServStat.radiantWin <= caster.ServStat.direWin and caster:GetTeam() == DOTA_TEAM_GOODGUYS or caster.ServStat.radiantWin >= caster.ServStat.direWin and caster:GetTeam() == DOTA_TEAM_BADGUYS then
		duration = 5
	end

	GameRules:SendCustomMessage("#identity_discernment_alert", 0, 0)
	LoopOverPlayers(function(player, playerID, playerHero)
		if playerHero:GetTeamNumber() ~= caster:GetTeamNumber() and playerHero:IsAlive() then
			delay = delay + 0.15
			Timers:CreateTimer(delay, function()
				MinimapEvent( caster:GetTeamNumber(), caster, playerHero:GetAbsOrigin().x, playerHero:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 2)
			end)
			playerHero:AddNewModifier(caster, self, "modifier_jeanne_vision", { Duration = duration })
		end
	end)
end

-- passive: refunds the cooldown on respawn
modifier_identity_discernment = class({})

function modifier_identity_discernment:IsHidden() return true end
function modifier_identity_discernment:IsPurgable() return false end
function modifier_identity_discernment:RemoveOnDeath() return false end

function modifier_identity_discernment:DeclareFunctions()
	return { MODIFIER_EVENT_ON_RESPAWN }
end

function modifier_identity_discernment:OnRespawn(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	if self:GetAbility():GetLevel() < 1 then return end
	self:GetAbility():EndCooldown()
end
