-- gille_larret_de_mort — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/gilles/gilles_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

gille_larret_de_mort = class({})

LinkLuaModifier("modifier_larret_de_mort_cooldown", "abilities/gilles/gille_larret_de_mort", LUA_MODIFIER_MOTION_NONE)
-- ^ класс объявлен в gille_exquisite_cadaver: тот же самый модификатор объявляли оба datadriven-блока
LinkLuaModifier("modifier_gille_combo", "abilities/gilles/gille_larret_de_mort", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gigantic_horror_freeze", "abilities/gilles/gille_larret_de_mort", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/gille_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnGilleComboStart, RemoveAllPoisons, OnGilleComboThink, CreateRavageParticle

OnGilleComboStart = function(keys)
	local caster = keys.caster
	local tentacle = caster.Squidlord
	
	local ability = caster:FindAbilityByName("gille_larret_de_mort")
	local radius = 1000
	--print(tentacle)
	--print(tentacle:IsAlive())
	caster:RemoveModifierByName("modifier_gilles_combo_window")
	LoopOverPlayers(function(player, playerID, playerHero)
	        --print("looping through " .. playerHero:GetName())
	        if playerHero.gachi == true then
	            -- apply legion horn vsnd on their client
	            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="gilles_wife_combo_0"..math.random(1,2)})
	            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
	        end
    	end)

	if not tentacle or not tentacle:IsAlive() then
		caster:FindAbilityByName("gille_larret_de_mort"):EndCooldown()
		return 
	end

	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName("gille_larret_de_mort")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(150)
	caster:AddNewModifier(caster, ability, "modifier_larret_de_mort_cooldown", {duration = 150})

	-- knockup enemies
	local targets = FindUnitsInRadius(caster:GetTeam(), tentacle:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		ApplyAirborne(caster, v, keys.KnockupDuration)
	end

	-- remove integrate status
	if caster.IsIntegrated then
		caster:RemoveModifierByName("modifier_integrate_gille")
		tentacle:RemoveModifierByName("modifier_integrate")
		caster.IsIntegrated = false
		tentacle.AttemptingIntegrate = false
		SendMountStatus(caster)
	end


	tentacle:AddNewModifier(caster, ability, "modifier_gigantic_horror_freeze", {})
	CreateRavageParticle(tentacle, tentacle:GetAbsOrigin(), 300)
	CreateRavageParticle(tentacle, tentacle:GetAbsOrigin(), 650)
	CreateRavageParticle(tentacle, tentacle:GetAbsOrigin(), 1000)
	EmitGlobalSound("ZC.Ravage")
	EmitGlobalSound("ZC.Laugh")

	local contractFx = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_upheaval.vpcf", PATTACH_CUSTOMORIGIN, visiondummy)
	ParticleManager:SetParticleControl(contractFx, 0, tentacle:GetAbsOrigin())
	ParticleManager:SetParticleControl(contractFx, 1, Vector(radius + 200,0,0))
	Timers:CreateTimer( 3, function()
		ParticleManager:DestroyParticle( contractFx, false )
		ParticleManager:ReleaseParticleIndex( contractFx )
	end)

	Timers:CreateTimer(1, function()
		local targets = FindUnitsInRadius(caster:GetTeam(), tentacle:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			DoDamage(caster, v, v:GetMaxHealth() * keys.Damage/100, DAMAGE_TYPE_MAGICAL, 0, ability, false)
			v:AddNewModifier(caster, ability, "modifier_gille_combo", {})
			v:EmitSound("hero_bloodseeker.rupture")
		end
		Timers:CreateTimer(0.5, function()
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_reborn_shockwave.vpcf", PATTACH_CUSTOMORIGIN, tentacle)
			ParticleManager:SetParticleControl(particle, 0, tentacle:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, Vector(radius+200,0,0))  
			ParticleManager:DestroyParticle(contractFx, false)
			ParticleManager:ReleaseParticleIndex(contractFx)
			Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( particle, false )
				ParticleManager:ReleaseParticleIndex( particle )
			end)
		end)
		
		tentacle:EmitSound("Hero_ObsidianDestroyer.SanityEclipse.Cast")
		local splashFx = ParticleManager:CreateParticle("particles/custom/screen_scarlet_splash.vpcf", PATTACH_EYES_FOLLOW, tentacle)
		Timers:CreateTimer( 3.0, function()
			ParticleManager:DestroyParticle( splashFx, false )
			ParticleManager:ReleaseParticleIndex( splashFx )
		end)
		tentacle:EmitSound("Hero_ShadowDemon.DemonicPurge.Impact")
		tentacle:ForceKill(true)
	end)

end

RemoveAllPoisons = function(keys) -- so people don't respawn with poison DoT debuff modifiers
	local caster = keys.caster
    LoopOverHeroes(function(hero)
    	hero:RemoveModifierByName("modifier_contaminate")
    	hero:RemoveModifierByName("modifier_gille_combo")
    end)
end

OnGilleComboThink = function(keys)
	local caster = keys.caster
	local target = keys.target
	local damage = target:GetMaxHealth()*keys.DPS/100
	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	--print("dealing damage")
end

CreateRavageParticle = function(handle, center, multiplier)
	for i=1, math.floor(multiplier/60) do
		local x = math.cos(i) * multiplier
		local y = math.sin(i) * multiplier
		local tentacleFx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_spell_ravage_hit.vpcf", PATTACH_CUSTOMORIGIN, handle)
		ParticleManager:SetParticleControl(tentacleFx, 0, Vector(center.x + x, center.y + y, 100))
		ParticleManager:SetParticleControl(tentacleFx, 2, Vector(center.x + x, center.y + y, 100))
	end
end


function gille_larret_de_mort:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function gille_larret_de_mort:OnSpellStart()
	local caster = self:GetCaster()
	-- DD RunScript: gille_ability / OnGilleComboStart
	OnGilleComboStart({
		caster = caster,
		ability = self,
		target = caster,
		Damage = self:GetSpecialValueFor("initial_damage"),
		KnockupDuration = self:GetSpecialValueFor("knockup_duration")
	})
end

modifier_gille_combo = class({})

function modifier_gille_combo:IsDebuff() return true end
function modifier_gille_combo:GetEffectName() return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf" end
function modifier_gille_combo:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_gille_combo:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_RESPAWN,
	}
