arturia_alter_tyrant_clap = class({})

LinkLuaModifier("modifier_clap_slow", "abilities/arturia_alter/modifiers/modifier_clap_slow", LUA_MODIFIER_MOTION_NONE)

function arturia_alter_tyrant_clap:GetBehavior()
	local caster = self:GetCaster()

	if caster:HasModifier("modifier_hammer_attribute") then
		return DOTA_ABILITY_BEHAVIOR_OPTIONAL_UNIT_TARGET
	else
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
	end
end

function arturia_alter_tyrant_clap:CastFilterResultTarget(hTarget)
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function arturia_alter_tyrant_clap:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function arturia_alter_tyrant_clap:CalculateAbilityDamage()
	local caster = self:GetCaster()

	local damage = caster:GetAverageTrueAttackDamage(caster)

	damage = damage * self:GetSpecialValueFor("ability_damage") / 100

	return damage
end

function arturia_alter_tyrant_clap:OnSpellStart()
	local position = nil
	local caster = self:GetCaster()

	if self:GetCursorTargetingNothing() then
		position = self:GetCursorPosition()
	else
		position = self:GetCursorTarget():GetAbsOrigin()
	end

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, self:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	local damage = self:CalculateAbilityDamage()

	for k,v in pairs(targets) do
	    DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self)

	    if v:GetManaPercent() < caster:GetManaPercent() then
	    	v:AddNewModifier(caster, self, "modifier_stunned", { Duration = self:GetSpecialValueFor("stun_duration") })
	    else
	    	v:AddNewModifier(caster, self, "modifier_clap_slow",  { Duration = self:GetSpecialValueFor("slow_duration"),
	    															SlowPct = self:GetSpecialValueFor("slow_pct") })
	    end
	end

	EmitSoundOnLocationWithCaster(position, "Hero_Nevermore.Shadowraze", caster)
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position) 

	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)
end