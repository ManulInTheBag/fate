modifier_sword_rain_thinker = class({})

if IsServer() then
	function modifier_sword_rain_thinker:OnCreated(args)
		self.Location = self:GetParent():GetAbsOrigin()
		self.CasterOriginalLoc = self:GetCaster():GetAbsOrigin()
		
		self.Damage = args.Damage
		self.Radius = args.Radius
		self:StartIntervalThink(0.2)
	end

	function modifier_sword_rain_thinker:OnIntervalThink()
		local target_loc = self.Location
		local sword_loc = RandomPointInCircle(target_loc, self.Radius * 0.5)
		local spawn_location = self.CasterOriginalLoc + Vector(0, 0, 1500 * math.tan( 60 / 180 * math.pi ))
		local damage = self.Damage
		local caster = self:GetCaster()
		local aoe = self.Radius
		local ability = self:GetAbility()

		--print(sword_loc)

		local swordFxIndex = ParticleManager:CreateParticle( "particles/custom/gilgamesh/gilgamesh_sword_barrage_model.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(swordFxIndex, 0, spawn_location)
		ParticleManager:SetParticleControl(swordFxIndex, 1, (sword_loc - spawn_location):Normalized() * 3000)		

		Timers:CreateTimer(0.5, function()
			local targets = FindUnitsInRadius(caster:GetTeam(), target_loc, nil, aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

			for i = 1, #targets do
				DoDamage(caster, targets[i], damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
				targets[i]:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
			end

			local explosionFxIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_gyrocopter/gyro_guided_missile_explosion.vpcf", PATTACH_CUSTOMORIGIN, caster )
			ParticleManager:SetParticleControl( explosionFxIndex, 0, target_loc + RandomVector(200))

			local impactFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_sword_barrage_impact_circle.vpcf", PATTACH_CUSTOMORIGIN, caster )
			ParticleManager:SetParticleControl( impactFxIndex, 0, target_loc)
			ParticleManager:SetParticleControl( impactFxIndex, 1, Vector(aoe,aoe,aoe) )
				
			-- Destroy Particle
			Timers:CreateTimer( 0.5, function()
				ParticleManager:DestroyParticle( explosionFxIndex, false )
				ParticleManager:DestroyParticle( impactFxIndex, false )
				ParticleManager:ReleaseParticleIndex( explosionFxIndex )
				ParticleManager:ReleaseParticleIndex( impactFxIndex )
				return
			end)

			return
		end)
	end
end

function modifier_sword_rain_thinker:IsHidden()
	return true
end