end

function modifier_gille_combo:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "12" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(12, true)
	end
	self:StartIntervalThink(1.0)
end

function modifier_gille_combo:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_gille_combo:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: gille_ability / OnGilleComboThink
	OnGilleComboThink({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent(),
		DPS = self:GetAbility():GetSpecialValueFor("damage_per_sec")
	})
end

function modifier_gille_combo:OnRespawn(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end
	-- DD RunScript: gille_ability / RemoveAllPoisons
	RemoveAllPoisons({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

modifier_gigantic_horror_freeze = class({})

function modifier_gigantic_horror_freeze:GetOverrideAnimation() return ACT_DOTA_CAST_ABILITY_3 end
function modifier_gigantic_horror_freeze:GetEffectName() return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf" end
function modifier_gigantic_horror_freeze:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end

function modifier_gigantic_horror_freeze:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}
end

function modifier_gigantic_horror_freeze:GetOverrideAnimationRate()
	return 0.5
end

function modifier_gigantic_horror_freeze:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

function modifier_gigantic_horror_freeze:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.5" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.5, true)
	end
end

function modifier_gigantic_horror_freeze:OnRefresh(kv)
	self:OnCreated(kv)
end

modifier_larret_de_mort_cooldown = class({})

function modifier_larret_de_mort_cooldown:IsDebuff() return true end
function modifier_larret_de_mort_cooldown:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
