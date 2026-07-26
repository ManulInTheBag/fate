-- avenger_overdrive — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/avenger/avenger_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

avenger_overdrive = class({})

LinkLuaModifier("modifier_overdrive", "abilities/avenger/avenger_overdrive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_overdrive_tier1", "abilities/avenger/avenger_overdrive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_overdrive_tier2", "abilities/avenger/avenger_overdrive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_overdrive_tier3", "abilities/avenger/avenger_overdrive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_overdrive_tier4", "abilities/avenger/avenger_overdrive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_overdrive_tier5", "abilities/avenger/avenger_overdrive", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_overdrive_tier6", "abilities/avenger/avenger_overdrive", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/avenger_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnOverdriveAttack

OnOverdriveAttack = function(keys)
	local caster = keys.caster
	if caster:HasModifier("modifier_overdrive_tier1") or caster:HasModifier("modifier_overdrive_tier2") or caster:HasModifier("modifier_overdrive_tier3") or caster:HasModifier("modifier_overdrive_tier4") or caster:HasModifier("modifier_overdrive_tier5") or caster:HasModifier("modifier_overdrive_tier6") then

	else
		caster:AddNewModifier(caster, keys.ability, "modifier_overdrive_tier1", {}) 
	end
end


function avenger_overdrive:GetIntrinsicModifierName()
	return "modifier_overdrive"
end

modifier_overdrive = class({})

function modifier_overdrive:IsHidden() return false end

function modifier_overdrive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function modifier_overdrive:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	-- DD RunScript: avenger_ability / OnOverdriveAttack
	OnOverdriveAttack({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		attacker = params.attacker,
		target = params.target
	})
end

modifier_overdrive_tier1 = class({})

function modifier_overdrive_tier1:IsHidden() return true end

function modifier_overdrive_tier1:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function modifier_overdrive_tier1:GetModifierAttackSpeedBonus_Constant()
	return 20
end

function modifier_overdrive_tier1:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_overdrive_tier1:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_overdrive_tier1:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_overdrive_tier2", {})
	self:GetCaster():RemoveModifierByName("modifier_overdrive_tier1")
end

modifier_overdrive_tier2 = class({})

function modifier_overdrive_tier2:IsHidden() return true end

function modifier_overdrive_tier2:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function modifier_overdrive_tier2:GetModifierAttackSpeedBonus_Constant()
	return 40
end

function modifier_overdrive_tier2:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_overdrive_tier2:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_overdrive_tier2:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_overdrive_tier3", {})
	self:GetCaster():RemoveModifierByName("modifier_overdrive_tier2")
end

modifier_overdrive_tier3 = class({})

function modifier_overdrive_tier3:IsHidden() return true end

function modifier_overdrive_tier3:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function modifier_overdrive_tier3:GetModifierAttackSpeedBonus_Constant()
	return 80
end

function modifier_overdrive_tier3:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_overdrive_tier3:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_overdrive_tier3:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_overdrive_tier4", {})
	self:GetCaster():RemoveModifierByName("modifier_overdrive_tier3")
end

modifier_overdrive_tier4 = class({})

function modifier_overdrive_tier4:IsHidden() return true end

function modifier_overdrive_tier4:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function modifier_overdrive_tier4:GetModifierAttackSpeedBonus_Constant()
	return 160
end

function modifier_overdrive_tier4:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_overdrive_tier4:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_overdrive_tier4:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_overdrive_tier5", {})
	self:GetCaster():RemoveModifierByName("modifier_overdrive_tier4")
end

modifier_overdrive_tier5 = class({})

function modifier_overdrive_tier5:IsHidden() return true end

function modifier_overdrive_tier5:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function modifier_overdrive_tier5:GetModifierAttackSpeedBonus_Constant()
	return 320
end

function modifier_overdrive_tier5:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_overdrive_tier5:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_overdrive_tier5:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_overdrive_tier6", {})
	self:GetCaster():RemoveModifierByName("modifier_overdrive_tier5")
end

modifier_overdrive_tier6 = class({})

function modifier_overdrive_tier6:IsHidden() return true end

function modifier_overdrive_tier6:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_START,
	}
end

function modifier_overdrive_tier6:GetModifierAttackSpeedBonus_Constant()
	return 640
end

function modifier_overdrive_tier6:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
end

function modifier_overdrive_tier6:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_overdrive_tier6:OnAttackStart(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_overdrive_tier6", {})
end
