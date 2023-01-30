LinkLuaModifier("modifier_altera_adaptive", "abilities/altera/altera_adaptive", LUA_MODIFIER_MOTION_NONE)

altera_adaptive = class({})

function altera_adaptive:OnAbilityPhaseStart()
    StartAnimation(self:GetCaster(), {duration=1.5, activity=ACT_DOTA_CAST_ABILITY_4, rate=1.0})
    return true
end

function altera_adaptive:OnAbilityPhaseInterrupted()
    EndAnimation(self:GetCaster())
end

function altera_adaptive:OnSpellStart()
	local caster = self:GetCaster()
	local delay = self:GetSpecialValueFor("duration")

	local damage = self:GetSpecialValueFor("damage")
	local damage1 = 0
	local damage2 = 0
	local mult = self:GetSpecialValueFor("damage_mult")
	local radius = self:GetSpecialValueFor("radius")
	local form = "neutral"

	caster:AddNewModifier(caster, self, "modifier_altera_adaptive", {duration = delay})
	caster:FindAbilityByName("altera_form_open"):OpenSezame()
	caster:FindAbilityByName("altera_form_close"):StartCooldown(caster:FindAbilityByName("altera_form_open"):GetCooldown(0))

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

	local particlename1 = "particles/altera/altera_adaptive.vpcf"
	local particlename2 = "particles/altera/altera_adaptive.vpcf"

	if caster:HasModifier("modifier_altera_form_str") then
        damage1 = damage + mult*caster:GetStrength()
        particlename1 = "particles/altera/altera_adaptive_red.vpcf"
    end
    if caster:HasModifier("modifier_altera_form_agi") then
        damage1 = damage + mult*caster:GetAgility()
        particlename1 = "particles/altera/altera_adaptive_green.vpcf"
    end
    if caster:HasModifier("modifier_altera_form_int") then
        damage1 = damage + mult*caster:GetIntellect()
        particlename1 = "particles/altera/altera_adaptive_blue.vpcf"
    end

    local hit_fx = ParticleManager:CreateParticle(particlename1, PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( hit_fx, 0, GetGroundPosition(caster:GetAbsOrigin(), caster))
	ParticleManager:SetParticleControl( hit_fx, 1, Vector(radius - 50, (radius-50)/3, 25))

	for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
			DoDamage(caster, enemy, damage1, DAMAGE_TYPE_MAGICAL, 0, self, false)
        end
    end

	Timers:CreateTimer(delay - FrameTime(), function()
		if caster and caster:IsAlive() then
			if caster:HasModifier("modifier_altera_form_str") then
		        damage2 = damage + mult*caster:GetStrength()
		        particlename2 = "particles/altera/altera_adaptive_red.vpcf"
		    end
		    if caster:HasModifier("modifier_altera_form_agi") then
		        damage2 = damage + mult*caster:GetAgility()
		        particlename2 = "particles/altera/altera_adaptive_green.vpcf"
		    end
		    if caster:HasModifier("modifier_altera_form_int") then
		        damage2 = damage + mult*caster:GetIntellect()
		        particlename2 = "particles/altera/altera_adaptive_blue.vpcf"
		    end
		end

		caster:FindAbilityByName("altera_form_close"):OnSpellCalled(true)

		local point = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*100, caster)

		EmitSoundOnLocationWithCaster(point, "Hero_Leshrac.Split_Earth", caster)

		local hit_fx2 = ParticleManager:CreateParticle(particlename2, PATTACH_ABSORIGIN, caster )
		ParticleManager:SetParticleControl( hit_fx2, 0, point)
		ParticleManager:SetParticleControl( hit_fx2, 1, Vector(radius, radius/3, 25))

		local enemies2 = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for _, enemy in pairs(enemies2) do
	        if enemy and not enemy:IsNull() and IsValidEntity(enemy) then
				DoDamage(caster, enemy, damage2, DAMAGE_TYPE_MAGICAL, 0, self, false)
	        end
	    end
	end)
end

modifier_altera_adaptive = class({})

function modifier_altera_adaptive:IsHidden() return true end

function modifier_altera_adaptive:CheckState()
	return { [MODIFIER_STATE_NO_HEALTH_BAR]	= true,
			 [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			 [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			 [MODIFIER_STATE_UNSELECTABLE] = true,
			 [MODIFIER_STATE_STUNNED] = true}
end