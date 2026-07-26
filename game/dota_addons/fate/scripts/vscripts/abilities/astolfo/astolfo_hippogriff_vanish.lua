-- astolfo_hippogriff_vanish — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/astolfo/astolfo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

astolfo_hippogriff_vanish = class({})

LinkLuaModifier("modifier_hippogriff_vanish_banish", "abilities/astolfo/astolfo_hippogriff_vanish", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_astolfo_vanish", "abilities/astolfo/modifiers/modifier_astolfo_vanish", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/astolfo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnVanishStart, OnVanishHit, OnVanishDebuffStart, OnVanishDebuffEnd

OnVanishStart = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if caster:HasModifier("modifier_hippogriff_ride_ascended") then 
		ability:EndCooldown()
		caster:GiveMana(ability:GetManaCost(1)) 
		return 
	end 
	local info = {
		Target = target, -- chainTarget
		Source = caster, -- chainSource
		Ability = ability,
		EffectName = "particles/custom/astolfo/astolfo_hippogriff_vanish.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = 2500
	}
	ProjectileManager:CreateTrackingProjectile(info) 

	caster:EmitSound("Astolfo_Snatch_" .. RandomInt(1,4))
	caster:EmitSound("Hero_Mirana.Leap.MoonGriffon")

	if caster.bIsSanityAcquired and ability:GetAutoCastState() then		
		caster:AddNewModifier(caster, ability, "modifier_astolfo_vanish", { Duration = 0.75 })
		caster:AddEffects(EF_NODRAW)

		Timers:CreateTimer(0.75, function()
			caster:RemoveEffects(EF_NODRAW)
			return
		end)
	end
end

OnVanishHit = function(keys)
	local target = keys.target
	if IsSpellBlocked(target, keys.caster)
		or target:IsMagicImmune()
	then
		return
	end -- Linken effect checker
	local caster = keys.caster
	local ability = keys.ability
	local damage = keys.Damage

	if caster.bIsSanityAcquired and ability:GetAutoCastState() then
		caster:SetAbsOrigin(target:GetAbsOrigin())
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	end

	ApplyPurge(target)
	DoDamage(caster, target, damage , DAMAGE_TYPE_MAGICAL, 0, ability, false)
	target:AddNewModifier(caster, ability, "modifier_hippogriff_vanish_banish", {})

end

OnVanishDebuffStart = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	-- if target:GetName() == "npc_dota_hero_queenofpain" and not debug_mode then
	-- 	local prop = Attachments:GetCurrentAttachment(target, "attach_sword")
	-- 	prop:RemoveSelf()
	-- end
	target:AddEffects(EF_NODRAW)
	--target:SetModel("models/development/invisiblebox.vmdl")
	--target:SetOriginalModel("models/development/invisiblebox.vmdl")
	target:EmitSound("Hero_Oracle.PurifyingFlames.Damage")
end

OnVanishDebuffEnd = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	target:RemoveEffects(EF_NODRAW)
	--target:SetModel(target.OriginalModel)
	--target:SetOriginalModel(target.OriginalModel)
	if caster.bIsSanityAcquired then 
		target:AddNewModifier(caster, target, "modifier_stunned", { Duration = 0.5 })
		--giveUnitDataDrivenModifier(caster, target, "stunned", 0.5)
	end

	-- if target:GetName() == "npc_dota_hero_queenofpain" and not debug_mode then
	-- 	Attachments:AttachProp(target, "attach_sword", "models/astolfo/astolfo_sword.vmdl")
	-- end
end


function astolfo_hippogriff_vanish:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: astolfo_ability / OnVanishStart
	OnVanishStart({ caster = caster, ability = self, target = target })
end

function astolfo_hippogriff_vanish:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: astolfo_ability / OnVanishHit
	OnVanishHit({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage")
	})
	return true
end

modifier_hippogriff_vanish_banish = class({})

function modifier_hippogriff_vanish_banish:IsDebuff() return true end
function modifier_hippogriff_vanish_banish:GetEffectName() return "particles/units/heroes/hero_shadow_demon/shadow_demon_disruption.vpcf" end
function modifier_hippogriff_vanish_banish:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_hippogriff_vanish_banish:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_SILENCED] = false,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_hippogriff_vanish_banish:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%banish_duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("banish_duration"), true)
	end
	-- DD RunScript: astolfo_ability / OnVanishDebuffStart
	OnVanishDebuffStart({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

function modifier_hippogriff_vanish_banish:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_hippogriff_vanish_banish:OnDestroy()
	if not IsServer() then return end
	-- DD RunScript: astolfo_ability / OnVanishDebuffEnd
	OnVanishDebuffEnd({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end
