-- lishuwen_martial_arts — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/li_shuwen/li_shuwen_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lishuwen_martial_arts = class({})

LinkLuaModifier("modifier_martial_arts_aura", "abilities/li_shuwen/lishuwen_martial_arts", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_martial_arts_aura_enemy", "abilities/li_shuwen/lishuwen_martial_arts", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mark_of_fatality", "abilities/li_shuwen/lishuwen_martial_arts", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_martial_arts_critical", "abilities/li_shuwen/lishuwen_martial_arts", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_martial_arts_crit_hit", "abilities/li_shuwen/lishuwen_martial_arts", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_furious_chain_buff", "abilities/li_shuwen/lishuwen_martial_arts", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/lishuwen_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnMartialStart, AuraRefresh, OnMartialAttackStart, OnMartialAttackLanded, ApplyMarkOfFatality

OnMartialStart = function(keys)

	local caster = keys.caster

	local target = keys.target

	local duration = keys.Duration

	if IsSpellBlocked(keys.target, caster) then return end -- Linken effect checker

	giveUnitDataDrivenModifier(caster, target, "silenced", duration)

	ApplyMarkOfFatality(caster, target)

	--[[if caster:GetName() == "npc_dota_hero_bloodseeker" then

		GrantCosmicOrbitResist(caster)

		if caster.bIsFuriousChainAcquired then

			GrantFuriousChainBuff(caster) 

		end

	end]]

    local pcMark = ParticleManager:CreateParticle("particles/econ/items/axe/axe_cinder/axe_cinder_battle_hunger_start.vpcf", PATTACH_OVERHEAD_FOLLOW, target)

    ParticleManager:ReleaseParticleIndex(pcMark)

	target:EmitSound("Hero_Nightstalker.Void")

end

AuraRefresh = function(keys)

	local hero = keys.caster:GetPlayerOwner():GetAssignedHero()

	hero:RemoveModifierByName("modifier_martial_arts_aura") 

	hero:AddNewModifier(hero, hero:FindAbilityByName("lishuwen_martial_arts"), "modifier_martial_arts_aura", {}) 

end

OnMartialAttackStart = function(keys)

	local caster = keys.caster

	local target = keys.target

	local chance = keys.Chance

	local ability = keys.ability

	if not target:HasModifier("modifier_mark_of_fatality") then return end

	local stacks = target:FindModifierByName("modifier_mark_of_fatality"):GetStackCount()

	chance = stacks * chance

	local roll = math.random(100)

	if roll < chance then

		caster:AddNewModifier(caster, ability, "modifier_martial_arts_crit_hit", {})

	end

end

OnMartialAttackLanded = function(keys)

	local caster = keys.caster

	local target = keys.target

	local ability = keys.ability

	if ability:GetLevel() == 2 and target:HasModifier("modifier_mark_of_fatality") then

		DoDamage(caster, target, target:GetMaxHealth() * 3.5/100, DAMAGE_TYPE_MAGICAL, 0, ability, false)

	end



end

ApplyMarkOfFatality = function(caster,target)

	local abil = caster:FindAbilityByName("lishuwen_martial_arts")



	SpawnAttachedVisionDummy(caster, target, abil:GetLevelSpecialValueFor("vision_radius", abil:GetLevel()-1 ), abil:GetLevelSpecialValueFor("duration", abil:GetLevel()-1 ), false)



	-- add new stack

	local currentStack = target:GetModifierStackCount("modifier_mark_of_fatality", abil)

	target:RemoveModifierByName("modifier_mark_of_fatality") 

	target:AddNewModifier(caster, abil, "modifier_mark_of_fatality", {}) 

	target:SetModifierStackCount("modifier_mark_of_fatality", abil, currentStack + 1)

end


function lishuwen_martial_arts:GetIntrinsicModifierName()
	return "modifier_martial_arts_aura"
end

function lishuwen_martial_arts:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: lishuwen_ability / OnMartialStart
	OnMartialStart({
		caster = caster,
		ability = self,
		target = self:GetCursorTarget(),
		Duration = self:GetSpecialValueFor("silence_duration")
	})
end

modifier_martial_arts_aura = class({})

function modifier_martial_arts_aura:IsHidden() return true end

-- В datadriven пассивных модификаторов было два (modifier_martial_arts_aura и modifier_martial_arts_critical);
-- интринсик в ability_lua только один, поэтому второй вешаем отсюда.
function modifier_martial_arts_aura:OnCreated(kv)
	if not IsServer() then return end
	if not self:GetParent():HasModifier("modifier_martial_arts_critical") then
		self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_martial_arts_critical", {})
	end
end

function modifier_martial_arts_aura:OnRefresh(kv)
	self:OnCreated(kv)
end


function modifier_martial_arts_aura:IsAura() return true end
function modifier_martial_arts_aura:GetModifierAura() return "modifier_martial_arts_aura_enemy" end
function modifier_martial_arts_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("search_radius") end
function modifier_martial_arts_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_martial_arts_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end

function modifier_martial_arts_aura:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_RESPAWN,
	}
end

function modifier_martial_arts_aura:OnRespawn(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: lishuwen_ability / AuraRefresh
	AuraRefresh({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

modifier_martial_arts_aura_enemy = class({})

function modifier_martial_arts_aura_enemy:IsHidden() return true end
function modifier_martial_arts_aura_enemy:IsDebuff() return true end

modifier_mark_of_fatality = class({})

function modifier_mark_of_fatality:IsDebuff() return true end
function modifier_mark_of_fatality:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_mark_of_fatality:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_mark_of_fatality:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_martial_arts_critical = class({})

function modifier_martial_arts_critical:IsHidden() return false end

function modifier_martial_arts_critical:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_martial_arts_critical:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	self:GetCaster():RemoveModifierByName("modifier_martial_arts_crit_hit")
	-- DD RunScript: lishuwen_ability / OnMartialAttackStart
	OnMartialAttackStart({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		attacker = params.attacker,
		target = params.target,
		Chance = self:GetAbility():GetSpecialValueFor("critical_rate_percentage")
	})
end

function modifier_martial_arts_critical:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	-- DD RunScript: lishuwen_ability / OnMartialAttackLanded
	OnMartialAttackLanded({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		attacker = params.attacker,
		target = params.target
	})
end

modifier_martial_arts_crit_hit = class({})

function modifier_martial_arts_crit_hit:IsHidden() return true end
function modifier_martial_arts_crit_hit:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_martial_arts_crit_hit:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_martial_arts_crit_hit:GetModifierPreAttack_CriticalStrike()
	return self:GetAbility():GetSpecialValueFor("critical_damage")
end

function modifier_martial_arts_crit_hit:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/jugg_crit_blur_impact.vpcf", PATTACH_POINT, params.target)
	ParticleManager:ReleaseParticleIndex(fx)
	self:GetCaster():RemoveModifierByName("modifier_martial_arts_crit_hit")
end

modifier_furious_chain_buff = class({})

function modifier_furious_chain_buff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_furious_chain_buff:GetEffectName() return "particles/units/heroes/hero_bristleback/bristleback_warpath.vpcf" end
function modifier_furious_chain_buff:GetEffectAttachType() return PATTACH_POINT end

function modifier_furious_chain_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_furious_chain_buff:GetModifierAttackSpeedBonus_Constant()
	return 20
end
function modifier_furious_chain_buff:GetModifierMoveSpeedBonus_Percentage()
	return 5
end

function modifier_furious_chain_buff:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "5" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(5, true)
	end
end

function modifier_furious_chain_buff:OnRefresh(kv)
	self:OnCreated(kv)
end
