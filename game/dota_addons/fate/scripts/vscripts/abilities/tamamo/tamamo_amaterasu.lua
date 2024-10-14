LinkLuaModifier("modifier_tamamo_combo_window", "abilities/tamamo/modifiers/modifier_tamamo_combo_window", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_amaterasu_heal", "abilities/tamamo/modifiers/modifier_amaterasu_heal", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_amaterasu_aura", "abilities/tamamo/tamamo_amaterasu", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_amaterasu_ally", "abilities/tamamo/tamamo_amaterasu", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_amaterasu_enemy", "abilities/tamamo/tamamo_amaterasu", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_amaterasu_enemy_slow", "abilities/tamamo/tamamo_amaterasu", LUA_MODIFIER_MOTION_NONE)

local spellBooks = {
    "cu_chulain_rune_magic",
    "cu_chulain_close_runes",
    "caster_5th_ancient_magic",
    "caster_5th_close_spellbook",
    "lancelot_knight_of_honor",
    "lancelot_knight_of_honor_close",
    "nero_imperial_privilege",
    "nero_close_spellbook",
    "tamamo_armed_up",
    "tamamo_close_spellbook",
    "gilles_rlyeh_text_open",
    "gilles_rlyeh_text_close",
    "nero_heat",
    "mordred_pedigree",
    "kuro_spellbook_open",
    "kuro_spellbook_close",
    "atalanta_celestial_arrow",
    "atalanta_priestess_of_the_hunt",
    "nero_imperial_open",
    "nero_imperial_close",
    "nero_imperial_activate",
    "tamamo_fiery_heaven",
    "tamamo_frigid_heaven",
    "tamamo_gust_heaven",
    "tamamo_void_heaven",
	"robin_tools",
	"robin_tools_close",
	"vlad_rebellious_intent",
}

tamamo_amaterasu = class({})

function tamamo_amaterasu:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	local SilenceDuration = caster.MasterUnit2:FindAbilityByName("tamamo_attribute_witchcraft"):GetSpecialValueFor("silence_duration")
	if caster.CurrentAmaterasuDummy ~= nil then
		if IsValidEntity(caster.CurrentAmaterasuDummy) or not caster.CurrentAmaterasuDummy:IsNull() then
			caster.CurrentAmaterasuDummy:RemoveModifierByName("modifier_amaterasu_aura")
		end
	end

	local healPct = ability:GetSpecialValueFor("heal_pct")

	--EmitGlobalSound("Hero_KeeperOfTheLight.ManaLeak.Cast")
	caster.AmaterasuCastLoc = caster:GetAbsOrigin()
	local dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
	caster.CurrentAmaterasuDummy = dummy
	dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	dummy:AddNewModifier(caster, nil, "modifier_phased", {duration=1.0})
	dummy:AddNewModifier(caster, nil, "modifier_kill", {duration= duration+0.5})
	dummy:AddNewModifier(caster, self, "modifier_amaterasu_aura", {})
	dummy.TempleDoors = self:CreateTempleDoorInCircle(caster, caster:GetAbsOrigin(), radius)
	--EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_Dazzle.Shallow_Grave", caster)

	if caster.IsTerritoryAcquired then 
		local allies = FindUnitsInRadius(caster:GetTeam(), caster.AmaterasuCastLoc, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false) 
		for i = 1, #allies do
			allies[i]:AddNewModifier(caster, ability, "modifier_amaterasu_heal", { duration = 1.033 })
		end
		local enemies = FindUnitsInRadius(caster:GetTeam(), caster.AmaterasuCastLoc, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for i = 1, #enemies do
			enemies[i]:AddNewModifier(caster, ability, "modifier_amaterasu_enemy_slow", { duration = 1.5 })
			enemies[i]:AddNewModifier(caster, ability, "modifier_silence", { duration = SilenceDuration })
		end
	end

	-- Particle
	local circleFx = ParticleManager:CreateParticle('particles/units/heroes/hero_dazzle/dazzle_weave.vpcf', PATTACH_CUSTOMORIGIN, dummy) 
    ParticleManager:SetParticleControl(circleFx, 0, caster:GetOrigin())
    ParticleManager:SetParticleControl(circleFx, 1, Vector(radius,0,0))
	local counter = 0
    Timers:CreateTimer(function()
    	if counter > duration or caster.CurrentAmaterasuDummy:IsNull() or not IsValidEntity(caster.CurrentAmaterasuDummy) then 
			ParticleManager:DestroyParticle( caster.CurrentAmaterasuParticle, false )
			ParticleManager:ReleaseParticleIndex( caster.CurrentAmaterasuParticle )
			return
    	end
    	if not dummy:IsNull() and IsValidEntity(dummy) then
			local circleFx = ParticleManager:CreateParticle('particles/custom/tamamo/tamamo_amaterasu_continuous.vpcf', PATTACH_CUSTOMORIGIN, dummy) 
			caster.CurrentAmaterasuParticle = circleFx
		    ParticleManager:SetParticleControl(circleFx, 0, dummy:GetOrigin())
		    ParticleManager:SetParticleControl(circleFx, 1, Vector(radius,0,0))
	   	end
	    counter = counter+1
	    return 0.9
    end)

    local AmaterasuLine = "Tamamo_Amaterasu_" .. math.random(1,3)
    caster:EmitSound(AmaterasuLine)

    if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1
    	and caster:FindAbilityByName("tamamo_combo"):IsCooldownReady() then
    	caster:AddNewModifier(caster, ability, "modifier_tamamo_combo_window", { Duration = 4 })
    end
	--EmitGlobalSound("Tamamo_NP1")
end

function tamamo_amaterasu:OnAmaterasuEnd(dummy)
	local target = dummy --lonk
	local caster = self:GetCaster()
	target:RemoveSelf()
	if IsServer() then
		for i=1, #target.TempleDoors do
			target.TempleDoors[i]:RemoveSelf()
		end
	end
	caster:RemoveModifierByName("modifier_tamamo_combo_window")
end

function tamamo_amaterasu:OnAmaterasuApplyAura()
	local caster = self:GetCaster()
	local ability = self
	local radius = self:GetSpecialValueFor("radius")
	if IsServer() then
		local diff = (caster:GetAbsOrigin() - caster.AmaterasuCastLoc):Length2D()
		if diff > radius or not caster:IsAlive() then
			caster.CurrentAmaterasuDummy:RemoveModifierByName("modifier_amaterasu_aura")
		end	

		local targets = FindUnitsInRadius(caster:GetTeam(), caster.AmaterasuCastLoc, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for k,v in pairs(targets) do
			v:AddNewModifier(caster, self, "modifier_amaterasu_ally", {duration = 0.3})
		end

		local targets = FindUnitsInRadius(caster:GetTeam(), caster.AmaterasuCastLoc, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for k,v in pairs(targets) do
			v:AddNewModifier(caster, self, "modifier_amaterasu_enemy", {duration = 0.3})
		end
	end
end

function tamamo_amaterasu:CreateTempleDoorInCircle(handle, center, multiplier)
	local bannerTable = {}
	for i=1, 8 do
		local x = math.cos(i*math.pi/4) * multiplier
		local y = math.sin(i*math.pi/4) * multiplier
		local banner = CreateUnitByName("tamamo_templedoor_dummy", Vector(center.x + x, center.y + y, 0), true, nil, nil, handle:GetTeamNumber())
		banner:AddNewModifier(caster, nil, "modifier_kill", {duration=10.5})
		local diff = (handle:GetAbsOrigin() - banner:GetAbsOrigin())
    	banner:SetForwardVector(diff:Normalized()) 
    	banner.Diff = diff
		table.insert(bannerTable, banner)
	end
	return bannerTable
end

--

modifier_amaterasu_aura = class({})

function modifier_amaterasu_aura:OnCreated()
	self.ability = self:GetAbility()
	self.caster = self:GetCaster()

	if IsServer() then
		self.ability:OnAmaterasuApplyAura()
		self:StartIntervalThink(0.25)
	end
end

function modifier_amaterasu_aura:OnIntervalThink()
	if IsServer() then
		self.ability:OnAmaterasuApplyAura()
	end
end

function modifier_amaterasu_aura:OnDestroy()
	if IsServer() then
		self.ability:OnAmaterasuEnd(self:GetParent())
	end
end

--

modifier_amaterasu_ally = class({})

function modifier_amaterasu_ally:IsHidden() return false end
function modifier_amaterasu_ally:IsDebuff() return false end

function modifier_amaterasu_ally:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
                        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,

                        --MODIFIER_EVENT_ON_ABILITY_EXECUTED
                    }
    return tFunc
end

function modifier_amaterasu_ally:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movespeed_modifier")
end

function modifier_amaterasu_ally:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("movespeed_modifier")
end

function modifier_amaterasu_ally:OnAbilityExecuted(args)
	local abilityname = args.ability:GetName()
	local hero = self:GetParent()
	if not string.match(abilityname,"item") then
        for i=1, #spellBooks do
            if abilityname == spellBooks[i] then return end
        end
        local amaterasu = self:GetAbility()
        local caster = self:GetCaster()
        local heal = amaterasu:GetSpecialValueFor("heal_per_cast")
        local mana = amaterasu:GetSpecialValueFor("mana_per_cast")
        hero:ApplyHeal(heal, amaterasu)
        hero:GiveMana(mana)
        --hero:SetMana(hero:GetMana()+200)
        --hero:SetHealth(hero:GetHealth()+300)
        hero:EmitSound("DOTA_Item.ArcaneBoots.Activate")
        local particle = ParticleManager:CreateParticle("particles/tamamo/tamamo_amaterasu_ally.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
        ParticleManager:SetParticleControlEnt(particle,	0, caster,	PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetOrigin(), true)
        ParticleManager:SetParticleControlEnt(particle,	1, hero,	PATTACH_POINT_FOLLOW, "attach_origin", hero:GetOrigin(), true)
    end
end

--[[function modifier_amaterasu_ally:GetEffectName()
	return "particles/units/heroes/hero_keeper_of_the_light/keeper_mana_leak.vpcf"
end

function modifier_amaterasu_ally:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end]]


modifier_amaterasu_enemy = class({})

function modifier_amaterasu_enemy:IsHidden() return false end
function modifier_amaterasu_enemy:IsDebuff() return true end

function modifier_amaterasu_enemy:DeclareFunctions()
    local tFunc =   {
                        --MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,

                        --MODIFIER_EVENT_ON_ABILITY_EXECUTED
                    }
    return tFunc
end

function modifier_amaterasu_enemy:OnAbilityExecuted(args)
	local abilityname = args.ability:GetName()
	local hero = self:GetParent()
	if hero.AmaterasuProcCd then return end
	if not string.match(abilityname,"item") then
        for i=1, #spellBooks do
            if abilityname == spellBooks[i] then return end
        end
        local amaterasu = self:GetAbility()
        local caster = self:GetCaster()
        local damage = amaterasu:GetSpecialValueFor("damage_per_cast")
        if caster.IsTerritoryAcquired then
        	damage = damage + caster:GetIntellect()/2
        	--hero:AddNewModifier(caster, amaterasu, "modifier_amaterasu_enemy_slow", {duration = 0.75})
        	caster:ApplyHeal(amaterasu:GetSpecialValueFor("heal_per_cast")/3, amaterasu)
        	caster:GiveMana(amaterasu:GetSpecialValueFor("mana_per_cast")/3)
        end
        DoDamage(caster, hero, damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
        --DoDamage(caster, hero, amaterasu:GetSpecialValueFor("damage_per_cast"), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
        hero:EmitSound("Hero_Pugna.NetherWard.Attack")
        local particle = ParticleManager:CreateParticle("particles/tamamo/tamamo_amaterasu_enemy.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
        ParticleManager:SetParticleControlEnt(particle,	0, caster,	PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetOrigin(), true)
        ParticleManager:SetParticleControlEnt(particle,	1, hero,	PATTACH_POINT_FOLLOW, "attach_origin", hero:GetOrigin(), true)
        hero.AmaterasuProcCd = true
        Timers:CreateTimer(2, function()
        	hero.AmaterasuProcCd = false
    	end)
    end
end

modifier_amaterasu_enemy_slow = class({})

function modifier_amaterasu_enemy_slow:IsHidden() return true end
function modifier_amaterasu_enemy_slow:IsDebuff() return true end

function modifier_amaterasu_enemy_slow:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,

                        --MODIFIER_EVENT_ON_ABILITY_EXECUTED
                    }
    return tFunc
end

function modifier_amaterasu_enemy_slow:GetModifierMoveSpeedBonus_Percentage()
	return -70
end