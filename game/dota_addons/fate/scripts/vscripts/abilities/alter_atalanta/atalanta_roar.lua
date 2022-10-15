LinkLuaModifier("modifier_roar_slow", "abilities/alter_atalanta/atalanta_roar", LUA_MODIFIER_MOTION_NONE)

atalanta_roar = class({})

function atalanta_roar:OnAbilityPhaseStart()
    self:GetCaster():EmitSound("atalanta_detonate")
    return true
end

function atalanta_roar:OnAbilityPhaseInterrupted()
    self:GetCaster():StopSound("atalanta_detonate")
end

function atalanta_roar:OnSpellStart()
	local caster = self:GetCaster()
	local startpoint = caster:GetAbsOrigin() + caster:GetForwardVector()*10
	local endpoint = caster:GetAbsOrigin() + caster:GetForwardVector()*self:GetSpecialValueFor("distance")
	local width = self:GetSpecialValueFor("width")

	local roar_fx = ParticleManager:CreateParticle("particles/atalanta/beastmaster_primal_roar.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl( roar_fx, 0, startpoint)
	ParticleManager:SetParticleControl( roar_fx, 1, endpoint)

	Timers:CreateTimer(2, function()
		ParticleManager:DestroyParticle(roar_fx, false)
		ParticleManager:ReleaseParticleIndex(roar_fx)
	end)

	local enemies = FindUnitsInLine(caster:GetTeam(), startpoint, endpoint, nil, width, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0)
	local count = (caster.TornadoAcquired and 5 or 0) + (caster.CursedMoonAcquired and #enemies or 0)
	local stacks = self:GetSpecialValueFor("base_stacks")
	local damage = self:GetSpecialValueFor("base_damage") + #enemies*(caster.EvolutionAcquired and self:GetSpecialValueFor("echo_damage") or 0)
	for _,v in ipairs(enemies) do
		 local knockback = { should_stun = false,
                        knockback_duration = 0.2,
                        duration = 0.2,
                        knockback_distance = -(150 + (caster.TornadoAcquired and (v:HasModifier("modifier_atalanta_curse") and v:FindModifierByName("modifier_atalanta_curse"):GetStackCount() or 0) or 0)),
                        knockback_height = 0,
                        center_x = caster:GetAbsOrigin().x,
                        center_y = caster:GetAbsOrigin().y,
                        center_z = caster:GetAbsOrigin().z }

		v:AddNewModifier(caster, self, "modifier_knockback", knockback)

		v:AddNewModifier(caster, self, "modifier_roar_slow", {duration = self:GetSpecialValueFor("duration")})

		--giveUnitDataDrivenModifier(caster, v, "locked", self:GetSpecialValueFor("duration_locked"))

		DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
		for i = 1,(count+stacks) do
			caster:FindAbilityByName("atalanta_curse"):Curse(v)
		end			
	end
end

modifier_roar_slow = class({})

function modifier_roar_slow:IsDebuff() return true end
function modifier_roar_slow:IsHidden() return false end
function modifier_roar_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end
function modifier_roar_slow:GetModifierMoveSpeedBonus_Percentage()
	return -(self:GetAbility():GetSpecialValueFor("ms_slow") + (self:GetCaster().CursedMoonAcquired and (self:GetParent():HasModifier("modifier_atalanta_curse") and self:GetParent():FindModifierByName("modifier_atalanta_curse"):GetStackCount() or 0) or 0))
end
function modifier_roar_slow:GetModifierAttackSpeedBonus_Constant()
	return -(self:GetAbility():GetSpecialValueFor("as_slow") + (self:GetCaster().CursedMoonAcquired and (self:GetParent():HasModifier("modifier_atalanta_curse") and self:GetParent():FindModifierByName("modifier_atalanta_curse"):GetStackCount() or 0) or 0))
end
function modifier_roar_slow:OnCreated()
	local particle_slow_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_sniper/sniper_headshot_slow.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(particle_slow_fx, 0, self:GetParent():GetAbsOrigin() + Vector(0, 0, 0))
	self:AddParticle(particle_slow_fx, false, false, -1, false, true)
end