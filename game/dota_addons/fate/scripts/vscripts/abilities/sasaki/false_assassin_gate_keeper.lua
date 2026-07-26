-- false_assassin_gate_keeper — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/sasaki/sasaki_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

false_assassin_gate_keeper = class({})

LinkLuaModifier("modifier_gate_keeper_self_buff", "abilities/sasaki/false_assassin_gate_keeper", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/fa_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnGKStart, FACheckCombo

OnGKStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	FACheckCombo(keys.caster, keys.ability)
	if caster.IsQuickdrawAcquired then 
		caster:SwapAbilities("false_assassin_gate_keeper", "false_assassin_quickdraw", false, true) 
		Timers:CreateTimer(5, function() return caster:SwapAbilities("false_assassin_gate_keeper", "false_assassin_quickdraw", true, false)   end)
	end

	local vision = ability:GetSpecialValueFor("bonus_sight")

	if caster.IsEyeOfSerenityAcquired then caster.IsEyeOfSerenityActive = true end

	caster:AddNewModifier(caster, ability, "modifier_gate_keeper_self_buff", {})

	local gkdummy = CreateUnitByName("sight_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	gkdummy:SetDayTimeVisionRange(caster:GetDayTimeVisionRange() + vision)
	gkdummy:SetNightTimeVisionRange(caster:GetNightTimeVisionRange() + vision)

	local gkdummypassive = gkdummy:FindAbilityByName("dummy_unit_passive")
	gkdummypassive:SetLevel(1)

	local eyeCounter = 0

	Timers:CreateTimer(function() 
		if eyeCounter > 5.0 then 
			caster.IsEyeOfSerenityActive = false
			DummyEnd(gkdummy) 
			return 
		end
		gkdummy:SetAbsOrigin(caster:GetAbsOrigin()) 
		eyeCounter = eyeCounter + 0.2
		return 0.2
	end)

end

FACheckCombo = function(caster, ability)
	if caster:GetStrength() >= 24.1 and caster:GetAgility() >= 24.1 then
		if ability == caster:FindAbilityByName("false_assassin_gate_keeper") and caster:FindAbilityByName("false_assassin_heart_of_harmony"):IsCooldownReady() and caster:FindAbilityByName("false_assassin_tsubame_mai"):IsCooldownReady() then
			caster:SwapAbilities("false_assassin_heart_of_harmony", "false_assassin_tsubame_mai", false, true) 
			Timers:CreateTimer({
				endTime = 3,
				callback = function()
				caster:SwapAbilities("false_assassin_heart_of_harmony", "false_assassin_tsubame_mai", true, false) 
			end
			})			
		end
	end
end


function false_assassin_gate_keeper:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: fa_ability / OnGKStart
	OnGKStart({ caster = caster, ability = self, target = caster })
	EmitSoundOn("Hero_TemplarAssassin.Refraction", caster)
end

modifier_gate_keeper_self_buff = class({})


function modifier_gate_keeper_self_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_BONUS_DAY_VISION,
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
	}
end

function modifier_gate_keeper_self_buff:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end
function modifier_gate_keeper_self_buff:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("mana_regen")
end
function modifier_gate_keeper_self_buff:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end
function modifier_gate_keeper_self_buff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movespeed_decrease")
end
function modifier_gate_keeper_self_buff:GetBonusDayVision()
	return self:GetAbility():GetSpecialValueFor("bonus_sight")
end
function modifier_gate_keeper_self_buff:GetBonusNightVision()
	return self:GetAbility():GetSpecialValueFor("bonus_sight")
end

function modifier_gate_keeper_self_buff:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start_f.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	self:AddParticle(fx, false, false, -1, false, false)
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_brewmaster/brewmaster_primal_split_storm_image.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
	ParticleManager:SetParticleControlEnt(fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_gate_keeper_self_buff:OnRefresh(kv)
	self:OnCreated(kv)
end
