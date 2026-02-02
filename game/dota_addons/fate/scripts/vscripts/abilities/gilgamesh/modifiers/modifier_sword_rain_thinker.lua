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
		local parent = self:GetParent()
		--print(sword_loc)

		local swordFxIndex = ParticleManager:CreateParticle( "particles/custom/gilgamesh/gilgamesh_sword_barrage_model.vpcf", PATTACH_CUSTOMORIGIN, parent)
		ParticleManager:SetParticleControl(swordFxIndex, 0, spawn_location)
		ParticleManager:SetParticleControl(swordFxIndex, 1, (sword_loc - spawn_location):Normalized() * 3000)		

		Timers:CreateTimer(0.5, function()
			local targets = FindUnitsInRadius(caster:GetTeam(), target_loc, nil, aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

			for i = 1, #targets do
				if  not targets[i]:HasModifier("modifier_protection_from_arrows_active") then 
					DoDamage(caster, targets[i], damage, DAMAGE_TYPE_PHYSICAL, 0, ability, false)
					targets[i]:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
				end
			end

			local explosionFxIndex = ParticleManager:CreateParticle( "particles/gilgamesh/gob_hit_extra_big.vpcf", PATTACH_CUSTOMORIGIN, parent )
			ParticleManager:SetParticleControl( explosionFxIndex, 0, target_loc + RandomVector(0))
			ParticleManager:SetParticleControl( explosionFxIndex, 1, Vector(aoe,0,0))
			local impactFxIndex = ParticleManager:CreateParticle( "particles/custom/gilgamesh/gil_sword_barrage_impact_circle.vpcf", PATTACH_CUSTOMORIGIN, parent )
			ParticleManager:SetParticleControl( impactFxIndex, 0, target_loc)
			ParticleManager:SetParticleControl( impactFxIndex, 1, Vector(aoe,aoe,aoe) )
			if #targets >= 1 then
				ParticleManager:SetParticleShouldCheckFoW(explosionFxIndex, false)
				ParticleManager:SetParticleShouldCheckFoW(impactFxIndex, false)
				ParticleManager:SetParticleShouldCheckFoW(swordFxIndex, false)
			end
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