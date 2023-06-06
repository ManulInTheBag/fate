angra_mainyu_verg_avesta = class({})

LinkLuaModifier("modifier_verg_damage_tracker", "abilities/angra_mainyu/modifiers/modifier_verg_damage_tracker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_verg_damage_tracker_progress", "abilities/angra_mainyu/modifiers/modifier_verg_damage_tracker", LUA_MODIFIER_MOTION_NONE)

function angra_mainyu_verg_avesta:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function angra_mainyu_verg_avesta:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local radius = self:GetAOERadius()
	local delay = self:GetSpecialValueFor("delay")

	Timers:CreateTimer(delay, function()
		EmitGlobalSound("Avenger.Berg")
	end)
	EmitGlobalSound("Avenger.BergShout")

	local modifier = caster:FindModifierByName("modifier_verg_damage_tracker")

	local verg_particle = ParticleManager:CreateParticle("particles/custom/avenger/avenger_verg_avesta.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(verg_particle, 0, caster:GetAbsOrigin())

	Timers:CreateTimer(delay, function()
		ParticleManager:DestroyParticle( verg_particle, false )
		ParticleManager:ReleaseParticleIndex( verg_particle )
		return nil
	end)

	if modifier then 
		local damage = modifier:GetDamageTaken()
		local multiplier = self:GetSpecialValueFor("multiplier")

		if caster.IsDIAcquired and caster:HasModifier("modifier_true_form") then
			multiplier = multiplier + self:GetSpecialValueFor("return_bonus")
		end

		damage = damage * (multiplier / 100)

		LoopOverPlayers(function(player, playerID, playerHero)
	        if playerHero:IsAlive() and playerHero:HasModifier("modifier_verg_marker") and not playerHero:IsMagicImmune() then
				if playerHero:GetTeamNumber() ~= caster:GetTeamNumber() and GetDistance(playerHero, caster) <= radius then
					playerHero:RemoveModifierByName("modifier_verg_marker")
					local verg_particle_hero = ParticleManager:CreateParticle("particles/custom/avenger/avenger_verg_avesta.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, playerHero)
					ParticleManager:SetParticleControl(verg_particle_hero, 0, playerHero:GetAbsOrigin())

					Timers:CreateTimer(delay, function()
						ParticleManager:DestroyParticle( verg_particle_hero, false )
						ParticleManager:ReleaseParticleIndex( verg_particle_hero )
						return nil
					end)
					Timers:CreateTimer(delay, function()
						if playerHero and playerHero:IsAlive() then
							DoDamage(caster, playerHero, damage, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, true)
							--EmitGlobalSound("body_reported")

				        	playerHero:EmitSound("Hero_WitchDoctor.Maledict_Tick")
					        local particle = ParticleManager:CreateParticle("particles/econ/items/sniper/sniper_charlie/sniper_assassinate_impact_blood_charlie.vpcf", PATTACH_CUSTOMORIGIN, nil)
					        ParticleManager:SetParticleControl(particle, 1, playerHero:GetAbsOrigin())
					    end
	        	 	end)
				end
	        end
	    end)

	    modifier:ResetCounter()
	end
end

function angra_mainyu_verg_avesta:OnUpgrade()
    if not self:GetCaster():HasModifier("modifier_verg_damage_tracker_progress") then
        self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_verg_damage_tracker_progress", {})
    end
end

function angra_mainyu_verg_avesta:GetIntrinsicModifierName()
	return "modifier_verg_damage_tracker"
end