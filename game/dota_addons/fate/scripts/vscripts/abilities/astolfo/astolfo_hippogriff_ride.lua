-- astolfo_hippogriff_ride — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/astolfo/astolfo_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

astolfo_hippogriff_ride = class({})

LinkLuaModifier("modifier_hippogriff_ride_ascended", "abilities/astolfo/astolfo_hippogriff_ride", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hippogriff_ride_cooldown", "abilities/astolfo/astolfo_hippogriff_ride", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/astolfo_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnRideStart, OnRideAscend, OnRideAscendEnd

OnRideStart = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ascendDelay = keys.Delay
	local radius = keys.Radius
	local duration = keys.Duration
	if caster:HasModifier("modifier_hippogriff_ride_ascended") then return end 
	
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(keys.ability:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(keys.ability:GetCooldown(1))
	caster:AddNewModifier(caster, ability, "modifier_hippogriff_ride_cooldown", {duration = ability:GetCooldown(ability:GetLevel())})
	
	caster.ComboStringNum = RandomInt(1, 2)

	EmitGlobalSound("Astolfo_Hippogriff_Ride_Cast_" .. caster.ComboStringNum)
	EmitGlobalSound("Astolfo.SolarForge")
	-- pause for ascend delay
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", ascendDelay)
	--StartAnimation(caster, {duration=1.0, activity=ACT_DOTA_CAST_ABILITY_3, rate=0.5})
	local ascendIndex = ParticleManager:CreateParticle("particles/econ/items/kunkka/divine_anchor/hero_kunkka_dafx_skills/kunkka_spell_torrent_bubbles_swirl_fxset.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( ascendIndex, 0, caster:GetAbsOrigin())

	StartAnimation(caster, {duration=2.0, activity=ACT_DOTA_CAST_ABILITY_1, rate=0.45})
	Timers:CreateTimer(ascendDelay, function()
		if caster:IsAlive() then
			caster:AddNewModifier(caster, ability, "modifier_hippogriff_ride_ascended", {})
			giveUnitDataDrivenModifier(caster, caster, "zero_attack_damage", 9.0)
			HardCleanse(caster)
			for i=2, 13 do
				if caster:GetTeamNumber() ~= i then
					AddFOWViewer(i, caster:GetAbsOrigin(), 500, 10, false)
				end
			end
	
			local aoeFx = ParticleManager:CreateParticle("particles/custom/astolfo/hippogriff_ride/astolfo_hippogriff_ride_aoe_indicator.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
			ParticleManager:SetParticleControl( aoeFx, 1, Vector(radius/3.35,0,0))
			
			local beaconIndex = ParticleManager:CreateParticle("particles/custom/astolfo/astolfo_ground_mark_flex_10sec.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl( beaconIndex, 0, caster:GetAbsOrigin())
			Timers:CreateTimer(duration, function()
				ParticleManager:DestroyParticle( aoeFx, true )
				ParticleManager:ReleaseParticleIndex( aoeFx )
				ParticleManager:DestroyParticle( beaconIndex, true )
				ParticleManager:ReleaseParticleIndex( beaconIndex )
				end
			)		
			
		end
	end)
	-- swap ability layout
	

end

OnRideAscend = function(keys)
	local caster = keys.caster
	local ability = keys.ability
	local duration = keys.Duration
	giveUnitDataDrivenModifier(caster, caster, "jump_pause_nosilence", duration)
	caster:AddEffects(EF_NODRAW)
	caster:SwapAbilities("astolfo_hippogriff_vanish", "astolfo_hippogriff_rush", false, true)
	Timers:CreateTimer(0.7, function()
		EmitGlobalSound("Astolfo_Hippogriff_Ride_Success_" .. caster.ComboStringNum)
		return
	end)
	
	local ascendFx = ParticleManager:CreateParticle( "particles/custom/astolfo/hippogriff_raid/astolfo_hippogriff_raid_ascend.vpcf", PATTACH_CUSTOMORIGIN, nil )
	ParticleManager:SetParticleControl( ascendFx, 0, caster:GetAbsOrigin())
	--local aoeIndicatorFx = ParticleManager:CreateParticle( "particles/custom/astolfo/hippogriff_ride/astolfo_hippogriff_ride_aoe_indicator.vpcf", PATTACH_CUSTOMORIGIN, nil )
    --ParticleManager:SetParticleControl(aoeIndicatorFx, 0, caster:GetAbsOrigin())
    --print("ascended")
	
end

OnRideAscendEnd = function(keys)
	local caster = keys.caster
	local ability = keys.ability

	caster:RemoveEffects(EF_NODRAW)
	caster:SwapAbilities("astolfo_hippogriff_vanish", "astolfo_hippogriff_rush", true, false)
end


function astolfo_hippogriff_ride:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: astolfo_ability / OnRideStart
	OnRideStart({
		caster = caster,
		ability = self,
		target = caster,
		Delay = self:GetSpecialValueFor("ascend_delay"),
		Radius = self:GetSpecialValueFor("max_range"),
		Duration = self:GetSpecialValueFor("duration")
	})
end

modifier_hippogriff_ride_ascended = class({})


function modifier_hippogriff_ride_ascended:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
	-- DD RunScript: astolfo_ability / OnRideAscend
	OnRideAscend({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent(),
		Duration = self:GetAbility():GetSpecialValueFor("duration")
	})
end

function modifier_hippogriff_ride_ascended:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_hippogriff_ride_ascended:OnDestroy()
	if not IsServer() then return end
	-- DD RunScript: astolfo_ability / OnRideAscendEnd
	OnRideAscendEnd({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

modifier_hippogriff_ride_cooldown = class({})

function modifier_hippogriff_ride_cooldown:IsDebuff() return true end
function modifier_hippogriff_ride_cooldown:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
