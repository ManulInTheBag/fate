-- gawain_excalibur_galatine — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gawain/gawain_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gawain_excalibur_galatine = class({})

LinkLuaModifier("modifier_excalibur_galatine_vfx", "abilities/gawain/gawain_excalibur_galatine", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_excalibur_galatine_burnk", "abilities/gawain/gawain_excalibur_galatine", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/gawain_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnGalatineStart, OnBurnDamageTick, GiveGawainGalatine

OnGalatineStart = function(keys)
	-- Declaring a bunch of stuffs
	local caster = keys.caster
	local ability = keys.ability
	--local ply = caster:GetPlayerOwner()
	local casterLoc = caster:GetAbsOrigin()
	local targetPoint = keys.ability:GetCursorPosition()
	local dist = keys.Max_range    --(targetPoint - casterLoc):Length2D()
	local orbLoc = caster:GetAbsOrigin()
	local diff = caster:GetForwardVector()
	local timeElapsed = 0
	local flyingDist = 0
	local orbVelocity = 90
	local fireTrailDuration = 3
	local damage = keys.Damage
	local InFirstLoop = true
	caster.IsGalatineActive = true

	-- Stops Gawain from doing anything else essentially and play the Galatine animation
	caster:AddNewModifier(caster, ability, "modifier_excalibur_galatine_vfx", {})	
	giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 2.0)
	StartAnimation(caster, {duration=2.0, activity=ACT_DOTA_CAST_ABILITY_4, rate=1.3})
	-- Need the dank voice. 
	EmitGlobalSound("Gawain_Galatine_1")

	-- Make dem particles and the Galatine ball
	local castFx1 = ParticleManager:CreateParticle("particles/custom/saber_excalibur_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( castFx1, 0, caster:GetAbsOrigin())

	local castFx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( castFx2, 0, caster:GetAbsOrigin())

	local galatineDummy = CreateUnitByName("gawain_galatine_dummy", Vector(20000,20000,0), true, nil, nil, caster:GetTeamNumber())
	local flameFx1 = ParticleManager:CreateParticle("particles/custom/gawain/gawain_excalibur_galatine_orb.vpcf", PATTACH_ABSORIGIN_FOLLOW, galatineDummy )
	ParticleManager:SetParticleControl( flameFx1, 0, galatineDummy:GetAbsOrigin())

	galatineDummy:SetDayTimeVisionRange(300)
	galatineDummy:SetNightTimeVisionRange(300)
	galatineDummy:AddNewModifier(caster, nil, "modifier_kill", {duration = 5.0})

	if caster.IsSoVAcquired then
		damage = damage + 250
		fireTrailDuration = fireTrailDuration + 3
	end

	-- Checks if Gawain is still alive as well as whether or not it overshot where the player intended it to flew.. or it flew for too long
	Timers:CreateTimer(1.4, function()
		if caster:IsAlive() and timeElapsed < 1.4 and caster.IsGalatineActive and flyingDist < dist then
			-- Need to initialize the variables and put in Gawain's detonate Galatine ability
			if InFirstLoop then
				casterLoc = caster:GetAbsOrigin()
				orbLoc = caster:GetAbsOrigin()
				diff = caster:GetForwardVector()
				caster:SwapAbilities("gawain_excalibur_galatine", "gawain_excalibur_galatine_detonate", false, true)
				InFirstLoop = false
				EmitGlobalSound("Gawain_Galatine_2")
			end
			-- Move the ball, reduce the remaining flight distance, reduce the remaining timer and increase the AoE gradually
			orbLoc = orbLoc + diff * orbVelocity
			galatineDummy:SetAbsOrigin(orbLoc)
			flyingDist = (casterLoc - orbLoc):Length2D()
			timeElapsed = timeElapsed + 0.05

			-- Get all nearby enemies and give them Galatine burn debuff if they don't have it
			local burnTargets = FindUnitsInRadius(caster:GetTeam(), galatineDummy:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)			
			for i,j in pairs(burnTargets) do
				j:AddNewModifier(caster, ability, "modifier_excalibur_galatine_burnk", {}) 				
			end

			--Hacky way to leave a fire trail 
			if (math.ceil(flyingDist) % 300 < 5) then
				LeaveFireTrail(keys, GetGroundPosition(galatineDummy:GetAbsOrigin(), nil), fireTrailDuration)
			end
			
			return 0.05
		else 
			LeaveFireTrail(keys, GetGroundPosition(galatineDummy:GetAbsOrigin(), nil), fireTrailDuration)

			-- Give Gawain back his Galatine
			GiveGawainGalatine(caster)

			-- Explosion on enemies
			local targets = FindUnitsInRadius(caster:GetTeam(), galatineDummy:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 

			for k,v in pairs(targets) do	
				v:AddNewModifier(caster, keys.ability, "modifier_excalibur_galatine_burnk", {})
				DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)				
			end

			local explodeFx1 = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_hit.vpcf", PATTACH_ABSORIGIN, galatineDummy )
			ParticleManager:SetParticleControl( explodeFx1, 0, galatineDummy:GetAbsOrigin())			

			local explodeFx2 = ParticleManager:CreateParticle("particles/custom/gawain/gawain_galetine_explosion_parent.vpcf", PATTACH_ABSORIGIN_FOLLOW, galatineDummy )
			ParticleManager:SetParticleControl( explodeFx2, 0, galatineDummy:GetAbsOrigin())

			galatineDummy:EmitSound("Ability.LightStrikeArray")
			local sunAbility = caster:FindAbilityByName("gawain_artificial_sun")
			sunAbility:GenerateArtificialSun(caster, galatineDummy:GetAbsOrigin(), false, "gawain_excalibur_galatine")
			galatineDummy:ForceKill(true) 
		
			ParticleManager:DestroyParticle( flameFx1, false )
			ParticleManager:ReleaseParticleIndex( flameFx1 )
			ParticleManager:DestroyParticle( castFx1, false )
			ParticleManager:ReleaseParticleIndex( castFx1 )

			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( explodeFx1, false )
				ParticleManager:ReleaseParticleIndex( explodeFx1 )
				ParticleManager:DestroyParticle( explodeFx2, false )
				ParticleManager:ReleaseParticleIndex( explodeFx2 )
			end)
			return
		end
	end)
