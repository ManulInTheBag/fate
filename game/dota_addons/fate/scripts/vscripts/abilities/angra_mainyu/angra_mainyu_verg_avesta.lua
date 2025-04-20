angra_mainyu_verg_avesta = class({})

LinkLuaModifier("angra_mainyu_verg_avesta_dot", "abilities/angra_mainyu/angra_mainyu_verg_avesta", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("angra_mainyu_verg_avesta_slow", "abilities/angra_mainyu/angra_mainyu_verg_avesta", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("angra_mainyu_verg_avesta_count", "abilities/angra_mainyu/angra_mainyu_verg_avesta", LUA_MODIFIER_MOTION_NONE)

function angra_mainyu_verg_avesta:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

-- function angra_mainyu_verg_avesta:GetManaCost()
-- 	local caster = self:GetCaster()
-- 	if caster:GetMana() >= 800 then
-- 		self.spendHealth = 0
-- 		return 800
-- 	else
-- 		self.spendHealth = 800 - caster:GetMana()
-- 		return caster:GetMana()
-- 	end
-- end

function angra_mainyu_verg_avesta:GetHealthCost()
	return self:GetCaster():GetMaxHealth()*0.1 --self:GetCaster():HasModifier("angra_mainyu_verg_avesta_count") and (self:GetCaster():GetModifierStackCount("angra_mainyu_verg_avesta_count", self:GetCaster())+1) * 50 or
	-- if caster:GetMana() >= 800 then 
	-- 	return self:GetCaster():GetMaxHealth()*0.1 --self:GetCaster():HasModifier("angra_mainyu_verg_avesta_count") and (self:GetCaster():GetModifierStackCount("angra_mainyu_verg_avesta_count", self:GetCaster())+1) * 50 or
	-- else
	-- 	return self:GetCaster():GetMaxHealth()*0.1 + (self.spendHealth and self.spendHealth or 0)
	-- end
end

function angra_mainyu_verg_avesta:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local radius = self:GetAOERadius()
	local delay = self:GetSpecialValueFor("delay")
	self.spendHealth = 0
	--caster:AddNewModifier(caster, self, "angra_mainyu_verg_avesta_count", { Duration = 55 })

	Timers:CreateTimer(delay, function()
		caster:EmitSound("Avenger.Berg")
	end)
	caster:EmitSound("Avenger.BergShout")

	local verg_particle = ParticleManager:CreateParticle("particles/custom/avenger/avenger_verg_avesta.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(verg_particle, 0, caster:GetAbsOrigin())

	Timers:CreateTimer(delay, function()
		ParticleManager:DestroyParticle( verg_particle, false )
		ParticleManager:ReleaseParticleIndex( verg_particle )
		return nil
	end)

	damage = self:GetSpecialValueFor("damage") * (((1-caster:GetHealth()/caster:GetMaxHealth()) * self:GetSpecialValueFor("lost_health_amp")/100) + 1) + (caster.IsDIAcquired and caster:GetMaxHealth() * 0.1 or 0)

	local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER , false)
	for k,v in pairs(targets) do
		if v:GetName() ~= "npc_dota_ward_base" then
			DoDamage(caster, v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
			if not v:IsAlive() and caster.IsDIAcquired and v:IsHero() then
				self:GetCaster():FindAbilityByName("angra_puddle"):DeathPuddle(v:GetAbsOrigin())
			end

			local verg_particle_hero = ParticleManager:CreateParticle("particles/custom/avenger/avenger_verg_avesta.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, v)
			ParticleManager:SetParticleControl(verg_particle_hero, 0, v:GetAbsOrigin())

			Timers:CreateTimer(delay, function()
				ParticleManager:DestroyParticle( verg_particle_hero, false )
				ParticleManager:ReleaseParticleIndex( verg_particle_hero )
				return nil
			end)
			Timers:CreateTimer(delay, function()
				if v and v:IsAlive() then
					v:AddNewModifier(caster, self , "angra_mainyu_verg_avesta_dot",{duration = 1.1, damage = damage})
			        local particle = ParticleManager:CreateParticle("particles/econ/items/sniper/sniper_charlie/sniper_assassinate_impact_blood_charlie.vpcf", PATTACH_CUSTOMORIGIN, nil)
			        ParticleManager:SetParticleControl(particle, 1, v:GetAbsOrigin())
			    end
    	 	end)

		end
	end
	
end

angra_mainyu_verg_avesta_dot = class({})

function angra_mainyu_verg_avesta_dot:GetEffectName()
    return "particles/zlodemon/avesta_burn.vpcf"
end

function angra_mainyu_verg_avesta_dot:IsHidden()
    return false
end
function angra_mainyu_verg_avesta_dot:IsDebuff()
    return true
end
function angra_mainyu_verg_avesta_dot:RemoveOnDeath()
    return false
end
function angra_mainyu_verg_avesta_dot:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end
function angra_mainyu_verg_avesta_dot:GetAttributes()                                                                  return MODIFIER_ATTRIBUTE_MULTIPLE end

function angra_mainyu_verg_avesta_dot:IsDebuff() return true end
if IsServer() then
	function angra_mainyu_verg_avesta_dot:OnCreated(args)

		self.damage = args.damage
		self.caster = self:GetCaster()
		self.target = self:GetParent()
		self.abil = self:GetAbility()
		self.spawnedPool = false
		self.target:EmitSound("Hero_WitchDoctor.Maledict_Tick")
		self.bDoSlow = self.caster.IsDIAcquired
		DoDamage(self.caster, self.target, self.damage/3, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self.abil, true)
		if not self.target:IsAlive() and self.caster.IsDIAcquired and self.target:IsHero() and not self.spawnedPool then
			self.caster:FindAbilityByName("angra_puddle"):DeathPuddle(self.target:GetAbsOrigin())
			self.spawnedPool = true
		end

		if self.bDoSlow then
			self.target:AddNewModifier(self.caster, self.abil , "angra_mainyu_verg_avesta_slow",{duration = 0.5})
		end
		self:StartIntervalThink(0.5)
	end
	function angra_mainyu_verg_avesta_dot:OnIntervalThink()
		if(not IsServer() ) then return end
		self.target:EmitSound("Hero_WitchDoctor.Maledict_Tick")

		DoDamage(self.caster, self.target, self.damage/3, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self.abil, true)
		if not self.target:IsAlive() and self.caster.IsDIAcquired and self.target:IsHero() and not self.spawnedPool then
			self.caster:FindAbilityByName("angra_puddle"):DeathPuddle(self.target:GetAbsOrigin())
			self.spawnedPool = true

		end
		if self.bDoSlow then
			self.target:AddNewModifier(self.caster, self.abil , "angra_mainyu_verg_avesta_slow",{duration = 0.5})
		end
	end
end


angra_mainyu_verg_avesta_slow = class({})

function angra_mainyu_verg_avesta_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
 
    return funcs
end

function angra_mainyu_verg_avesta_slow:GetModifierMoveSpeedBonus_Percentage() 
    return -60
end
------------------------------------------------------------------------------

function angra_mainyu_verg_avesta_slow:IsDebuff()
    return true
end

-----------------------------------------------------------------------------------

function angra_mainyu_verg_avesta_slow:RemoveOnDeath()
    return true
end

-----------------------------------------------------------------------------------

angra_mainyu_verg_avesta_count = class({})

if IsServer() then 
	function angra_mainyu_verg_avesta_count:OnCreated(args)
		self:SetStackCount(args.Stacks or 1)
	end

	function angra_mainyu_verg_avesta_count:OnRefresh(args)
		self:SetStackCount(math.min(self:GetStackCount() + 1, 5))
	end
end

function angra_mainyu_verg_avesta_count:IsHidden()
	return false
end

function angra_mainyu_verg_avesta_count:RemoveOnDeath()
	return true
end