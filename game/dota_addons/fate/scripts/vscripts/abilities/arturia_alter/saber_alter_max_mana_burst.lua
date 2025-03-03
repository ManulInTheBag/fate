LinkLuaModifier("modifier_max_mana_burst_cooldown", "abilities/arturia_alter/saber_alter_max_mana_burst", LUA_MODIFIER_MOTION_NONE)
saber_alter_max_mana_burst = class({})


function saber_alter_max_mana_burst:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end


function saber_alter_max_mana_burst:OnSpellStart(keys)
	local caster = self:GetCaster()
	local ability = self
	local radius = self:GetSpecialValueFor("radius")
	local roflParticle = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(roflParticle)
	-- Set master's combo cooldown
	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(self:GetCooldown(1))
	caster:AddNewModifier(caster, self, "modifier_max_mana_burst_cooldown", {duration = self:GetCooldown(1)})
	caster:FindAbilityByName("saber_alter_mana_burst"):StartCooldown(15.0)
    giveUnitDataDrivenModifier(caster, caster, "pause_sealdisabled", 1)
	StartAnimation(caster, {duration=1, activity=ACT_DOTA_CAST_ABILITY_1, rate=1.5})
	EmitGlobalSound("salter_combo_voiceline")
	local fxIndexjopa = ParticleManager:CreateParticle("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fxIndexjopa, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(fxIndexjopa, 1, Vector(0.1,0.1,1))
	ParticleManager:SetParticleControl(fxIndexjopa, 2, Vector(radius,1.3,0))
	ParticleManager:ReleaseParticleIndex(fxIndexjopa)
	local fxIndexjopa2 = ParticleManager:CreateParticle("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fxIndexjopa2, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(fxIndexjopa2, 1, Vector(0.4,0.01,0.7))
	ParticleManager:SetParticleControl(fxIndexjopa2, 2, Vector(700,1.3,0))
	ParticleManager:ReleaseParticleIndex(fxIndexjopa2)
	local fxIndexjopa3 = ParticleManager:CreateParticle("particles/zlodemon/zlodemon_basic_circle.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fxIndexjopa3, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(fxIndexjopa3, 1, Vector(0.2,0.01,0.7))
	ParticleManager:SetParticleControl(fxIndexjopa3, 2, Vector(1300,1.3,0))
	ParticleManager:ReleaseParticleIndex(fxIndexjopa3)
	Timers:CreateTimer( 1.3, function()
		if caster:IsAlive() then 
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			EmitGlobalSound("Saber_Alter.MMB" ) 
			
			EmitGlobalSound("Saber_Alter.MMBAfter") 
			--EmitGlobalSound("Killer_Queen")
			LoopOverPlayers(function(player, playerID, playerHero)
				--print("looping through " .. playerHero:GetName())
				if playerHero.music == true then
					-- apply legion horn vsnd on their client
					CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Killer_Queen"})
					--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
				end
			end)
			local BlueSplashFx = ParticleManager:CreateParticle("particles/custom/screen_blue_splash.vpcf", PATTACH_EYES_FOLLOW, caster)
			ScreenShake(caster:GetOrigin(), 15, 2.0, 2, 10000, 0, true)
			-- Destroy particle
			Timers:CreateTimer( 3.0, function()
				ParticleManager:DestroyParticle( BlueSplashFx, false )
				ParticleManager:ReleaseParticleIndex(BlueSplashFx)
			end)

			local dmg = caster:GetMaxMana()*1.3
			if caster.IsManaBlastAcquired then
				dmg = caster:GetMaxMana()*1.6
			end
			local finaldmg = dmg

			for k,v in pairs(targets) do
				local dist = (v:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() 
				if dist <= 700 then
					finaldmg = dmg
				elseif dist > 700 and dist <= 1300 then
					finaldmg = dmg*0.8
				elseif dist > 1300 and dist <= 2000 then
					finaldmg = dmg*0.6
				end

				DoDamage(caster, v, finaldmg , DAMAGE_TYPE_MAGICAL, 0, self, false)
			end

			local particle1 = ParticleManager:CreateParticle("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(particle1, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle1, 1, Vector(radius, 0, 0))
			local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(particle2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle2, 1, Vector(radius, 0, 0))
			ParticleManager:SetParticleControl(particle2, 2, Vector(1, 0, 0))
			local particle3 = ParticleManager:CreateParticle("particles/units/heroes/hero_slark/slark_dark_pact_pulses.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl(particle3, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle3, 2, Vector(radius, 0, 0))
			Timers:CreateTimer(1.5, function()
			
				ParticleManager:DestroyParticle( particle1, false )
				ParticleManager:ReleaseParticleIndex(particle1)
				ParticleManager:DestroyParticle( particle2, false )
				ParticleManager:ReleaseParticleIndex(particle2)
				ParticleManager:DestroyParticle( particle3, false )
				ParticleManager:ReleaseParticleIndex(particle3)
			end)

		end
    end)
	
end

modifier_max_mana_burst_cooldown = class({})


function modifier_max_mana_burst_cooldown:IsHidden()
    return false 
end

function modifier_max_mana_burst_cooldown:RemoveOnDeath()
    return false
end

function modifier_max_mana_burst_cooldown:IsDebuff()
    return true 
end

function modifier_max_mana_burst_cooldown:GetAttributes()
    return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end