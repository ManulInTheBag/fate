LinkLuaModifier("modifier_arcueid_melty", "abilities/arcueid/arcueid_melty", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arcueid_melty_cd", "abilities/arcueid/arcueid_melty", LUA_MODIFIER_MOTION_NONE)

arcueid_melty = class({})

function arcueid_melty:CastFilterResultLocation(hLocation)
    if self.launched then
    	return UF_FAIL_CUSTOM
    else
    	return UF_SUCCESS
    end
end

function arcueid_melty:GetCustomCastErrorLocation(hLocation)
    if self.launched then
    	return "#Already active"
    end
end

function arcueid_melty:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function arcueid_melty:OnSpellStart()
	local caster = self:GetCaster()

	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
    local abil = caster:FindAbilityByName("arcueid_melty")
    abil:StartCooldown(abil:GetCooldown(abil:GetLevel() - 1))

    caster:RemoveModifierByName("modifier_arcueid_combo_window")

    caster:AddNewModifier(caster, self, "modifier_arcueid_melty_cd", {duration = self:GetCooldown(1)})

    EmitGlobalSound("arcueid_combo_end")

	local target = self:GetCursorTarget()
	target:AddNewModifier(caster, self, "modifier_arcueid_melty", {duration = self:GetSpecialValueFor("duration")})
end

function arcueid_melty:ChainHunt(source_enemy)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = self

	self.AttackedTargets    = {}
	self.source_enemy = source_enemy

	local smokeFx3 = ParticleManager:CreateParticle("particles/custom_game/heroes/kenshiro/kenshiro_pressure_points_explosion/kenshiro_pressure_points_explosion_blood.vpcf", PATTACH_CUSTOMORIGIN, self.source_enemy)
	ParticleManager:SetParticleControl(smokeFx3, 0, self.source_enemy:GetAbsOrigin())
	ParticleManager:DestroyParticle(smokeFx3, false)
	ParticleManager:ReleaseParticleIndex(smokeFx3)

	for i = 1,4 do
		Timers:CreateTimer(0.0 + FrameTime()*i*2, function()
			if not self.source_enemy then return end
			--local smokeFx3 = ParticleManager:CreateParticle("particles/custom/ta/zabaniya_fiendsgrip_hands.vpcf", PATTACH_CUSTOMORIGIN, self.source_enemy)
			--ParticleManager:SetParticleControl(smokeFx3, 0, self.source_enemy:GetAbsOrigin())
			EmitSoundOn("arcueid_hit", self.source_enemy)
			EmitSoundOn("Hero_PhantomAssassin.CoupDeGrace", self.source_enemy)
			if self.source_enemy:IsAlive() then
				DoDamage(caster, self.source_enemy, self:GetSpecialValueFor("damage")/4, DAMAGE_TYPE_MAGICAL, 0, self, false)
			end
			local random = RandomVector(60)
			local random2 = RandomVector(300)
			local rand = math.random(0, 150)
			if math.random(1, 2) == 2 then
				rand = -1*rand
			end
			local Particle = ParticleManager:CreateParticle("particles/arcueid/arcueid_beam_red.vpcf", PATTACH_CUSTOMORIGIN, self.source_enemy)
			ParticleManager:SetParticleControl( Particle, 1, self.source_enemy:GetAbsOrigin() + random2 + Vector(0, 0, 150 + rand))
			ParticleManager:SetParticleControl( Particle, 0, self.source_enemy:GetAbsOrigin() + random + Vector(0, 0, 100))
			local Particle2 = ParticleManager:CreateParticle("particles/arcueid/arcueid_beam_red.vpcf", PATTACH_CUSTOMORIGIN, self.source_enemy)
			ParticleManager:SetParticleControl( Particle2, 0, self.source_enemy:GetAbsOrigin() - random2 + Vector(0, 0, 150 - rand))
			ParticleManager:SetParticleControl( Particle2, 1, self.source_enemy:GetAbsOrigin() + random + Vector(0, 0, 100))
			Timers:CreateTimer(0.2, function()
				ParticleManager:DestroyParticle(Particle, false)
				ParticleManager:ReleaseParticleIndex(Particle)
				ParticleManager:DestroyParticle(Particle2, false)
				ParticleManager:ReleaseParticleIndex(Particle2)
			end)
			local smokeFx3 = ParticleManager:CreateParticle("particles/custom_game/heroes/kenshiro/kenshiro_pressure_points_explosion/kenshiro_pressure_points_explosion_blood.vpcf", PATTACH_CUSTOMORIGIN, self.source_enemy)
			ParticleManager:SetParticleControl(smokeFx3, 0, self.source_enemy:GetAbsOrigin())
			ParticleManager:DestroyParticle(smokeFx3, false)
			ParticleManager:ReleaseParticleIndex(smokeFx3)
			local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_crit_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.source_enemy )
			ParticleManager:SetParticleControlEnt(
				effect_cast,
				0,
				self.source_enemy,
				PATTACH_POINT_FOLLOW,
				"attach_hitloc",
				self.source_enemy:GetOrigin(), -- unknown
				true -- unknown, true
			)
			ParticleManager:SetParticleControlForward( effect_cast, 1, (caster:GetOrigin()-self.source_enemy:GetOrigin()):Normalized() )
			ParticleManager:ReleaseParticleIndex( effect_cast )
		end)
	end

	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                    source_enemy:GetAbsOrigin(),
                                    nil,
                                    self:GetSpecialValueFor("radius"),
                                    DOTA_UNIT_TARGET_TEAM_ENEMY,
                                    DOTA_UNIT_TARGET_HERO,
                                    DOTA_UNIT_TARGET_FLAG_NONE,
                                    FIND_ANY_ORDER,
                                    false)

	for _, target in pairs(enemies) do
		if not (target == source_enemy) then

			--[[hook_particle = ParticleManager:CreateParticle("particles/arcueid/medusa_hook_chain.vpcf", PATTACH_ABSORIGIN_FOLLOW, source_enemy)
			ParticleManager:SetParticleControlEnt(hook_particle, 0, source_enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", source_enemy:GetAbsOrigin(), true)
			ParticleManager:SetParticleControl(hook_particle, 3, source_enemy:GetAbsOrigin() + Vector(0, 0, 96))
			ParticleManager:SetParticleControl(hook_particle, 8, Vector(2, 0, 0))]]
			hook_particle = ParticleManager:CreateParticle("particles/arcueid/arcueid_beam_attempt.vpcf", PATTACH_ABSORIGIN_FOLLOW, source_enemy)
			ParticleManager:SetParticleControlEnt(hook_particle, 0, source_enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", source_enemy:GetAbsOrigin(), true)
			ParticleManager:SetParticleControl(hook_particle, 1, source_enemy:GetAbsOrigin() + Vector(0, 0, 96))

			local projectile = {
			    Target = target,
			 
			    Ability = ability,
			    EffectName = nil,
			    iMoveSpeed = ability:GetSpecialValueFor("speed"),
			    vSpawnOrigin = source_enemy:GetAbsOrigin(),
			    bDodgeable = false,
				Source = source_enemy,  
				bDeleteOnHit = false,
				bReplaceExisting = false,
			    flExpireTime = GameRules:GetGameTime() + 10,
			    ExtraData = {
					proj_id = target:entindex(),
					part_id = hook_particle
				}
			}

			local proj = ProjectileManager:CreateTrackingProjectile(projectile)

			self.AttackedTargets[target:entindex()] = hook_particle
		end
	end
end

function arcueid_melty:OnProjectileThink_ExtraData(vLocation, hTable)
	if not IsServer() then return end

	for a,b in pairs(self.AttackedTargets) do
		local enemy = EntIndexToHScript(a)
		local hook_particle = b

		if EntIndexToHScript(hTable.proj_id) == enemy then
			ParticleManager:SetParticleControl(hook_particle, 1, vLocation)
			--ParticleManager:SetParticleControl(hook_particle, 3, vLocation)
		end
	end
end

function arcueid_melty:OnProjectileHit_ExtraData(hTarget, vLocation, hTable)
	ParticleManager:DestroyParticle(hTable.part_id, false)
	ParticleManager:ReleaseParticleIndex(hTable.part_id)

    if IsNotNull(hTarget) then
        local hCaster       = self:GetCaster()
        local iCasterTeam   = hCaster:GetTeamNumber()

        for a,b in pairs(self.AttackedTargets) do
			enemy = EntIndexToHScript(a)
			hook_particle = b

			if (hTarget == enemy) then
				EmitSoundOn("arcueid_hit", enemy)
				EmitSoundOn("Hero_PhantomAssassin.CoupDeGrace", enemy)
				DoDamage(hCaster, hTarget, self:GetSpecialValueFor("target_damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)

				local or_tar = hTarget:GetAbsOrigin()
				local or_en = self.source_enemy:GetAbsOrigin()

				local distance = (or_tar - or_en):Length2D()

				local knockback = { should_stun = 1,
	                                knockback_duration = 0.3,
	                                duration = 0.3,
	                                knockback_distance = -distance*4/5,
	                                knockback_height = 100 or 0,
	                                center_x = or_en.x,
	                                center_y = or_en.y,
	                                center_z = or_en.z }

	            enemy:AddNewModifier(hCaster, self, "modifier_knockback", knockback)

	            if self.source_enemy:IsAlive() then
	            	EmitSoundOn("Hero_PhantomAssassin.CoupDeGrace", self.source_enemy)
		            DoDamage(hCaster, self.source_enemy, self:GetSpecialValueFor("enemy_damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)

		            local knockback2 = { should_stun = 1,
		                                knockback_duration = 0.3,
		                                duration = 0.3,
		                                knockback_distance = -distance/10,
		                                knockback_height = 100 or 0,
		                                center_x = or_tar.x,
		                                center_y = or_tar.y,
		                                center_z = or_tar.z }

		            self.source_enemy:AddNewModifier(hCaster, self, "modifier_knockback", knockback2)
		        end

		        local effect_cast = ParticleManager:CreateParticle( "particles/ryougi/ryougi_crit_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy )
				ParticleManager:SetParticleControlEnt(
					effect_cast,
					0,
					enemy,
					PATTACH_POINT_FOLLOW,
					"attach_hitloc",
					enemy:GetOrigin(), -- unknown
					true -- unknown, true
				)
				ParticleManager:SetParticleControlForward( effect_cast, 1, (self.source_enemy:GetOrigin()-enemy:GetOrigin()):Normalized() )
				ParticleManager:ReleaseParticleIndex( effect_cast )
			end
		end

    	return true
    end
end

modifier_arcueid_melty = class({})

function modifier_arcueid_melty:RemoveOnDeath() return false end

function modifier_arcueid_melty:DeclareFunctions()
	return {  MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE  }
end

function modifier_arcueid_melty:GetModifierMoveSpeedBonus_Percentage()
	return -60
end

if IsServer() then 
	function modifier_arcueid_melty:OnCreated(args)
		self.circle_particle = ParticleManager:CreateParticle("particles/arcueid/chain_model_circle_enemy.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl( self.circle_particle, 0, self:GetParent():GetAbsOrigin())

		self.parttable    = {}
		self.parttable2    = {}
		self.randtable    = {}
		self.randomtable    = {}
		self.time_elapsed = 0
		self.part_count = 0
		for i = 1,10 do
			Timers:CreateTimer(FrameTime()*3*i, function()
				if not self:GetParent():IsAlive() then return end
				self.part_count = self.part_count + 1
				local origin = self:GetParent():GetAbsOrigin()
				local random = RandomVector(60)
				local random2 = RandomVector(300)
				local rand = math.random(0, 150)
				if math.random(1, 2) == 2 then
					rand = -1*rand
				end
				local Particle = ParticleManager:CreateParticle("particles/arcueid/arcueid_beam_attempt.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
				ParticleManager:SetParticleControl( Particle, 1, self:GetParent():GetAbsOrigin() + random2 + Vector(0, 0, 150 + rand))
				ParticleManager:SetParticleControl( Particle, 0, self:GetParent():GetAbsOrigin() + random + Vector(0, 0, 100))
				local Particle2 = ParticleManager:CreateParticle("particles/arcueid/arcueid_beam_attempt.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
				ParticleManager:SetParticleControl( Particle2, 0, self:GetParent():GetAbsOrigin() - random2 + Vector(0, 0, 150 - rand))
				ParticleManager:SetParticleControl( Particle2, 1, self:GetParent():GetAbsOrigin() + random + Vector(0, 0, 100))
				self.parttable[i] = Particle
				self.parttable2[i] = Particle2
				self.randomtable[i] = random
				self.randtable[i] = rand
				Timers:CreateTimer(0.05, function()
					if self:GetParent():IsAlive() then
						EmitSoundOn("arcueid_hit", self:GetParent())
						DoDamage(self:GetCaster(), self:GetParent(), self:GetAbility():GetSpecialValueFor("chain_damage"), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
						self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_stunned", {duration = FrameTime()})
					end
				end)
			end)
		end
		--[[self.Particle = ParticleManager:CreateParticle( "particles/arcueid/enkidu.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControlEnt( self.Particle, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true )
		ParticleManager:SetParticleControl( self.Particle, 1, self:GetParent():GetAbsOrigin() )]]

		self:StartIntervalThink(FrameTime())
	end

	function modifier_arcueid_melty:OnDestroy()
		ParticleManager:DestroyParticle( self.circle_particle, false )
		ParticleManager:ReleaseParticleIndex( self.circle_particle )
		for a,b in pairs(self.parttable) do
			ParticleManager:DestroyParticle( b, false )
			ParticleManager:ReleaseParticleIndex( b )
		end
		for a,b in pairs(self.parttable2) do
			ParticleManager:DestroyParticle( b, false )
			ParticleManager:ReleaseParticleIndex( b )
		end
	end

	function modifier_arcueid_melty:OnIntervalThink()
		self.time_elapsed = self.time_elapsed + FrameTime()
		for i = 1,self.part_count do
			ParticleManager:SetParticleControl( self.parttable[i], 0, self:GetParent():GetAbsOrigin() + self.randomtable[i] + Vector(0, 0, 100))
			ParticleManager:SetParticleControl( self.parttable2[i], 1, self:GetParent():GetAbsOrigin() + self.randomtable[i] + Vector(0, 0, 100))
		end
		if self.time_elapsed >= 1.4 and not self.triggered then
			self.triggered = true
			self:GetAbility():ChainHunt(self:GetParent())
		end
	end
end

modifier_arcueid_melty_cd = class({})

function modifier_arcueid_melty_cd:GetTexture()
	return "custom/arcueid/arcueid_melty_2"
end

function modifier_arcueid_melty_cd:IsHidden()
	return false 
end

function modifier_arcueid_melty_cd:RemoveOnDeath()
	return false
end

function modifier_arcueid_melty_cd:IsDebuff()
	return true 
end

function modifier_arcueid_melty_cd:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end