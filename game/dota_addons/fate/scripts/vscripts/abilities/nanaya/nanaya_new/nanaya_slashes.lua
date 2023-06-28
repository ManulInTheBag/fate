nanaya_slashes = class({})

function nanaya_slashes:OnSpellStart()
	local caster = self:GetCaster()
	local slash_count = self:GetSpecialValueFor("slash_count")
	local radius = self:GetSpecialValueFor("radius")
	local interval = 0.05

	caster:EmitSound("nanaya.zange")

	StartAnimation(caster, {duration=0.35, activity=ACT_DOTA_CAST_ABILITY_5, rate=1})

	Timers:CreateTimer(0, function()
		slash_count = slash_count - 1
		if slash_count <= 0 then
			interval = nil
		else
			giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", 0.06)
		end

		local part = math.random(-40, 40)
		local part2 = -20
		if slash_count%2 == 0 then
			part = part + 180
			part2 = 20
		end

		local particle = ParticleManager:CreateParticle("particles/nanaya/nanaya_slash.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 5, Vector(self:GetSpecialValueFor("radius") + 50, 0, 110))
		ParticleManager:SetParticleControl(particle, 10, Vector(0, part, -90 + part2))
		Timers:CreateTimer(1, function()
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
		end)

		caster:EmitSound("nanaya.slash")

		local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        radius,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
                                        FIND_ANY_ORDER,
                                        false)

	    for _,enemy in pairs(enemies) do
	    	local damage = self:GetSpecialValueFor("damage") + ((caster.ScaleAcquired and caster:HasModifier("modifier_nanaya_instinct")) and caster:GetAgility()*self:GetSpecialValueFor("attribute_agility_multiplier") or 0)
			local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
			local origin_diff_norm = origin_diff:Normalized()
			if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then
				local hit_particle = ParticleManager:CreateParticle("particles/nanaya_work_22.vpcf", PATTACH_ABSORIGIN, enemy)
				ParticleManager:ReleaseParticleIndex(hit_particle)

				giveUnitDataDrivenModifier(caster, enemy, "silenced", 0.3)

				--enemy:AddNewModifier(caster, self, "silenced", { Duration = 0.3 })
			    DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	        end
	    end

	    return interval
	end)
end