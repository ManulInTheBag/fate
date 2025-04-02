iskander_trap = class({})

LinkLuaModifier("modifier_iskandar_trap", "abilities/iskandar/iskander_trap", LUA_MODIFIER_MOTION_NONE)

 

 

function iskander_trap:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local debuff_duration = self:GetSpecialValueFor("debuff_duration")
	local trapDuration = 0
	caster:EmitSound("sanya_trap")
	local trap = CreateUnitByName("sanya_trap", targetPoint, true, nil, nil, caster:GetTeamNumber())
	Timers:CreateTimer(1.0, function()
		LevelAllAbility(trap)
		trap:AddNewModifier(caster, self, "modifier_iskandar_trap", { Duration = self:GetSpecialValueFor("duration"),
																			Radius = self:GetSpecialValueFor("radius"),
																			Damage = self:GetSpecialValueFor("damage"),
																			DebuffDuration = debuff_duration })
		return
	end)


end


modifier_iskandar_trap = class({})

if IsServer() then
	function modifier_iskandar_trap:OnCreated(args)
		self.Radius = args.Radius
		self.Damage = args.Damage
		self.StunDuration = args.DebuffDuration

		self:StartIntervalThink(0.25)
	end

	function modifier_iskandar_trap:OnIntervalThink()
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local targets = FindUnitsInRadius(caster:GetTeam(), parent:GetAbsOrigin(), nil, self.Radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST  , false)
		local aotkAbility = caster:FindAbilityByName("iskander_ionioi")

		if #targets > 0 then
			caster:EmitSound("sanya_trap_prock")
			DoDamage(caster, targets[1], self.Damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
			targets[1]:AddNewModifier(caster, self:GetAbility(), "modifier_silence", { Duration = self.StunDuration })
			targets[1]:AddNewModifier(caster, self:GetAbility(), "modifier_rooted", { Duration = self.StunDuration })
			local PI = ParticleManager:CreateParticle("particles/custom/atalanta/entangle_better/pair_tree.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
			ParticleManager:SetParticleControlEnt(PI, 0, targets[1], PATTACH_ABSORIGIN_FOLLOW, nil, targets[1]:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(PI, 1, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), true)
			ParticleManager:SetParticleControl(PI, 2, Vector(self.StunDuration,0,0))
			ParticleManager:ReleaseParticleIndex(PI)
			for i=0,5 do
				Timers:CreateTimer(i*0.1, function()
					local soldier_pos = PointOnCircle(GetGroundPosition(targets[1]:GetAbsOrigin(), targets[1]), self.Radius-50, i * 45)
					local soldier = CreateUnitByName("iskander_infantry", soldier_pos, true, nil, nil, caster:GetTeamNumber())
					soldier:SetOwner(caster)
					soldier:AddNewModifier(caster, nil, "modifier_kill", {duration = self.StunDuration + 1})
					soldier:AddNewModifier(caster, self, "modifier_iskander_units_bonus_dmg", {duration = self.StunDuration + 1, dmg = aotkAbility:GetSpecialValueFor("infantry_bonus_damage")})
					soldier:EmitSound("Hero_LegionCommander.Overwhelming.Location")
					if i==0 then
						local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, soldier)
						ParticleManager:SetParticleControl(particle, 3, parent:GetAbsOrigin())
						Timers:CreateTimer( 2.0, function()
							ParticleManager:DestroyParticle( particle, false )
							ParticleManager:ReleaseParticleIndex( particle )
						end)
					end 
				end)
			end


			self:Destroy()
		end
	end

	function modifier_iskandar_trap:OnDestroy()
		local parent = self:GetParent()
		parent:ForceKill(true)
	end
end

function modifier_iskandar_trap:RemoveOnDeath()
	return true 
end

function modifier_iskandar_trap:IsHidden()
	return true 
end