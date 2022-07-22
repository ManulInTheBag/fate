khsn_stab = class({})

LinkLuaModifier("modifier_khsn_flame1", "abilities/kinghassan/khsn_stab", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_silence", "abilities/kinghassan/khsn_stab", LUA_MODIFIER_MOTION_NONE)

function khsn_stab:OnSpellStart()
	local caster = self:GetCaster()
	local point = caster:GetAbsOrigin() + caster:GetForwardVector()*self:GetSpecialValueFor("range")
	local width = self:GetSpecialValueFor("radius")

	local enemies = FindUnitsInLine(
								        caster:GetTeamNumber(),
								        caster:GetAbsOrigin(),
								        point,
								        nil,
								        width,
										self:GetAbilityTargetTeam(),
										self:GetAbilityTargetType(),
										self:GetAbilityTargetFlags()
    								)

	for _,enemy in ipairs(enemies) do
		local damage = self:GetSpecialValueFor("damage")
		if not IsFacingUnit(enemy, caster, 90) then
			damage = damage*self:GetSpecialValueFor("backstab_multiplier")
			EmitSoundOnLocationWithCaster(enemy:GetAbsOrigin(), "Hero_SkeletonKing.Hellfire_BlastImpact", caster)

			enemy:AddNewModifier(caster, self, "modifier_khsn_silence", {duration = self:GetSpecialValueFor("silence_duration")})

			local burn_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_shadowraze.vpcf", PATTACH_ABSORIGIN, enemy)
			ParticleManager:SetParticleControl(burn_fx, 0, point)

			local flame_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_flame_kappa.vpcf", PATTACH_ABSORIGIN, enemy)
			ParticleManager:SetParticleControl(flame_fx, 0, point)
			ParticleManager:SetParticleControl(flame_fx, 1, Vector(0, 0, 1000))

			--if caster.FlameAcquired then 
				--caster:GiveMana(200)
			--end

			--enemy:AddNewModifier(caster, self, "modifier_khsn_flame1", {duration = self:GetSpecialValueFor("duration")})
		end
		giveUnitDataDrivenModifier(caster, enemy, "locked", self:GetSpecialValueFor("lock_duration"))
		
		caster:PerformAttack( enemy, true, true, true, true, false, false, false )
		DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
    end
end

modifier_khsn_silence = class({})

function modifier_khsn_silence:IsHidden() return false end
function modifier_khsn_silence:IsDebuff() return true end
function modifier_khsn_silence:IsPurgable() return false end
function modifier_khsn_silence:IsPurgeException() return false end
function modifier_khsn_silence:RemoveOnDeath() return true end

function modifier_khsn_silence:CheckState()
    local state =   { 
                        [MODIFIER_STATE_SILENCED] = true
                    }
    return state
end

modifier_khsn_flame1 = class({})

function modifier_khsn_flame1:GetTexture()
    return "custom/kinghassan/khsn_flame_attr"
end
function modifier_khsn_flame1:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    }
 
    return funcs
end

--function modifier_calydonian_hunt_sight:CheckState()
--end

function modifier_khsn_flame1:GetModifierProvidesFOWVision()
	if self:GetParent():HasModifier("modifier_murderer_mist_in") then
		return 0
	end
    return 1
end
function modifier_khsn_flame1:IsHidden() return false end
function modifier_khsn_flame1:IsDebuff() return true end
function modifier_khsn_flame1:RemoveOnDeath() return true end
--function modifier_khsn_flame1:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_khsn_flame1:OnCreated(keys)
	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.duration_pepeg = keys.duration

	if IsServer() then
		self.flame_damage_interval 	= 0.1
		self.flame_damage_second 	= self.ability:GetSpecialValueFor("damage_per_second") * self.flame_damage_interval

		local burn_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		
		self:AddParticle(burn_fx, false, false, -1, false, false)

		self:StartIntervalThink(self.flame_damage_interval)
	end
end
function modifier_khsn_flame1:OnIntervalThink()
	if IsServer() then
		self.duration_pepeg = self.duration_pepeg - self.flame_damage_interval
		DoDamage(self.caster, self.parent, self.flame_damage_second, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		if self.caster.FlameAcquired then
			--self.flame_damage_second = self.flame_damage_second + self.caster:FindAbilityByName("khsn_flame_active"):GetSpecialValueFor("damage_per_second")*self.flame_damage_interval*self.flame_damage_interval
			--self.parent:FindModifierByName("modifier_death_door").recieved_damage = self.parent:FindModifierByName("modifier_death_door").recieved_damage + self.flame_damage_second
		end
		--[[if self.caster.FlameAcquired then
			DoDamage(self.caster, self.parent, self.parent:GetMaxHealth()*0.07*self.flame_damage_interval, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		end]]
	end
end