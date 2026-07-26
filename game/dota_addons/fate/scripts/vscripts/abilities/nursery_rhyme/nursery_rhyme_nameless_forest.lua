-- nursery_rhyme_nameless_forest — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/nursery_rhyme/nursery_rhyme_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

nursery_rhyme_nameless_forest = class({})

LinkLuaModifier("modifier_nameless_forest", "abilities/nursery_rhyme/nursery_rhyme_nameless_forest", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nameless_forest_stat_steal_debuff", "abilities/nursery_rhyme/nursery_rhyme_nameless_forest", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nameless_forest_stat_steal_buff", "abilities/nursery_rhyme/nursery_rhyme_nameless_forest", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nameless_forest_mana_regen", "abilities/nursery_rhyme/nursery_rhyme_nameless_forest", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/nursery_rhyme_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnNamelessStart, OnNamelessDebuffStart, OnNamelessEnd

OnNamelessStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		if IsSpellBlocked(target, caster) or target:IsMagicImmune() then return end -- Linken effect checker
	end
	caster.NamelessTarget = target
	ApplyPurge(target)
	target:AddNewModifier(caster, ability, "modifier_nameless_forest", {})

	if caster.bIsReminiscenceAcquired then
		caster:SwapAbilities("nursery_rhyme_nameless_forest", "nursery_rhyme_reminiscence", false, true)
	end
end

OnNamelessDebuffStart = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	target:AddEffects(EF_NODRAW)
	target:EmitSound("Hero_Winter_Wyvern.ColdEmbrace")
end

OnNamelessEnd = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	target:RemoveEffects(EF_NODRAW)
	target:StopSound("Hero_Winter_Wyvern.ColdEmbrace")
	if caster.bIsReminiscenceAcquired then
		caster:SwapAbilities("nursery_rhyme_nameless_forest", "nursery_rhyme_reminiscence", true, false)
		caster:AddNewModifier(caster, ability, "modifier_nameless_forest_stat_steal_buff", {})
		target:AddNewModifier(caster, ability, "modifier_nameless_forest_stat_steal_debuff", {})
	end
end


function nursery_rhyme_nameless_forest:GetIntrinsicModifierName()
	return "modifier_nameless_forest_mana_regen"
end

function nursery_rhyme_nameless_forest:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: nursery_rhyme_ability / OnNamelessStart
	OnNamelessStart({ caster = caster, ability = self, target = target })
end

modifier_nameless_forest = class({})

function modifier_nameless_forest:IsDebuff() return true end
function modifier_nameless_forest:GetEffectName() return "particles/units/heroes/hero_winter_wyvern/wyvern_cold_embrace_buff.vpcf" end
function modifier_nameless_forest:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_nameless_forest:CheckState()
	return {
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_SILENCED] = false,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_nameless_forest:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
	-- DD RunScript: nursery_rhyme_ability / OnNamelessDebuffStart
	OnNamelessDebuffStart({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

function modifier_nameless_forest:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_nameless_forest:OnDestroy()
	if not IsServer() then return end
	-- DD RunScript: nursery_rhyme_ability / OnNamelessEnd
	OnNamelessEnd({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

modifier_nameless_forest_stat_steal_debuff = class({})

function modifier_nameless_forest_stat_steal_debuff:IsDebuff() return true end

function modifier_nameless_forest_stat_steal_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function modifier_nameless_forest_stat_steal_debuff:GetModifierBonusStats_Strength()
	return 0
end
function modifier_nameless_forest_stat_steal_debuff:GetModifierBonusStats_Agility()
	return 0
end
function modifier_nameless_forest_stat_steal_debuff:GetModifierBonusStats_Intellect()
	return 0
end

function modifier_nameless_forest_stat_steal_debuff:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "20" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(20, true)
	end
end

function modifier_nameless_forest_stat_steal_debuff:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_nameless_forest_stat_steal_buff = class({})


function modifier_nameless_forest_stat_steal_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function modifier_nameless_forest_stat_steal_buff:GetModifierBonusStats_Strength()
	return 0
end
function modifier_nameless_forest_stat_steal_buff:GetModifierBonusStats_Agility()
	return 0
end
function modifier_nameless_forest_stat_steal_buff:GetModifierBonusStats_Intellect()
	return 0
end

function modifier_nameless_forest_stat_steal_buff:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "20" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(20, true)
	end
end

function modifier_nameless_forest_stat_steal_buff:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_nameless_forest_mana_regen = class({})

function modifier_nameless_forest_mana_regen:IsHidden() return true end

function modifier_nameless_forest_mana_regen:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
	}
end

function modifier_nameless_forest_mana_regen:GetModifierTotalPercentageManaRegen()
	if self:GetAbility():GetLevel() < 1 then return 0 end
	return self:GetAbility():GetSpecialValueFor("mana_regen")
end
