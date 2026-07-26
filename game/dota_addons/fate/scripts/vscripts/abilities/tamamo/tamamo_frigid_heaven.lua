-- tamamo_frigid_heaven — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/tamamo/tamamo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

tamamo_frigid_heaven = class({})

LinkLuaModifier("modifier_frigid_heaven_indicator", "abilities/tamamo/tamamo_frigid_heaven", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_frigid_heaven_indicator_enemy", "abilities/tamamo/tamamo_frigid_heaven", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_frigid_heaven_slow", "abilities/tamamo/tamamo_frigid_heaven", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_frigid_heaven_stun_fx", "abilities/tamamo/tamamo_frigid_heaven", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/tamamo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnFreezeCharmLoaded, CloseCharmList

OnFreezeCharmLoaded = function(keys)
	local caster = keys.caster
	CharmHandle = keys.ability
	CurrentCharmName = "modifier_frigid_heaven_indicator"
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
	caster:AddNewModifier(caster, keys.ability, "modifier_frigid_heaven_indicator", {}) 
	--caster:SetModifierStackCount("modifier_frigid_heaven_indicator", keys.ability, chargeAmount)
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


function tamamo_frigid_heaven:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: tamamo_ability / OnFreezeCharmLoaded
	OnFreezeCharmLoaded({ caster = caster, ability = self, target = caster })
end

function tamamo_frigid_heaven:OnOwnerSpawned()
	local caster = self:GetCaster()
	-- (DD-событие было пустым)
end

modifier_frigid_heaven_indicator = class({})

function modifier_frigid_heaven_indicator:RemoveOnDeath() return false end
function modifier_frigid_heaven_indicator:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

modifier_frigid_heaven_indicator_enemy = class({})

function modifier_frigid_heaven_indicator_enemy:IsDebuff() return true end
function modifier_frigid_heaven_indicator_enemy:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_frigid_heaven_indicator_enemy:GetEffectName() return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf" end
function modifier_frigid_heaven_indicator_enemy:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_frigid_heaven_indicator_enemy:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "10" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(10, true)
	end
end

function modifier_frigid_heaven_indicator_enemy:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_frigid_heaven_slow = class({})

function modifier_frigid_heaven_slow:IsDebuff() return true end

function modifier_frigid_heaven_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_frigid_heaven_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_frigid_heaven_slow:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_frigid_heaven_slow:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_frigid_heaven_stun_fx = class({})

function modifier_frigid_heaven_stun_fx:IsHidden() return true end
function modifier_frigid_heaven_stun_fx:IsDebuff() return true end
function modifier_frigid_heaven_stun_fx:GetEffectName() return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf" end
function modifier_frigid_heaven_stun_fx:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_frigid_heaven_stun_fx:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%stack_stun_duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("stack_stun_duration"), true)
	end
end

function modifier_frigid_heaven_stun_fx:OnRefresh(kv)
	self:OnCreated(kv)
end
