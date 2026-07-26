-- avenger_true_form — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_true_form = class({})

LinkLuaModifier("modifier_true_form", "abilities/avenger/avenger_true_form", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnTFStart, OnTFLevelUp, OnTFEnd, AvengerCheckCombo

OnTFStart = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	--local newMana = caster:GetMana() + 300
	for i=0,15 do
		if caster:GetAbilityByIndex(i) then
			print(caster:GetAbilityByIndex(i):GetName())
		end
	end
	caster:AddNewModifier(caster, keys.ability, "modifier_true_form", {}) 
	AvengerCheckCombo(keys.caster, keys.ability)
	--local a1 = caster:GetAbilityByIndex(0)
	--local a2 = caster:GetAbilityByIndex(1):GetAbilityName()
    caster:SwapAbilities("angra_murderous", "avenger_unlimited_remains", false, true) 
    --caster:SetMana(newMana)

    caster:SwapAbilities("avenger_true_form", "angra_puddle", false, true)
    if caster.IsBloodMarkAcquired then 
    	caster:SwapAbilities("fate_empty1", "avenger_blood_mark", false, true)
    end

    caster:SwapAbilities("avenger_tawrich_zarich", "avenger_vengeance_mark", false, true) 
    caster.OriginalModel = "models/avenger/trueform/trueform.vmdl"
    caster:SetModel("models/avenger/trueform/trueform.vmdl")
    caster:SetOriginalModel("models/avenger/trueform/trueform.vmdl")

    caster:SetModelScale(1.3)

    caster:EmitSound("Avenger.TransformShort")
end

OnTFLevelUp = function(keys)
	local caster = keys.caster
	caster:FindAbilityByName("angra_puddle"):SetLevel(keys.ability:GetLevel())
end

OnTFEnd = function(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
    caster:SwapAbilities("angra_murderous", "avenger_unlimited_remains", true, false) 
    local a2 = caster:GetAbilityByIndex(1):GetAbilityName()
    caster:SwapAbilities("avenger_tawrich_zarich", a2, true, false) 
    --[[if caster.IsBloodMarkAcquired then 
    	caster:SwapAbilities("avenger_true_form", "avenger_blood_mark", true, false) 
    end
    caster:SwapAbilities("fate_empty1", "avenger_demon_core", true, false)]]

    caster:SwapAbilities("avenger_true_form", "angra_puddle", true, false) 

    if caster.IsBloodMarkAcquired then 
    	caster:SwapAbilities("fate_empty1", "avenger_blood_mark", true, false)
    else
    end

    -- local demoncore = caster:FindAbilityByName("avenger_demon_core")
    -- if demoncore:GetToggleState() then
    -- 	demoncore:ToggleAbility()
    -- end
    caster.OriginalModel = "models/avenger/avenger_new.vmdl"
    caster:SetModel("models/avenger/avenger_new.vmdl")
    caster:SetOriginalModel("models/avenger/avenger_new.vmdl")

    caster:SetModelScale(1.5)
end

AvengerCheckCombo = function(caster, ability)
    if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
        if ability == caster:FindAbilityByName("avenger_true_form") and ability:GetAutoCastState() and caster:FindAbilityByName("angra_mainyu_verg_avesta"):IsCooldownReady() and caster:FindAbilityByName("avenger_endless_loop"):IsCooldownReady()  then
            caster:SwapAbilities("angra_mainyu_verg_avesta", "avenger_endless_loop", false, true) 
            Timers:CreateTimer({
                endTime = 3,
                callback = function()
                if caster:GetAbilityByIndex(5):GetName() ~= "angra_mainyu_verg_avesta" then
                    caster:SwapAbilities("angra_mainyu_verg_avesta", "avenger_endless_loop", true, false) 
                end
            end
            })
        end
    end
end


function avenger_true_form:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: avenger_ability / OnTFStart
	OnTFStart({
		caster = caster,
		ability = self,
		target = caster,
		BonusMana = self:GetSpecialValueFor("bonus_mana")
	})
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_transform.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
end

function avenger_true_form:OnUpgrade()
	local caster = self:GetCaster()
	-- DD RunScript: avenger_ability / OnTFLevelUp
	OnTFLevelUp({ caster = caster, ability = self, target = caster })
end

modifier_true_form = class({})

function modifier_true_form:GetEffectName() return "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis.vpcf" end
function modifier_true_form:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_true_form:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
	}
end

function modifier_true_form:GetModifierHealAmplify_PercentageTarget()
	return self:GetAbility():GetSpecialValueFor("bonus_healing_power")
end
function modifier_true_form:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_health")
end
function modifier_true_form:GetModifierHPRegenAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_healing_power")
end

function modifier_true_form:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_true_form:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_true_form:OnDestroy()
	if not IsServer() then return end
	-- DD RunScript: avenger_ability / OnTFEnd
	OnTFEnd({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end
