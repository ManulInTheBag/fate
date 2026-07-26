-- saber_strike_air_upstream — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/saber/saber_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

saber_strike_air_upstream = class({})

LinkLuaModifier("modifier_strike_air_upstream_ready", "abilities/saber/saber_strike_air_upstream", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/saber_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnUpstreamHit

OnUpstreamHit = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	--if keys.target:GetName() == "npc_dota_hero_bounty_hunter" and keys.target.IsPFWAcquired then return end
	-- particle
	local damage = caster:GetAttackDamage() * 1.3 + 150
	--if target:GetName() == "npc_dota_hero_juggernaut" then damage = 0 end
	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
	ApplyAirborne(caster, target, 1.25)
	caster:RemoveModifierByName("modifier_strike_air_upstream_ready")
	local sound = RandomInt(1,2)
	if sound == 1 then caster:EmitSound("Saber.StrikeAir_Release1") else caster:EmitSound("Saber.StrikeAir_Release2") end
	local upstreamFx = ParticleManager:CreateParticle( "particles/custom/saber/strike_air_upstream/strike_air_upstream.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl( upstreamFx, 0, target:GetAbsOrigin() )

	caster.UpstreamHitCooldown = true
	Timers:CreateTimer(0.1, function()
		caster.UpstreamHitCooldown = false
	end)
end


modifier_strike_air_upstream_ready = class({})


function modifier_strike_air_upstream_ready:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_strike_air_upstream_ready:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "3.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(3.0, true)
	end
end

function modifier_strike_air_upstream_ready:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_strike_air_upstream_ready:OnAttackLanded(params)
	if not IsServer() then return end
	-- в lua события глобальные: без фильтра сработает на чужие атаки
	if params.attacker ~= self:GetParent() then return end
	-- DD RunScript: saber_ability / OnUpstreamHit
	OnUpstreamHit({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		attacker = params.attacker,
		target = params.target,
		Damage = self:GetAbility():GetSpecialValueFor("ad_ratio"),
		KnockupDuration = self:GetAbility():GetSpecialValueFor("knockup_duration")
	})
end
