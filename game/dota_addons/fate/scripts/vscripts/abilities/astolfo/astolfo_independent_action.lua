-- astolfo_independent_action — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/astolfo/astolfo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

astolfo_independent_action = class({})

LinkLuaModifier("modifier_astolfo_independent_action", "abilities/astolfo/astolfo_independent_action", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_astolfo_indepedent_action_regen", "abilities/astolfo/astolfo_independent_action", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_astolfo_indepedent_action_conditional_regen", "abilities/astolfo/astolfo_independent_action", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/astolfo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnIAThink

OnIAThink = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local bIsVisibleToEnemy = false
	LoopOverPlayers(function(player, playerID, playerHero)
		-- if enemy hero can see astolfo, set visibility to true
		if playerHero:GetTeamNumber() ~= caster:GetTeamNumber() then
			if playerHero:CanEntityBeSeenByMyTeam(caster) then
				bIsVisibleToEnemy = true
				return
			end
		end
	end)
	if IsRevoked(caster) or not bIsVisibleToEnemy then
		caster:AddNewModifier(caster, ability, "modifier_astolfo_indepedent_action_conditional_regen", {})
	else
		caster:AddNewModifier(caster, ability, "modifier_astolfo_indepedent_action_regen", {})
	end


end


function astolfo_independent_action:GetIntrinsicModifierName()
	return "modifier_astolfo_independent_action"
end

modifier_astolfo_independent_action = class({})

function modifier_astolfo_independent_action:IsHidden() return true end

function modifier_astolfo_independent_action:OnCreated(kv)
	if not IsServer() then return end
	self:StartIntervalThink(1)
end

function modifier_astolfo_independent_action:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_astolfo_independent_action:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: astolfo_ability / OnIAThink
	OnIAThink({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

modifier_astolfo_indepedent_action_regen = class({})

function modifier_astolfo_indepedent_action_regen:IsHidden() return true end

function modifier_astolfo_indepedent_action_regen:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
	}
end

function modifier_astolfo_indepedent_action_regen:GetModifierHealthRegenPercentage()
	return 0.5
end
function modifier_astolfo_indepedent_action_regen:GetModifierTotalPercentageManaRegen()
	return 0.8
end

function modifier_astolfo_indepedent_action_regen:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.033" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.033, true)
	end
end

function modifier_astolfo_indepedent_action_regen:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_astolfo_indepedent_action_conditional_regen = class({})

function modifier_astolfo_indepedent_action_conditional_regen:IsHidden() return true end

function modifier_astolfo_indepedent_action_conditional_regen:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
	}
end

function modifier_astolfo_indepedent_action_conditional_regen:GetModifierHealthRegenPercentage()
	return 1.5
end
function modifier_astolfo_indepedent_action_conditional_regen:GetModifierTotalPercentageManaRegen()
	return 3
end
function modifier_astolfo_indepedent_action_conditional_regen:GetModifierMoveSpeedBonus_Constant()
	return 300
end

function modifier_astolfo_indepedent_action_conditional_regen:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.033" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.033, true)
	end
end

function modifier_astolfo_indepedent_action_conditional_regen:OnRefresh(kv)
	self:OnCreated(kv)
end
