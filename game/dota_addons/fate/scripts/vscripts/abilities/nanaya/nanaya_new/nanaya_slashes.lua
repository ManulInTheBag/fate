nanaya_slashes = class({})

function nanaya_slashes:OnSpellStart()
	local caster = self:GetCaster()
	local slash_count = self:GetSpecialValueFor("slash")
	local radius = 500
	local interval = 0.05
	local damage = self:GetSpecialValueFor("dmg")

	local slash_particle = ParticleManager:CreateParticle("particles/check_slashes.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(slash_particle, 4, caster:GetAbsOrigin() + caster:GetForwardVector() * 1600)

	Timers:CreateTimer(0, function()
		slash_count = slash_count - 1
		if slash_count <= 0 then
			interval = nil
			ParticleManager:DestroyParticle(slash_particle, false)
			ParticleManager:ReleaseParticleIndex(slash_particle)
		end

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
			local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
			local origin_diff_norm = origin_diff:Normalized()
			if caster:GetForwardVector():Dot(origin_diff_norm) > 0 then

				enemy:EmitSound("nanaya.slash")

				local hit_particle = ParticleManager:CreateParticle("particles/nanaya_work_22.vpcf", PATTACH_ABSORIGIN, enemy)
				ParticleManager:ReleaseParticleIndex(hit_particle)

				enemy:AddNewModifier(caster, self, "modifier_silence", { Duration = 0.3 })
			    DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	        end
	    end

	    return interval
	end)
end