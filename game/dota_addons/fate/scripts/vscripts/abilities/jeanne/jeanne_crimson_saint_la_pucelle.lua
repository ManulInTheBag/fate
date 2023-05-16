jeanne_crimson_saint_la_pucelle = class({})

LinkLuaModifier("modifier_jeanne_crimson_saint_delay", "abilities/jeanne/modifiers/modifier_jeanne_crimson_saint_delay", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_crimson_saint_stun", "abilities/jeanne/modifiers/modifier_jeanne_crimson_saint_stun", LUA_MODIFIER_MOTION_NONE)

function jeanne_crimson_saint_la_pucelle:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local delay_duration = self:GetSpecialValueFor("delay_duration")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local damage = self:GetSpecialValueFor("damage")
	local targets = DOTA_UNIT_TARGET_HERO
	
	local enemyuser= PickRandomEnemy(caster)
	if enemyuser then
        caster:AddNewModifier(enemyuser, nil, "modifier_vision_provider", { Duration = 1 })
    end
	
	Timers:CreateTimer(0.5, function()
		EmitGlobalSound("jeanne_combo_end")
	end)
	
	Timers:CreateTimer(0, function()
		if caster:IsAlive() then
			StartAnimation(caster, {duration=1, activity=ACT_DOTA_CAST_ABILITY_4, rate=1})
			caster:AddNewModifier( self:GetCaster(), self, "modifier_jeanne_crimson_saint_delay", { duration = 1 } )
		end
		return
	end)

	local particle = ParticleManager:CreateParticle("particles/custom/ruler/la_pucelle/ruler_la_pucelle.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControlEnt( particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_origin", caster:GetAbsOrigin(), true )
	ParticleManager:SetParticleControl( particle, 1, caster:GetAbsOrigin() )

	Timers:CreateTimer(1, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)
	
	Timers:CreateTimer(1, function()
		if caster:IsAlive() or not caster:IsAlive() then
			damage = damage + caster:GetHealth()*self:GetSpecialValueFor("hp_damage")/100
			local LaPucelleExplosion = ParticleManager:CreateParticle("particles/custom/jeanne/jeanne_crimson_saint_burst.vpcf", PATTACH_CUSTOMORIGIN, nil)
			ParticleManager:SetParticleControl( LaPucelleExplosion, 0, caster:GetAbsOrigin())
			
			--[[local LaPucelleAura = ParticleManager:CreateParticle("particles/custom/jeanne/la_pucelle_aura.vpcf", PATTACH_CUSTOMORIGIN, self.Dummy)
			ParticleManager:SetParticleControlEnt(LaPucelleAura, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true)
			ParticleManager:SetParticleControl(LaPucelleAura, 1, caster:GetOrigin())]]
			
			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( LaPucelleExplosion, false )
				ParticleManager:ReleaseParticleIndex( LaPucelleExplosion )
				--[[ParticleManager:DestroyParticle( LaPucelleAura, false )
				ParticleManager:ReleaseParticleIndex( LaPucelleAura )]]
			end)
			
			ScreenShake(caster:GetOrigin(), 10, 1.5, 3, 40000, 0, true)
			
			EmitGlobalSound("jeanne_la_pucelle_explosion")
			
			-- Find Units in Radius
			local enemies = FindUnitsInRadius(
				self:GetCaster():GetTeamNumber(),	-- int, your team number
				caster:GetAbsOrigin() ,	-- point, center point
				nil,	-- handle, cacheUnit. (not known)
				radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
				DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
				targets,	-- int, type filter
				0,	-- int, flag filter
				0,	-- int, order filter
				false	-- bool, can grow cache
			)
	
			for _,enemy in pairs(enemies) do
				-- Add modifier
				--[[if caster:HasModifier("modifier_jeanne_attribute_holy_light") then
					ApplyStrongDispel(enemy)
				end]]
				
				DoDamage(caster, enemy, damage, DAMAGE_TYPE_PURE, 0, self, false)
				enemy:AddNewModifier(caster, self, "modifier_stunned", { Duration = stun_duration })

				local rope_fx = ParticleManager:CreateParticle("particles/jeanne/jeanne_la_pucelle_rope.vpcf", PATTACH_POINT_FOLLOW, caster)
				ParticleManager:SetParticleControlEnt(rope_fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
				ParticleManager:SetParticleControlEnt(rope_fx, 1, enemy, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)

				ParticleManager:ReleaseParticleIndex(rope_fx)

				local effect_target = ParticleManager:CreateParticle( "particles/jeanne/jeanne_la_pucelle_target.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
				ParticleManager:SetParticleControlEnt(effect_target, 1, enemy, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(0, 0, 0), true)
				ParticleManager:ReleaseParticleIndex( effect_target )
			end
			
			if caster:IsAlive() then
				caster:Execute(self, caster, { bExecution = true })
			end
		end
		return
	end)
end

--------------------------------------------------------------------------------