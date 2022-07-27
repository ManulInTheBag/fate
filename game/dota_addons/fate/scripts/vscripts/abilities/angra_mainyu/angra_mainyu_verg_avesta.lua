angra_mainyu_verg_avesta = class({})

LinkLuaModifier("modifier_verg_damage_tracker", "abilities/angra_mainyu/modifiers/modifier_verg_damage_tracker", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_verg_damage_tracker_progress", "abilities/angra_mainyu/modifiers/modifier_verg_damage_tracker", LUA_MODIFIER_MOTION_NONE)

function angra_mainyu_verg_avesta:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self

	EmitGlobalSound("Avenger.Berg")
	EmitGlobalSound("Avenger.BergShout")

	local modifier = caster:FindModifierByName("modifier_verg_damage_tracker")

	local verg_particle = ParticleManager:CreateParticle("particles/custom/avenger/avenger_verg_avesta.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(verg_particle, 0, caster:GetAbsOrigin())

	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle( verg_particle, false )
		ParticleManager:ReleaseParticleIndex( verg_particle )
		return nil
	end)

	if modifier then 
		local damage = modifier:GetDamageTaken()
		local multiplier = self:GetSpecialValueFor("multiplier")

		if caster.IsDIAcquired and caster:HasModifier("modifier_true_form") then
			multiplier = multiplier + 25
		end

		damage = damage * (multiplier / 100)

		LoopOverPlayers(function(player, playerID, playerHero)
	        if playerHero:IsAlive() and playerHero:HasModifier("modifier_verg_marker") and not playerHero:IsMagicImmune() then
	        	DoDamage(caster, playerHero, damage, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, true)
	        	if not playerHero:IsAlive() then
	        		if playerHero:GetTeamNumber() == caster:GetTeamNumber() then
	        			EmitGlobalSound("body_reported")
	        		end
	        	end
	        	playerHero:RemoveModifierByName("modifier_verg_marker")

	        	playerHero:EmitSound("Hero_WitchDoctor.Maledict_Tick")
		        local particle = ParticleManager:CreateParticle("particles/econ/items/sniper/sniper_charlie/sniper_assassinate_impact_blood_charlie.vpcf", PATTACH_CUSTOMORIGIN, nil)
		        ParticleManager:SetParticleControl(particle, 1, playerHero:GetAbsOrigin())
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