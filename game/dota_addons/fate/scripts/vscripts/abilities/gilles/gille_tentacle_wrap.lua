-- gille_tentacle_wrap — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gilles/gilles_abyssal_contract.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gille_tentacle_wrap = class({})

LinkLuaModifier("modifier_tentacle_wrap", "abilities/gilles/gille_tentacle_wrap", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/gille_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnTentacleWrapStart

OnTentacleWrapStart = function(keys)
	local caster = keys.caster
	local target = keys.target
	local fxCounter = 0
	Timers:CreateTimer(function()
		if fxCounter > 2 then return end 
		local tentacleFx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_spell_ravage_hit_wrap.vpcf", PATTACH_CUSTOMORIGIN, target)
		ParticleManager:SetParticleControl(tentacleFx, 0, target:GetAbsOrigin() + Vector(0,0,100))
		ParticleManager:SetParticleControl(tentacleFx, 2, target:GetAbsOrigin() + Vector(0,0,100))
		Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( tentacleFx, false )
			ParticleManager:ReleaseParticleIndex( tentacleFx )
		end)
		fxCounter = fxCounter + 0.5
		return 0.5
	end)
end


function gille_tentacle_wrap:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- DD RunScript: gille_ability / OnTentacleWrapStart
	OnTentacleWrapStart({ caster = caster, ability = self, target = target })
	target:AddNewModifier(caster, self, "modifier_tentacle_wrap", {})
	EmitSoundOn("ZC.Tentacle2", caster)
end

modifier_tentacle_wrap = class({})

function modifier_tentacle_wrap:IsDebuff() return true end

function modifier_tentacle_wrap:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end

function modifier_tentacle_wrap:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "2.0" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(2.0, true)
	end
end

function modifier_tentacle_wrap:OnRefresh(kv)
	self:OnCreated(kv)
end