end

OnBurnDamageTick = function(keys)
	local caster = keys.caster
	local target = keys.target
	local damage = keys.Damage/4

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	if target:GetName() == "npc_dota_hero_nevermore" then
		target:FindAbilityByName("demon_king_materialization"):ProckSpellAmpBonus()
	end
end

GiveGawainGalatine = function(caster)
	local galatineSlot = caster:GetAbilityByIndex(5)

	caster.IsGalatineActive = false

	if galatineSlot:GetAbilityName() ~= "gawain_excalibur_galatine" then
		caster:SwapAbilities("gawain_excalibur_galatine", galatineSlot:GetAbilityName(), true, false)
	end
end


function gawain_excalibur_galatine:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function gawain_excalibur_galatine:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: gawain_ability / OnGalatineStart
	OnGalatineStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Target = "POINT",
		Damage = self:GetSpecialValueFor("damage"),
		BurnDamage = self:GetSpecialValueFor("dot_damage"),
		Max_range = self:GetSpecialValueFor("max_range"),
		Radius = self:GetSpecialValueFor("radius")
	})
	caster:AddNewModifier(caster, self, "modifier_excalibur_galatine_vfx", {})
end

modifier_excalibur_galatine_vfx = class({})


function modifier_excalibur_galatine_vfx:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.75" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.75, true)
	end
	local fx = ParticleManager:CreateParticle("particles/custom/saber_excalibur_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(fx, 1, Vector(400, 0, 0))
	self:AddParticle(fx, false, false, -1, false, false)
end

function modifier_excalibur_galatine_vfx:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_excalibur_galatine_burnk = class({})

function modifier_excalibur_galatine_burnk:IsDebuff() return true end
function modifier_excalibur_galatine_burnk:GetEffectName() return "particles/units/heroes/hero_doom_bringer/doom_infernal_blade_debuff.vpcf" end
function modifier_excalibur_galatine_burnk:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_excalibur_galatine_burnk:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("duration"), true)
	end
	self:StartIntervalThink(0.25)
end

function modifier_excalibur_galatine_burnk:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_excalibur_galatine_burnk:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: gawain_ability / OnBurnDamageTick
	OnBurnDamageTick({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent(),
		Damage = self:GetAbility():GetSpecialValueFor("dot_damage")
	})
end
