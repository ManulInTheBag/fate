LinkLuaModifier("modifier_atalanta_curse", "abilities/alter_atalanta/atalanta_curse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_atalanta_curse_passive", "abilities/alter_atalanta/atalanta_curse", LUA_MODIFIER_MOTION_NONE)

atalanta_curse = class({})

function atalanta_curse:GetIntrinsicModifierName()
	return "modifier_atalanta_curse_passive"
end

function atalanta_curse:OnSpellStart()
	local caster = self:GetCaster()
	EmitGlobalSound("atalanta_skia_channel")
	Timers:CreateTimer(5.0, function()
		local units = FindUnitsInRadius(caster:GetTeam(),
                                        caster:GetAbsOrigin(), 
                                        nil, 
                                        99999, 
                                        DOTA_UNIT_TARGET_TEAM_ENEMY, 
                                        DOTA_UNIT_TARGET_ALL, 
                                        DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 
                                        0, 
                                        false)
		for _,unit in pairs(units) do
			if not unit or unit:IsNull() or not unit:IsAlive() then return end
			unit:RemoveModifierByName("modifier_atalanta_curse")
        end
    end)
    if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then		
			if caster:FindAbilityByName("atalanta_jump"):IsCooldownReady() 
				and caster:FindAbilityByName("atalanta_skia"):IsCooldownReady()  
		    	and caster:GetAbilityByIndex(2):GetName() == "atalanta_jump" then
				caster:SwapAbilities("atalanta_jump", "atalanta_skia", false, true)
				Timers:CreateTimer(4, function()
					caster:SwapAbilities("atalanta_jump", "atalanta_skia", true, false)
				end)
			end
		end
end

function atalanta_curse:Curse(target)
	local caster = self:GetCaster()
	local stacks = 0

	if not target or not target:IsAlive() or target:IsNull() then return end

	if target:HasModifier("modifier_atalanta_curse") then
		stacks = target:FindModifierByName("modifier_atalanta_curse"):GetStackCount()
	end

	target:AddNewModifier(caster, self, "modifier_atalanta_curse", {duration = self:GetSpecialValueFor("duration")})
	target:FindModifierByName("modifier_atalanta_curse"):SetStackCount(stacks + 1)
end

modifier_atalanta_curse = class({})

function modifier_atalanta_curse:IsHidden() return false end
function modifier_atalanta_curse:IsDebuff() return true end
function modifier_atalanta_curse:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
			MODIFIER_PROPERTY_PROVIDES_FOW_POSITION}
end

function modifier_atalanta_curse:GetTexture()
    return "custom/alter_atalanta/atalanta_curse_rofl"
end

function modifier_atalanta_curse:OnCreated()
	self.parent = self:GetParent()
	self.particle_4stacks = "particles/units/heroes/hero_shadow_demon/shadow_demon_shadow_poison_4stack.vpcf"
	if not self.particle_4stacks_fx then
        self.particle_4stacks_fx = ParticleManager:CreateParticle(self.particle_4stacks, PATTACH_ABSORIGIN_FOLLOW, self.parent)
        ParticleManager:SetParticleControl(self.particle_4stacks_fx, 0, self.parent:GetAbsOrigin())
        self:AddParticle(self.particle_4stacks_fx, true, false, -1, false, false)        
    end
end

function modifier_atalanta_curse:GetModifierProvidesFOWVision()
	return self:CanBeDetected()
end

function modifier_atalanta_curse:CanBeDetected(hHero)
    if not (self:GetCaster().VisionAcquired and self:GetCaster():IsAlive() and self:GetStackCount() >= 10) or self:GetParent():HasModifier("modifier_murderer_mist_in") then
        return 0
    end
    
    return 1
end

function modifier_atalanta_curse:GetModifierIncomingDamage_Percentage(keys)
	if keys.attacker == self:GetCaster() then
		return self:GetStackCount()*(self:GetAbility():GetSpecialValueFor("amplify_per_stack"))*2
	else
		return self:GetStackCount()*(self:GetAbility():GetSpecialValueFor("amplify_per_stack"))
	end
end

function modifier_atalanta_curse:OnDestroy()
	DoDamage(self:GetCaster(), self:GetParent(), (self:GetAbility():GetSpecialValueFor("detonate_damage") + (self:GetCaster().VisionAcquired and 5 or 0))*self:GetStackCount(), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
    local particle_kill = "particles/units/heroes/hero_shadow_demon/shadow_demon_shadow_poison_kill.vpcf"
	local particle_kill_fx = ParticleManager:CreateParticle(particle_kill, PATTACH_ABSORIGIN, self:GetParent())        
	ParticleManager:SetParticleControlEnt(particle_kill_fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle_kill_fx, 2, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)    
	ParticleManager:SetParticleControlEnt(particle_kill_fx, 3, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(1,0,0), true)
	ParticleManager:ReleaseParticleIndex(particle_kill_fx)
end

modifier_atalanta_curse_passive = class({})

function modifier_atalanta_curse_passive:IsHidden() return true end
function modifier_atalanta_curse_passive:RemoveOnDeath() return false end
function modifier_atalanta_curse_passive:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED,
			--MODIFIER_EVENT_ON_TAKEDAMAGE
		}
end

--[[function modifier_atalanta_curse_passive:OnCreated()
	Timers:CreateTimer(0.1, function()
		self.parent = self:GetParent()
		local direction = self.parent:GetForwardVector()
		self.particle_modifier = "particles/hero/shadow_demon/shadow_demon_demonic_purge.vpcf"
		self.particle_modifier_fx = ParticleManager:CreateParticle(self.particle_modifier, PATTACH_ABSORIGIN_FOLLOW, self.parent)
	    ParticleManager:SetParticleControl(self.particle_modifier_fx, 0, self.parent:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.particle_modifier_fx, 1, self.parent:GetAbsOrigin())
	    ParticleManager:SetParticleControl(self.particle_modifier_fx, 3, direction)
	    ParticleManager:SetParticleControl(self.particle_modifier_fx, 4, self.parent:GetAbsOrigin())
	    self:AddParticle(self.particle_modifier_fx, false, false, -1, false, false)
	end)
end]]

function modifier_atalanta_curse_passive:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end

	if self:GetParent().EvolutionAcquired and args.target:HasModifier("modifier_atalanta_curse") then
		self:GetParent():Heal(args.target:FindModifierByName("modifier_atalanta_curse"):GetStackCount() + 10, self:GetParent())
	end

	if self:GetParent().TornadoAcquired then
		args.target:RemoveModifierByName("modifier_knockback")
		local knockback_pepega = (40 + (args.target:HasModifier("modifier_atalanta_curse") and args.target:FindModifierByName("modifier_atalanta_curse"):GetStackCount() or 0)/2)
		 local knockback = { should_stun = false,
                        knockback_duration = 0.05,
                        duration = 0.05,
                        knockback_distance = -math.min(knockback_pepega, (args.attacker:GetAbsOrigin()-args.target:GetAbsOrigin()):Length2D()),
                        knockback_height = 0,
                        center_x = args.attacker:GetAbsOrigin().x,
                        center_y = args.attacker:GetAbsOrigin().y,
                        center_z = args.attacker:GetAbsOrigin().z }

		args.target:AddNewModifier(caster, self, "modifier_knockback", knockback)
	end

	self:GetAbility():Curse(args.target)
end

function modifier_atalanta_curse_passive:OnTakeDamage(args)
	if not self:GetParent().EvolutionAcquired then return end
	if args.attacker ~= self:GetParent() then return end
	if args.damage_type == 2 then
		self:GetParent():Heal(args.damage*0.15, self:GetParent())
	end
end