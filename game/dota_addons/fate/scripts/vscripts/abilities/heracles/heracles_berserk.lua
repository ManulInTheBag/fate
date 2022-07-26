heracles_berserk = class({})

LinkLuaModifier("modifier_heracles_berserk", "abilities/heracles/modifiers/modifier_heracles_berserk", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heracles_combo_window", "abilities/heracles/modifiers/modifier_heracles_combo_window", LUA_MODIFIER_MOTION_NONE)

function heracles_berserk:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local hplock = math.max(caster:GetHealth(), caster:GetMaxHealth()*self:GetSpecialValueFor("health_constant")/100)
	local duration = self:GetSpecialValueFor("duration")
	local attack_speed = self:GetSpecialValueFor("bns_att_spd")
	local radius = 300

	if caster:HasModifier("modifier_mad_enhancement_attribute") then
		duration = duration + 2
	end

	caster:AddNewModifier(caster, ability, "modifier_heracles_berserk", { BonusAttSpd = attack_speed, 
																		  LockedHealth = hplock,
																		  Duration = duration })
	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.voice == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Nanomachines"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)

	local casterHealth = caster:GetHealth()
	if casterHealth - hplock > 0 then
		local berserkDamage = math.min((casterHealth - hplock), self:GetSpecialValueFor("max_damage"))  
		caster:EmitSound("Hero_Centaur.HoofStomp")

		local berserkExp = ParticleManager:CreateParticle("particles/custom/berserker/berserk/eternal_rage_shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(berserkExp, 1, Vector(radius,0,radius))

		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 400, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for k,v in pairs(targets) do
	        DoDamage(caster, v, berserkDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		end
	end

	if caster.IsEternalRageAcquired then 
		local explosionCounter = 0
		local manaregenCounter = 0

		Timers:CreateTimer(function()
			if not caster:HasModifier("modifier_heracles_berserk") then return end
			if explosionCounter == duration then return end

			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for k,v in pairs(targets) do
		        DoDamage(caster, v, caster.BerserkDamageTaken/5, DAMAGE_TYPE_MAGICAL, 0, self, false)
			end
			caster.BerserkDamageTaken = 0
			local berserkExp = ParticleManager:CreateParticle("particles/custom/berserker/berserk/eternal_rage_shockwave.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(berserkExp, 1, Vector(radius,0,radius))

			explosionCounter = explosionCounter + 1.0
			return 1.0
			end
		)
	end
	
	EmitGlobalSound("Berserker.Roar")
end

