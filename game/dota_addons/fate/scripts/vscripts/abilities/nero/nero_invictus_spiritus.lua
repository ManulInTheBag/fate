-- nero_invictus_spiritus — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/nero/nero_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

nero_invictus_spiritus = class({})

LinkLuaModifier("modifier_invictus_spiritus", "abilities/nero/nero_invictus_spiritus", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_invictus_spiritus_cooldown", "abilities/nero/nero_invictus_spiritus", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("nero_autoattack_passive", "abilities/nero/nero_invictus_spiritus", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/nero_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnISStart, NeroTakeDamage

OnISStart = function(keys)
end

NeroTakeDamage = function(keys)
	--SendChatToPanorama("nero_revive 0")
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local damageTaken = keys.damageTaken
	local healCounter = 0

	--[[[if caster:GetHealth() == 0 and IsRevivePossible(caster) and caster.IsISAcquired and not caster:HasModifier("modifier_invictus_spiritus_cooldown") and not IsRevoked(caster) then
		--RemoveDebuffsForRevival(caster)
		caster:SetHealth(caster:GetMaxHealth()*0.30)
		caster:FindAbilityByName("nero_invictus_spiritus"):ApplyDataDrivenModifier(caster, caster, "modifier_invictus_spiritus",{})
		
		caster:EmitSound("Hero_SkeletonKing.Reincarnate")
		--caster:SetHealth(1)
		if caster:HasModifier("modifier_aestus_domus_aurea") then 
			caster:RemoveModifierByName("modifier_aestus_domus_aurea")
			FxDestroyer(caster.theatreFx2, false)
		end
		Timers:CreateTimer(function()
			if healCounter == 9 or not caster:IsAlive() then return end
			--caster:SetHealth(caster:GetHealth() + caster:GetMaxHealth() * 0.1)
			healCounter = healCounter + 1
			return 1.0
		end)
		caster:EmitSound("Hero_SkeletonKing.Reincarnate")
		--giveUnitDataDrivenModifier(keys.caster, keys.caster, "rb_sealdisabled", 4.5)
		caster:FindAbilityByName("nero_invictus_spiritus"):ApplyDataDrivenModifier(caster, caster, "modifier_invictus_spiritus_cooldown", {duration = 130})
	end]]
end


function nero_invictus_spiritus:GetIntrinsicModifierName()
	return "nero_autoattack_passive"
end

function nero_invictus_spiritus:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: nero_ability / OnISStart
	OnISStart({ caster = caster, ability = self, target = target })
end

modifier_invictus_spiritus = class({})

function modifier_invictus_spiritus:IsHidden() return true end
function modifier_invictus_spiritus:GetOverrideAnimation() return ACT_DOTA_DIE end

function modifier_invictus_spiritus:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
	}
end

function modifier_invictus_spiritus:GetOverrideAnimationRate()
	return 0.5
end
function modifier_invictus_spiritus:GetModifierIncomingDamage_Percentage()
	return -100
end
function modifier_invictus_spiritus:GetModifierHealthBonus()
	return 99999
end

function modifier_invictus_spiritus:CheckState()
	return {
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_invictus_spiritus:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "3.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(3.0, true)
	end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_livingarmor.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControlEnt(fx, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "follow_origin", self:GetCaster():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, self:GetCaster(), PATTACH_POINT_FOLLOW, "follow_origin", self:GetCaster():GetAbsOrigin(), true)
	self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_invictus_spiritus:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_invictus_spiritus_cooldown = class({})

function modifier_invictus_spiritus_cooldown:IsDebuff() return true end
function modifier_invictus_spiritus_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

nero_autoattack_passive = class({})

function nero_autoattack_passive:IsHidden() return true end

function nero_autoattack_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function nero_autoattack_passive:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	EmitSoundOn("Hero_LegionCommander.Attack", self:GetCaster())
end

function nero_autoattack_passive:OnTakeDamage(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: nero_ability / NeroTakeDamage
	-- TODO(dd2lua): функция читает keys.damageTaken — проверить
	NeroTakeDamage({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = params.unit,
		target = params.unit,
		attacker = params.attacker,
		damage = params.damage,
		DamageTaken = params.damage,
		DamageTaken = self:GetAbility():GetSpecialValueFor("attack_damage")
	})
end
