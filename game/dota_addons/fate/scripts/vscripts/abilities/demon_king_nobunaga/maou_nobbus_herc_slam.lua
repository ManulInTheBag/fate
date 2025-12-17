maou_nobbus_herc_slam = class({})

function maou_nobbus_herc_slam:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "nobus_big", caster)
	StartAnimation(caster, {duration=0.8, activity=ACT_DOTA_ATTACK, rate=0.8})
	
end

function maou_nobbus_herc_slam:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	caster:StopSound("nobus_big")
	 EndAnimation(caster)

end

function maou_nobbus_herc_slam:OnSpellStart()
	local caster = self:GetCaster()
	local distance_to_point = (caster:GetAbsOrigin() - self:GetCursorPosition()):Length2D() 
	local knockDist =  math.min(self:GetSpecialValueFor("jump_range"), distance_to_point)
	
	local knockback1 = { should_stun = true,
						knockback_duration = 0.5,
						duration = 0.5,
						knockback_distance = -knockDist,
						knockback_height = 500,
						center_x = self:GetCursorPosition().x,
						center_y = self:GetCursorPosition().y,
						center_z = self:GetCursorPosition().z }
	caster:RemoveModifierByName("modifier_knockback")
	caster:AddNewModifier(caster, self, "modifier_knockback", knockback1)
	local damage = self:GetSpecialValueFor("damage")  + caster.Level * self:GetSpecialValueFor("damage_per_caster_level")
	local range = self:GetSpecialValueFor("range")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local width = self:GetSpecialValueFor("width")
	local vec = (self:GetCursorPosition() - caster:GetAbsOrigin() ):Normalized()
	Timers:CreateTimer(0.5, function()
		local point = caster:GetAbsOrigin()

		local pointEnd =point + range * vec
		local hEnemies =   FindUnitsInLine(
							caster:GetTeamNumber(),
							point,
							pointEnd,
							nil,
							width,
							DOTA_UNIT_TARGET_TEAM_ENEMY,
							DOTA_UNIT_TARGET_ALL,
							0
		)
		EmitSoundOnLocationWithCaster(pointEnd, "heracles_q_new_1", caster)

		for _, enemy in pairs(hEnemies) do
			 DoDamage(caster.Caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, caster.Ability, false)

			giveUnitDataDrivenModifier(caster,enemy , "stunned", stun_duration)
		end
		local particle = ParticleManager:CreateParticle("particles/zlodemon/heracles/heracles_fissure_nobbus.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControlTransformForward(particle, 0, caster:GetAbsOrigin()+caster:GetForwardVector() * 100, caster:GetForwardVector())
		ParticleManager:SetParticleControlTransformForward(particle, 1, caster:GetAbsOrigin()+caster:GetForwardVector() * 100,  caster:GetForwardVector())
		ParticleManager:SetParticleControlTransformForward(particle, 3, Vector(range, 0, 0))
	
	end)
	
end