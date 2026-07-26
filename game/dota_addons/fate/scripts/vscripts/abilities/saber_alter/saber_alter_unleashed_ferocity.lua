-- saber_alter_unleashed_ferocity — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/saber_alter/saber_alter_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

saber_alter_unleashed_ferocity = class({})

LinkLuaModifier("modifier_unleashed_ferocity_caster_VFX_controller", "abilities/saber_alter/saber_alter_unleashed_ferocity", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_unleashed_ferocity_caster_VFX", "abilities/saber_alter/saber_alter_unleashed_ferocity", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/saber_alter_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnUFStart, OnUFCreateVfx, DSCheckCombo

OnUFStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local UFCount = 0
	local bonusDamage = 0

	if caster.IsFerocityImproved then
		bonusDamage = caster:GetStrength()*0.75 + caster:GetIntellect()*0.75
	end

	caster:EmitSound("saber_alter_other_03") 

	DSCheckCombo(caster, keys.ability)
	Timers:CreateTimer(function()
		if UFCount == 5 or not caster:IsAlive() then return end
		caster:EmitSound("Saber_Alter.Unleashed") 
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, keys.Radius
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
	         DoDamage(caster, v, v:GetHealth() * keys.Damage / 100 + bonusDamage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	         v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 0.1})
	    end
		UFCount = UFCount + 1;
		return 0.5
		end
	)

	caster:AddNewModifier(caster, ability, "modifier_unleashed_ferocity_caster_VFX_controller", {})
end

OnUFCreateVfx = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:AddNewModifier(caster, ability, "modifier_unleashed_ferocity_caster_VFX", {})
end

DSCheckCombo = function(caster, ability)
	if caster:HasModifier("modifier_arturia_alter_combo_window") then
		if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
	    	if caster:FindAbilityByName("saber_alter_max_mana_burst"):IsCooldownReady() and caster:FindAbilityByName("saber_alter_mana_burst"):IsCooldownReady() and caster:IsAlive() then	    		
	    		caster:SwapAbilities("saber_alter_max_mana_burst", "saber_alter_mana_burst", true, false)
	    		Timers:CreateTimer(3, function()
	    			caster:SwapAbilities("saber_alter_max_mana_burst", "saber_alter_mana_burst", false, true)
	    	    end)   		
	    	end
	    end
	end
end


function saber_alter_unleashed_ferocity:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function saber_alter_unleashed_ferocity:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: saber_alter_ability / OnUFStart
	OnUFStart({
		caster = caster,
		ability = self,
		target = caster,
		Radius = self:GetSpecialValueFor("radius"),
		Damage = self:GetSpecialValueFor("damage")
	})
end

modifier_unleashed_ferocity_caster_VFX_controller = class({})

function modifier_unleashed_ferocity_caster_VFX_controller:IsHidden() return true end
function modifier_unleashed_ferocity_caster_VFX_controller:IsPurgable() return false end

function modifier_unleashed_ferocity_caster_VFX_controller:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "2.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(2.0, true)
	end
	self:StartIntervalThink(0.5)
	-- DD RunScript: saber_alter_ability / OnUFCreateVfx
	OnUFCreateVfx({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

function modifier_unleashed_ferocity_caster_VFX_controller:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_unleashed_ferocity_caster_VFX_controller:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: saber_alter_ability / OnUFCreateVfx
	OnUFCreateVfx({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

modifier_unleashed_ferocity_caster_VFX = class({})

function modifier_unleashed_ferocity_caster_VFX:IsHidden() return true end
function modifier_unleashed_ferocity_caster_VFX:IsPurgable() return false end

function modifier_unleashed_ferocity_caster_VFX:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "0.1" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(0.1, true)
	end
	local fx = ParticleManager:CreateParticle("particles/custom/saber_alter/saber_alter_unleashed_ferocity.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(fx, 0, Vector(400, 3, 0))
	ParticleManager:SetParticleControl(fx, 1, Vector(self:GetAbility():GetSpecialValueFor("radius"), 0, 0))
	self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_unleashed_ferocity_caster_VFX:OnRefresh(kv)
	self:OnCreated(kv)
end
