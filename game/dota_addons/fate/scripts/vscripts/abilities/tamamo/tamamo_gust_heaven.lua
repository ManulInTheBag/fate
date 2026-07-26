-- tamamo_gust_heaven — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/tamamo/tamamo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

tamamo_gust_heaven = class({})

LinkLuaModifier("modifier_gust_heaven_indicator", "abilities/tamamo/tamamo_gust_heaven", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gust_heaven_indicator_enemy", "abilities/tamamo/tamamo_gust_heaven", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gust_heaven_purge", "abilities/tamamo/tamamo_gust_heaven", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gust_heaven_purge_slow_tier1", "abilities/tamamo/tamamo_gust_heaven", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gust_heaven_purge_slow_tier2", "abilities/tamamo/tamamo_gust_heaven", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/tamamo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnGustCharmLoaded, CloseCharmList

OnGustCharmLoaded = function(keys)
	local caster = keys.caster
	CharmHandle = keys.ability
	CurrentCharmName = "modifier_gust_heaven_indicator"
	local fieryHeaven = caster:FindAbilityByName("tamamo_fiery_heaven")
	local frigidHeaven = caster:FindAbilityByName("tamamo_frigid_heaven")
	local gustHeaven = caster:FindAbilityByName("tamamo_gust_heaven")
	local voidHeaven = caster:FindAbilityByName("tamamo_void_heaven")
	fieryHeaven:StartCooldown(5)
	frigidHeaven:StartCooldown(5)
	gustHeaven:StartCooldown(5)
	voidHeaven:StartCooldown(5)
	CloseCharmList(keys)
	if caster.IsWitchcraftAcquired then
		local armedUp = caster:FindAbilityByName("tamamo_armed_up")
		armedUp:EndCooldown()
		--armedUp:StartCooldown(15)
		fieryHeaven:EndCooldown()
		--fieryHeaven:StartCooldown(15)
		frigidHeaven:EndCooldown()
		--frigidHeaven:StartCooldown(15)
		gustHeaven:EndCooldown()
		--gustHeaven:StartCooldown(15)
		voidHeaven:EndCooldown()
	end

	for i=1, #CharmModifierList do
		if caster:HasModifier(CharmModifierList[i]) then
			caster:RemoveModifierByName(CharmModifierList[i])
		end
	end
	-- Apply stacks
	--local chargeAmount = caster:FindAbilityByName("tamamo_armed_up"):GetLevelSpecialValueFor("charge", 0)
	caster:AddNewModifier(caster, keys.ability, "modifier_gust_heaven_indicator", {}) 
	--caster:SetModifierStackCount("modifier_gust_heaven_indicator", keys.ability, chargeAmount)
end

CloseCharmList = function(keys)
	local caster = keys.caster

	local a1 = caster:FindAbilityByName("tamamo_fiery_heaven") -- Soulstream 
	local a2 = caster:FindAbilityByName("tamamo_frigid_heaven") -- Subterranean Grasp
	local a3 = caster:FindAbilityByName("tamamo_gust_heaven") -- Mantra
	local a4 = caster:FindAbilityByName("tamamo_void_heaven") -- Armed Up
	local a5 = caster:FindAbilityByName("tamamo_close_spellbook") -- fate_empty1
	local a6 = caster:FindAbilityByName("fate_empty2") -- Amaterasu


	caster:SwapAbilities("tamamo_soul_stream", a1:GetName(), true, false) 
	caster:SwapAbilities("tamamo_subterranean_grasp", a2:GetName(), true, false) 
	if caster.bIsShackleAvailable then
		caster:SwapAbilities("tamamo_mystic_shackle", a3:GetName(), true, false) 
	else
		caster:SwapAbilities("tamamo_mantra", a3:GetName(), true, false) 
	end
	caster:SwapAbilities("tamamo_castration_fist", a4:GetName(), true, false) 
	caster:SwapAbilities("tamamo_armed_up", a5:GetName(), true,false) 
	--caster:SwapAbilities("tamamo_amaterasu", a6:GetName(), true, false) 
end


function tamamo_gust_heaven:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: tamamo_ability / OnGustCharmLoaded
	OnGustCharmLoaded({ caster = caster, ability = self, target = caster })
end

function tamamo_gust_heaven:OnOwnerSpawned()
	local caster = self:GetCaster()
	-- (DD-событие было пустым)
end

modifier_gust_heaven_indicator = class({})

function modifier_gust_heaven_indicator:RemoveOnDeath() return false end
function modifier_gust_heaven_indicator:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

modifier_gust_heaven_indicator_enemy = class({})

function modifier_gust_heaven_indicator_enemy:IsDebuff() return true end
function modifier_gust_heaven_indicator_enemy:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_gust_heaven_indicator_enemy:GetEffectName() return "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf" end
function modifier_gust_heaven_indicator_enemy:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_gust_heaven_indicator_enemy:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_gust_heaven_indicator_enemy:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("mr_reduction")
end

function modifier_gust_heaven_indicator_enemy:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "10" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(10, true)
	end
end

function modifier_gust_heaven_indicator_enemy:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_gust_heaven_purge = class({})

function modifier_gust_heaven_purge:IsDebuff() return true end
function modifier_gust_heaven_purge:GetEffectName() return "particles/generic_gameplay/generic_purge.vpcf" end
function modifier_gust_heaven_purge:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_gust_heaven_purge:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end

function modifier_gust_heaven_purge:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%stack_lock_duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("stack_lock_duration"), true)
	end
end

function modifier_gust_heaven_purge:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_gust_heaven_purge_slow_tier1 = class({})

function modifier_gust_heaven_purge_slow_tier1:IsDebuff() return true end
function modifier_gust_heaven_purge_slow_tier1:GetEffectName() return "particles/generic_gameplay/generic_purge.vpcf" end
function modifier_gust_heaven_purge_slow_tier1:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_gust_heaven_purge_slow_tier1:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_gust_heaven_purge_slow_tier1:GetModifierMoveSpeedBonus_Percentage()
	return -80
end

function modifier_gust_heaven_purge_slow_tier1:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.5" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.5, true)
	end
end

function modifier_gust_heaven_purge_slow_tier1:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_gust_heaven_purge_slow_tier2 = class({})

function modifier_gust_heaven_purge_slow_tier2:IsDebuff() return true end
function modifier_gust_heaven_purge_slow_tier2:GetEffectName() return "particles/generic_gameplay/generic_purge.vpcf" end
function modifier_gust_heaven_purge_slow_tier2:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_gust_heaven_purge_slow_tier2:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_gust_heaven_purge_slow_tier2:GetModifierMoveSpeedBonus_Percentage()
	return -30
end

function modifier_gust_heaven_purge_slow_tier2:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%stack_slow_duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("stack_slow_duration"), true)
	end
end

function modifier_gust_heaven_purge_slow_tier2:OnRefresh(kv)
	self:OnCreated(kv)
end
