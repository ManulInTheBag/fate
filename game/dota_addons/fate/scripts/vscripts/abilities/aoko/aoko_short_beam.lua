LinkLuaModifier("modifier_aoko_short_beam_debuff", "abilities/aoko/aoko_short_beam", LUA_MODIFIER_MOTION_NONE)

aoko_short_beam = class({})

function aoko_short_beam:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("aoko_lazers"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("aoko_lazers"):SetLevel(self:GetLevel())
    end
end

function aoko_short_beam:GetManaCost()
	local caster = self:GetCaster()
	local ability = caster:FindAbilityByName("aoko_circuits")

	local stacks = ability:GetStacks()

	local base_manacost = self:GetSpecialValueFor("mana_cost")
	local increment = ability:GetSpecialValueFor("manacost_increase_per_stack")

	local result = math.min(base_manacost*(1 + stacks*increment/100), caster:GetMaxMana())

	return result
end

function aoko_short_beam:OnSpellStart()
	local caster = self:GetCaster()
	local target_point = self:GetCursorPosition()
	local range = self:GetSpecialValueFor("range")
	local damage = self:GetSpecialValueFor("damage")
	local amp = self:GetSpecialValueFor("circuit_amplify_per_stack")

	if caster.MagicBulletLoadAcquired then
		damage = damage + self:GetSpecialValueFor("attribute_int_scaling")*caster:GetIntellect()
	end

	local circuits = caster:FindAbilityByName("aoko_circuits")
	local stacks = self:GetSpecialValueFor("stack_gain")

	--damage = damage * (1 + circuits:GetStacks()*amp/100)

	local pepega = false

	local or1 = GetGroundPosition((caster:GetAbsOrigin() + caster:GetForwardVector()*range), caster)
	local or2 = caster:GetAbsOrigin()
	local right = caster:GetRightVector()

	local height_att = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_beamu")).z - caster:GetAbsOrigin().z

	local height = or1.z - or2.z + height_att

	local enemieshit = {}

	caster:EmitSound("aoko_shotgun_"..math.random(1, 3))

	for i = 1, 3 do
		local part1 = caster:GetAbsOrigin() + caster:GetForwardVector()*range + Vector(0, 0, height) + 125*right*(2-i)
		local part9 = caster:GetAbsOrigin() + Vector(0, 0, height_att) + caster:GetForwardVector()*100 + 125*right*(2-i)

		EmitSoundOn("edmon_short_beam", caster)
		local particle = ParticleManager:CreateParticle("particles/aoko/aoko_beam_laser_short.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 0, part9)
		ParticleManager:SetParticleControl(particle, 1, part1)
		ParticleManager:SetParticleControl(particle, 9, part9)
		--ParticleManager:SetParticleControlEnt(particle,	1, args.target,	PATTACH_POINT, "attach_hitloc", args.target:GetOrigin(), true)
		--ParticleManager:SetParticleControlEnt(particle,	9, self.parent,	PATTACH_POINT, "attach_attack"..self.seq, self.parent:GetOrigin(), true)
		ParticleManager:ReleaseParticleIndex(particle)

		local enemies = FindUnitsInLine(
									        caster:GetTeamNumber(),
									        part1,
									        caster:GetAbsOrigin(),
									        nil,
									        225,
											DOTA_UNIT_TARGET_TEAM_ENEMY,
											DOTA_UNIT_TARGET_ALL,
											0
		   								)

		for _, enemy in pairs(enemies) do
			if not enemieshit[enemy:entindex()] then
				enemieshit[enemy:entindex()] = true

				if caster.MagicBulletLoadAcquired then
					enemy:AddNewModifier(caster, self, "modifier_aoko_short_beam_debuff", {duration = self:GetSpecialValueFor("attribute_debuff_duration")})
				end

				DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)

				EmitSoundOn("edmon_beam_hit", enemy)

				if not pepega then
					circuits:GainStacks(stacks)
					pepega = true
				end
			end
		end

		local spherecheck = FindUnitsInLine(
									        caster:GetTeamNumber(),
									        part1,
									        caster:GetAbsOrigin(),
									        nil,
									        225,
											DOTA_UNIT_TARGET_TEAM_FRIENDLY,
											DOTA_UNIT_TARGET_ALL,
											DOTA_UNIT_TARGET_FLAG_INVULNERABLE
		   								)

		for _, check in pairs(spherecheck) do
			if check:HasModifier("modifier_aoko_sphere_dummy") then
				check:FindModifierByName("modifier_aoko_sphere_dummy"):ShortExplode()
			end
		end
	end
end

modifier_aoko_short_beam_debuff = class({})

function modifier_aoko_short_beam_debuff:IsHidden()	return false end
function modifier_aoko_short_beam_debuff:IsDebuff()	return true end
function modifier_aoko_short_beam_debuff:DeclareFunctions()
    local tFunc =   {
                        MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
                    }
    return tFunc
end
function modifier_aoko_short_beam_debuff:GetModifierTotalDamageOutgoing_Percentage(keys)
    if bit.band(keys.damage_type or DAMAGE_TYPE_NONE, DAMAGE_TYPE_MAGICAL) ~= 0 then
        return -1*self:GetAbility():GetSpecialValueFor("attribute_magical_damage_reduction")
    end
end