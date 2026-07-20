--------------------------------------------------------------------------------
-- modifier_fate_flying_vision
--
-- Restores unobstructed ("flying") vision for a MOVING unit after the 2026-07-18
-- Dota client build stopped granting flying vision from MODIFIER_STATE_FLYING.
--
-- The unit keeps its own (now obstructed) vision; this modifier re-issues a
-- rolling unobstructed FOW viewer at the unit's position on a fixed interval.
-- The viewer lives slightly longer than the interval so there is never a gap.
--
-- Optional param "range": vision radius to reveal. If omitted, the unit's own
-- configured day/night vision range is used, so it always matches the unit.
--------------------------------------------------------------------------------
modifier_fate_flying_vision = class({})

local INTERVAL = 0.5

function modifier_fate_flying_vision:IsHidden() return true end
function modifier_fate_flying_vision:IsPurgable() return false end
function modifier_fate_flying_vision:RemoveOnDeath() return true end

function modifier_fate_flying_vision:OnCreated(params)
	if not IsServer() then return end
	self.range = tonumber(params and params.range) -- nil -> use the unit's own vision range
	self:OnIntervalThink()                          -- reveal immediately, no first-tick gap
	self:StartIntervalThink(INTERVAL)
end

function modifier_fate_flying_vision:OnIntervalThink()
	if not IsServer() then return end
	local unit = self:GetParent()
	if unit == nil or unit:IsNull() then return end

	local range = self.range
	if range == nil then
		range = GameRules:IsDaytime() and unit:GetDayTimeVisionRange() or unit:GetNightTimeVisionRange()
	end

	-- last arg false = unobstructed (flying) vision; +0.1s overlap prevents flicker
	AddFOWViewer(unit:GetTeamNumber(), unit:GetAbsOrigin(), range, INTERVAL + 0.1, false)
end
