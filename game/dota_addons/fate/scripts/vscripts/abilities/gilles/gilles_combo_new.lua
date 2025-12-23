gilles_combo_new = class({})

LinkLuaModifier("modifier_gilles_combo_cooldown", "abilities/gilles/gilles_combo_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilles_combo_new_blood", "abilities/gilles/gilles_combo_new", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilles_combo_new_slow", "abilities/gilles/gilles_combo_new", LUA_MODIFIER_MOTION_NONE)
function gilles_combo_new:GetManaCost(iLevel)
	return self:GetCaster():GetMaxMana() * 0.8
end

function gilles_combo_new:IsHiddenAbilityCastable()
	return true
end

function gilles_combo_new:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end



function gilles_combo_new:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local radius = self:GetAOERadius()
	local debuff_duration = self:GetSpecialValueFor("blood_duration")
	local initial_damage = self:GetSpecialValueFor("initial_damage")
	local explosion_damage = self:GetSpecialValueFor("explosion_damage")
	local dot_damage = self:GetSpecialValueFor("damage_per_sec")
	local delay = self:GetSpecialValueFor("cast_delay")
	local stun_duration = self:GetSpecialValueFor("knockup_duration")
	local particles = {}
	local ray_particle = "particles/gilles/new_combo/gilles_new_combo_1.vpcf"
	local aoe_particle = "particles/gilles/new_combo/gilles_new_combo_2.vpcf"
	local kraken_particle = "particles/gilles/new_combo/kraken_model_1.vpcf"
	local kraken_blood_particle = "particles/gilles/new_combo/gilles_combo_kraken_2.vpcf"
	local kraken_blood_particle_2 = "particles/gilles/new_combo/gilles_new_combo_kraken_blood_kill.vpcf"
	local rain_particle = "particles/gilles/new_combo/blood_rain.vpcf"
	local tempRadiusParticleChanger = 0
	local angle_diff = 30
	local indexer = 0

	caster:FindAbilityByName("gilles_abyssal_contract"):StartCooldown(caster:FindAbilityByName("gilles_abyssal_contract"):GetCooldown(0)* caster:GetCooldownReduction())

	if(caster:GetAbilityByIndex(5):GetName() == "gilles_combo_new") then
		caster:SwapAbilities("gilles_abyssal_contract", "gilles_combo_new", true, false)
	end
	local masterCombo = caster.MasterUnit2:FindAbilityByName("gilles_combo_new")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(0))

	caster:AddNewModifier(caster, self , "modifier_gilles_combo_cooldown",{duration = 150 })
	EmitSoundOnLocationWithCaster(point, "gilles_blood_torrent_combo", caster)
	Timers:CreateTimer(0.01, function() 
		
		-- if indexer >= 8 then
		-- 	tempRadiusParticleChanger = 500
		-- 	angle_diff = 80
		-- end
		rayTarget =  PointOnCircle(point, radius - 150 - tempRadiusParticleChanger, indexer * angle_diff)
		--print(radius - 150 - tempRadiusParticleChanger)
		local fxIndex = ParticleManager:CreateParticle(ray_particle, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(fxIndex, 0, rayTarget)
		ParticleManager:SetParticleShouldCheckFoW(fxIndex, false)
		table.insert(particles, fxIndex)
		local targets = FindUnitsInRadius(caster:GetTeam(),point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			DoDamage(caster, v, initial_damage/9, DAMAGE_TYPE_MAGICAL, 0, self, false)
			v:AddNewModifier(caster, self, "modifier_gilles_combo_new_slow", {duration = 0.5})
		end
		indexer = indexer + 1
		if indexer % 2 == 0 then 
			EmitSoundOnLocationWithCaster(point, "gilles_blood_torrent_combo_short", caster)
		end
		if indexer >= 9 then
			return
		end
		return (0.15) 

	end)
	EmitGlobalSound("ZC.Laugh")
	local fxIndex = ParticleManager:CreateParticle(aoe_particle, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fxIndex, 0, point)
	ParticleManager:SetParticleControl(fxIndex, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleShouldCheckFoW(fxIndex, false)
	local fxIndexjopa = ParticleManager:CreateParticle("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fxIndexjopa, 0, point)
	ParticleManager:SetParticleControl(fxIndexjopa, 1, Vector(1,0.01,0.1))
	ParticleManager:SetParticleControl(fxIndexjopa, 2, Vector(self:GetAOERadius(),delay,0))
	ParticleManager:ReleaseParticleIndex(fxIndexjopa)
	table.insert(particles, fxIndex)
	Timers:CreateTimer(2, function()
		self:RemoveParticles(particles)
		local targets = FindUnitsInRadius(caster:GetTeam(),point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			DoDamage(caster, v, explosion_damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			ApplyAirborne(caster, v, 0.5)
			 v:AddNewModifier(caster, self , "modifier_gilles_combo_new_blood",{duration = debuff_duration })
			v:EmitSound("hero_bloodseeker.rupture")
		end
			-- local fxIndexRain = ParticleManager:CreateParticle(rain_particle, PATTACH_WORLDORIGIN, nil)
			-- ParticleManager:SetParticleControl(fxIndexRain, 0, point)
			-- ParticleManager:SetParticleShouldCheckFoW(fxIndexRain, false)
			-- Timers:CreateTimer(2, function()

			-- 		ParticleManager:DestroyParticle(fxIndexRain, true)
			-- 		ParticleManager:ReleaseParticleIndex(fxIndexRain)
			-- end)
	end)
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.gachi == true then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="gilles_wife_combo_0"..math.random(1,2)})
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
	local krakenFxIndex = nil

	Timers:CreateTimer(delay, function()
		EmitSoundOnLocationWithCaster(point, "ZC.Ravage", caster)
		EmitSoundOnLocationWithCaster(point, "gilles_blood_spill_combo", caster)
		ParticleManager:SetParticleControl(krakenFxIndex, 1, Vector(0,0,0))
		krakenBloodFxIndex = ParticleManager:CreateParticle(kraken_blood_particle, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(krakenBloodFxIndex, 0, point)

		ParticleManager:SetParticleShouldCheckFoW(krakenBloodFxIndex, false)

		krakenBloodFxIndex2 = ParticleManager:CreateParticle(kraken_blood_particle_2, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(krakenBloodFxIndex2, 4, point)
		ParticleManager:SetParticleControlTransformForward(krakenBloodFxIndex2, 3, Vector(0,0,0), Vector(100,0,0))
		ParticleManager:SetParticleShouldCheckFoW(krakenBloodFxIndex2, false)
		--table.insert(particles, krakenBloodFxIndex)
		Timers:CreateTimer(3, function()
					ParticleManager:DestroyParticle(krakenBloodFxIndex, true)
					ParticleManager:ReleaseParticleIndex(krakenBloodFxIndex)
					ParticleManager:DestroyParticle(krakenBloodFxIndex2, true)
					ParticleManager:ReleaseParticleIndex(krakenBloodFxIndex2)

		end)
	end)

	
	Timers:CreateTimer(delay - 1.5, function()
			krakenFxIndex = ParticleManager:CreateParticle(kraken_particle, PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(krakenFxIndex, 0, point)
			ParticleManager:SetParticleControl(krakenFxIndex, 1, Vector(0,0,650))
			ParticleManager:SetParticleShouldCheckFoW(krakenFxIndex, false)
			table.insert(particles, krakenFxIndex)
	end)

end

function gilles_combo_new:RemoveParticles(table)
	for i=1,#table do 
		ParticleManager:DestroyParticle(table[i], true)
		ParticleManager:ReleaseParticleIndex(table[i])

	end

end



modifier_gilles_combo_new_blood = class({})



function modifier_gilles_combo_new_blood:GetEffectName()
    return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf"
end
function modifier_gilles_combo_new_blood:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
function modifier_gilles_combo_new_blood:CheckState()
    local tState =  {
                        [MODIFIER_STATE_PROVIDES_VISION] = true,
                    }
    return tState
end

function modifier_gilles_combo_new_blood:GetModifierProvidesFOWVision(keys)
   return true
end
function modifier_gilles_combo_new_blood:IsDebuff() return true end
function modifier_gilles_combo_new_blood:OnCreated()
	if IsServer() then
		local splashFx = ParticleManager:CreateParticle("particles/custom/screen_scarlet_splash.vpcf", PATTACH_EYES_FOLLOW, self:GetParent())
		Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( splashFx, true )
			ParticleManager:ReleaseParticleIndex( splashFx )
		end)
		self:StartIntervalThink(1)
	end
end
function modifier_gilles_combo_new_blood:OnIntervalThink()
    if(not IsServer() ) then return end
    local caster = self:GetCaster()
    local target = self:GetParent()
    local damage = self:GetAbility():GetSpecialValueFor("damage_per_sec")

    DoDamage(caster, target, damage/100 * target:GetMaxHealth(), DAMAGE_TYPE_PURE, 0, self:GetAbility(), false)

end

modifier_gilles_combo_cooldown = class({})


function modifier_gilles_combo_cooldown:IsHidden()
    return false 
end

function modifier_gilles_combo_cooldown:RemoveOnDeath()
    return false
end

function modifier_gilles_combo_cooldown:IsDebuff()
    return true 
end

function modifier_gilles_combo_cooldown:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_gilles_combo_new_slow = class({})
function modifier_gilles_combo_new_slow:IsHidden() return false end
function modifier_gilles_combo_new_slow:IsDebuff() return true end
function modifier_gilles_combo_new_slow:IsPurgable() return true end
function modifier_gilles_combo_new_slow:IsPurgeException() return true end
function modifier_gilles_combo_new_slow:RemoveOnDeath() return true end
function modifier_gilles_combo_new_slow:DeclareFunctions()
    local funcs = { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,}
    return funcs
end

function modifier_gilles_combo_new_slow:GetModifierMoveSpeedBonus_Percentage()
    return -self:GetAbility():GetSpecialValueFor("slow")
end