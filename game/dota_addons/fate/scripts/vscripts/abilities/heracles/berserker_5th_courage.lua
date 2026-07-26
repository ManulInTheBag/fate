-- berserker_5th_courage — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/heracles/heracles_old_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

berserker_5th_courage = class({})

LinkLuaModifier("modifier_courage_armor_reduction", "abilities/heracles/berserker_5th_courage", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_courage_attack_damage_debuff", "abilities/heracles/berserker_5th_courage", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_courage_attack_damage_buff", "abilities/heracles/berserker_5th_courage", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_courage_damage_stack_indicator", "abilities/heracles/berserker_5th_courage", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_courage_stackable_buff", "abilities/heracles/berserker_5th_courage", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/berserker_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnCourageStart, OnCourageAttackLanded, OnCourageBuffEnded, DeductCourageDamageStack

OnCourageStart = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local radius = 400
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		-- Apply armor reduction and damage reduction buff to nearby enemies
		v:AddNewModifier(caster, ability, "modifier_courage_armor_reduction", {}) 
		v:AddNewModifier(caster, ability, "modifier_courage_attack_damage_debuff", {}) 
	end 

	-- Apply stackable speed buff
	local currentStack = caster:GetModifierStackCount("modifier_courage_stackable_buff", keys.ability)
	if currentStack == 0 and caster:HasModifier("modifier_courage_stackable_buff") then 
		currentStack = 1 
	elseif currentStack == keys.MaxStack then 
		currentStack = currentStack-1 
	end

	RemoveSlowEffect(caster)

	caster:EmitSound("Heracles_Roar_" .. math.random(1,6))
	caster:RemoveModifierByName("modifier_courage_stackable_buff") 
	caster:AddNewModifier(caster, keys.ability, "modifier_courage_stackable_buff", {}) 
	caster:SetModifierStackCount("modifier_courage_stackable_buff", keys.ability, currentStack + 1)

	-- Apply damage buff indicator
	caster:RemoveModifierByName("modifier_courage_damage_stack_indicator")
	caster:AddNewModifier(caster, ability, "modifier_courage_damage_stack_indicator", {}) 
	caster:SetModifierStackCount("modifier_courage_damage_stack_indicator", ability, 9)

	-- Apply damage buff
	caster:AddNewModifier(caster, ability, "modifier_courage_attack_damage_buff", {}) 

	-- Reduce Nine Lives cooldown if applicable
	if caster.IsEternalRageAcquired then
		ReduceCooldown(caster:FindAbilityByName("heracles_nine_lives"), 5)
	end

	caster.courage_particle = ParticleManager:CreateParticle("particles/custom/berserker/courage/buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(caster.courage_particle, 1, Vector(currentStack + 1,1,1))
	ParticleManager:SetParticleControl(caster.courage_particle, 3, Vector(radius,1,1))
end

OnCourageAttackLanded = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	DeductCourageDamageStack(caster)
end

OnCourageBuffEnded = function(keys)
	ParticleManager:DestroyParticle(keys.caster.courage_particle, false)
	keys.caster.courage_particle = nil
end

DeductCourageDamageStack = function(caster)
	local courageAbility = caster:FindAbilityByName("berserker_5th_courage")
	-- Deduce a stack from damage buff
	local currentStack = caster:GetModifierStackCount("modifier_courage_damage_stack_indicator", courageAbility)
	if currentStack == 1 then
		caster:RemoveModifierByName("modifier_courage_damage_stack_indicator")
	else
		caster:SetModifierStackCount("modifier_courage_damage_stack_indicator", courageAbility, currentStack-1)
	end
end


function berserker_5th_courage:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: berserker_ability / OnCourageStart
	OnCourageStart({
		caster = caster,
		ability = self,
		target = caster,
		MaxStack = self:GetSpecialValueFor("max_stack")
	})
	EmitSoundOn("Hero_Axe.Berserkers_Call", caster)
end

modifier_courage_armor_reduction = class({})

function modifier_courage_armor_reduction:IsDebuff() return true end

function modifier_courage_armor_reduction:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_courage_armor_reduction:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("armor_reduction")
end

function modifier_courage_armor_reduction:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_courage_armor_reduction:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_courage_attack_damage_debuff = class({})

function modifier_courage_attack_damage_debuff:IsDebuff() return true end
function modifier_courage_attack_damage_debuff:GetEffectName() return "particles/custom/berserker/courage/debuff.vpcf" end
function modifier_courage_attack_damage_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_courage_attack_damage_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_courage_attack_damage_debuff:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("damage_reduction")
end

function modifier_courage_attack_damage_debuff:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_courage_attack_damage_debuff:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_courage_attack_damage_buff = class({})

function modifier_courage_attack_damage_buff:IsHidden() return true end
function modifier_courage_attack_damage_buff:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_courage_attack_damage_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_courage_attack_damage_buff:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_courage_attack_damage_buff:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_courage_attack_damage_buff:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_courage_attack_damage_buff:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	-- DD RunScript: berserker_ability / OnCourageAttackLanded
	OnCourageAttackLanded({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		attacker = params.attacker,
		target = params.target
	})
end

modifier_courage_damage_stack_indicator = class({})

function modifier_courage_damage_stack_indicator:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_courage_damage_stack_indicator:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_courage_damage_stack_indicator:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_courage_damage_stack_indicator:OnDestroy()
	if not IsServer() then return end
	self:GetCaster():RemoveModifierByName("modifier_courage_attack_damage_buff")
end

modifier_courage_stackable_buff = class({})

function modifier_courage_stackable_buff:IsDebuff() return true end
function modifier_courage_stackable_buff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_courage_stackable_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_courage_stackable_buff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("aspd_bonus")
end
function modifier_courage_stackable_buff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("ms_bonus")
end
function modifier_courage_stackable_buff:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("str_debuff")
end

function modifier_courage_stackable_buff:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_courage_stackable_buff:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_courage_stackable_buff:OnDestroy()
	if not IsServer() then return end
	-- DD RunScript: berserker_ability / OnCourageBuffEnded
	OnCourageBuffEnded({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end
