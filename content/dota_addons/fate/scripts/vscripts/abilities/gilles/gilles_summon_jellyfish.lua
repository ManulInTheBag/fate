gilles_summon_jellyfish = class({})
modifier_jellyfish_maker = class({})
gilles_jellyfish_passive = class({})
modifier_gilles_jellyfish_trigger = class({})
modifier_gilles_jellyfish_curse = class({})
modifier_gilles_jellyfish_slow = class({})

LinkLuaModifier("modifier_gilles_jellyfish_curse", "abilities/gilles/gilles_summon_jellyfish", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilles_jellyfish_trigger", "abilities/gilles/gilles_summon_jellyfish", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_gilles_jellyfish_slow", "abilities/gilles/gilles_summon_jellyfish", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jellyfish_maker", "abilities/gilles/gilles_summon_jellyfish", LUA_MODIFIER_MOTION_NONE)

function gilles_summon_jellyfish:GetManaCost(iLevel)
	return (self:GetCaster():GetMaxMana() * self:GetSpecialValueFor("mana_cost") / 100)
end

function gilles_summon_jellyfish:IsHiddenAbilityCastable()
	return true
end

function gilles_summon_jellyfish:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function gilles_summon_jellyfish:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()
	local number = self:GetSpecialValueFor("summon_count")
	local summon_dur = 10

	if caster:HasModifier("modifier_demonic_horde_attribute") then
		number = 6
		summon_dur = 15
	end
	
	local thinker = CreateModifierThinker(caster, self, "modifier_jellyfish_maker", { AOE = self:GetAOERadius(),
																					  SummonDuration = summon_dur,
																					  Duration = number * 0.11 }, 
		targetPoint, caster:GetTeamNumber(), false)
end

if IsServer() then 
	function modifier_jellyfish_maker:OnCreated(args)
		self.SummonDuration = args.SummonDuration
	 	self:StartIntervalThink(0.1)
	end

	function modifier_jellyfish_maker:OnIntervalThink()
		local spawn_location = RandomPointInCircle(self:GetParent():GetAbsOrigin(), self:GetAbility():GetAOERadius())
		local caster = self:GetCaster()

		EmitSoundOnLocationWithCaster(spawn_location, "Hero_Necrolyte.Attack", caster)

		local jellyfish = CreateUnitByName("gille_oceanic_demon", spawn_location, true, caster, caster, caster:GetTeamNumber())
		jellyfish:SetControllableByPlayer(caster:GetPlayerID(), true)
		jellyfish:SetOwner(caster)
		jellyfish.Caster = caster
		jellyfish.Ability = self:GetAbility()
		jellyfish:AddNewModifier(caster, nil, "modifier_kill", {duration = self.SummonDuration})

		local particleIndex = ParticleManager:CreateParticle("particles/custom/gilles/gilles_summon_jellyfish.vpcf", PATTACH_CUSTOMORIGIN, jellyfish)
	 	ParticleManager:SetParticleControl(particleIndex, 1, jellyfish:GetAbsOrigin()) 

		Timers:CreateTimer( 1.5, function()
	        ParticleManager:DestroyParticle( particleIndex, true )
	        ParticleManager:ReleaseParticleIndex( particleIndex )
	        return nil
	    end)
	end
end

-- To attach the passive buff
function gilles_jellyfish_passive:GetIntrinsicModifierName()
	return "modifier_gilles_jellyfish_trigger"
end

-- To allow the game to recognize the trigger
function modifier_gilles_jellyfish_trigger:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_START }
end

if IsServer() then 
	function modifier_gilles_jellyfish_trigger:OnAttackStart(args)
		if args.attacker ~= self:GetParent() then return end

		local hCaster = self:GetParent().Caster
		local hAbility = self:GetParent().Ability
		local targets = FindUnitsInRadius(hCaster:GetTeam(), self:GetParent():GetAbsOrigin(), nil, hAbility:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		
		for _,v in pairs(targets) do
			if not v:IsMagicImmune() then
				v:AddNewModifier(hCaster, hAbility, "modifier_gilles_jellyfish_curse", { Damage = hAbility:GetSpecialValueFor("damage"),
																						 Duration = hAbility:GetSpecialValueFor("duration")})

				if not IsImmuneToSlow(v) then
					v:AddNewModifier(hCaster, hAbility, "modifier_gilles_jellyfish_slow", {Duration = hAbility:GetSpecialValueFor("duration")})
				end
			end
		end

		EmitSoundOnLocationWithCaster(self:GetParent():GetAbsOrigin(), "Hero_Necrolyte.ProjectileImpact", hCaster)

		local particleIndex = ParticleManager:CreateParticle("particles/custom/gilles/gilles_jellyfish_explode_blood.vpcf", PATTACH_CUSTOMORIGIN, nil)
	 	ParticleManager:SetParticleControl(particleIndex, 0, self:GetParent():GetAbsOrigin()) 

		Timers:CreateTimer( 1.5, function()
	        ParticleManager:DestroyParticle( particleIndex, true )
	        ParticleManager:ReleaseParticleIndex( particleIndex )
	        return nil
	    end)

		self:GetParent():ForceKill(true)
	end
end

function modifier_gilles_jellyfish_trigger:IsHidden() 
	return true 
end

--Actual debuff code
function modifier_gilles_jellyfish_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_gilles_jellyfish_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_pct")
end

function modifier_gilles_jellyfish_slow:IsHidden()
	return true
end

if IsServer() then
	function modifier_gilles_jellyfish_curse:OnCreated(args)
		self:SetStackCount(1)
		self.Damage = args.Damage * 0.4 / self:GetDuration()
		self:StartIntervalThink(0.4)
	end

	function modifier_gilles_jellyfish_curse:OnRefresh(args)
		self:SetStackCount((self:GetStackCount() or 1) + 1)
		self.Damage = args.Damage * 0.4 / self:GetDuration()
	end

	function modifier_gilles_jellyfish_curse:OnIntervalThink()
		DoDamage(self:GetCaster(), self:GetParent(), self.Damage * self:GetStackCount(), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end
end

function modifier_gilles_jellyfish_curse:IsDebuff()
	return true
end