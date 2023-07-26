LinkLuaModifier("modifier_arcueid_impulses", "abilities/arcueid/arcueid_impulses", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arcueid_combo_window", "abilities/arcueid/arcueid_impulses", LUA_MODIFIER_MOTION_NONE)

arcueid_impulses = class({})

function arcueid_impulses:GetIntrinsicModifierName()
	return "modifier_arcueid_impulses"
end

function arcueid_impulses:GetBehavior()
	if self:GetCaster():HasModifier("modifier_arcueid_world") then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AUTOCAST + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
	end
	return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
end

function arcueid_impulses:OnSpellStart()
	local caster = self:GetCaster()

	EmitGlobalSound("arcueid_combo_start")
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
	    if caster:FindAbilityByName("arcueid_melty"):IsCooldownReady() and caster:IsAlive() then	    		
	    	caster:AddNewModifier(caster, self, "modifier_arcueid_combo_window", {duration = 3})
		end
	end

	local player_table = {}
	local i = 0

	LoopOverPlayers(function(player, playerID, playerHero)
    	--print("looping through " .. playerHero:GetName())
        if playerHero:GetTeamNumber() ~= caster:GetTeamNumber() and playerHero:IsAlive() then
        	i = i+1
        	player_table[i] = playerHero
        end
    end)

    local distance = 99999
    local target = nil

    for a,b in pairs(player_table) do
    	if CanBeDetected(b) then
    		local dist = (b:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
    		if dist < distance then
    			target = b
    			distance = dist
    		end
    	end
    end

    if target then
    	MinimapEvent( caster:GetTeamNumber(), caster, target:GetAbsOrigin().x, target:GetAbsOrigin().y, DOTA_MINIMAP_EVENT_HINT_LOCATION, 2)
    end
end

function arcueid_impulses:Pepeg(target)
	local caster = self:GetCaster()
	local modifier = caster:FindModifierByName("modifier_arcueid_impulses")

	if modifier:GetStackCount() > 0 then
		if modifier:GetStackCount() < self:GetSpecialValueFor("max_stacks") then
			modifier:SetStackCount(modifier:GetStackCount() + 1)
		end
	else
		modifier:SetStackCount(1)
	end
	modifier:StartIntervalThink(10)

	if caster.RecklesnessAcquired then
		caster:PerformAttack( target, true, true, true, true, false, true, false )
	end
end
	

modifier_arcueid_impulses = class({})

function modifier_arcueid_impulses:IsHidden() return true end
function modifier_arcueid_impulses:IsDebuff() return false end
--function modifier_true_assassin_selfmod:IsPurgable() return false end
--function modifier_true_assassin_selfmod:IsPurgeException() return false end
function modifier_arcueid_impulses:RemoveOnDeath() return false end
function modifier_arcueid_impulses:GetAttributes() 
    return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_arcueid_impulses:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_arcueid_impulses:GetModifierMagicalResistanceBonus()
	return (self:GetParent():HasModifier("modifier_arcueid_world") and (1 - self:GetParent():GetHealth()/self:GetParent():GetMaxHealth())*self:GetAbility():GetSpecialValueFor("magical_resistance") or 0)
end

function modifier_arcueid_impulses:GetModifierAttackSpeedBonus_Constant()
	return (self:GetParent():HasModifier("modifier_arcueid_world") and (1 - self:GetParent():GetHealth()/self:GetParent():GetMaxHealth())*self:GetAbility():GetSpecialValueFor("attack_speed") or 0)
end

function modifier_arcueid_impulses:OnCreated()
	if IsServer() then
		self.stack_count = 0
		self.ability = self:GetAbility()
	end
end

function modifier_arcueid_impulses:OnAttackLanded(args)
	if args.attacker ~= self:GetParent() then return end

	self.parent = self:GetParent()
	local caster = self:GetCaster()
	local damage = self.ability:GetSpecialValueFor("damage") + self.ability:GetSpecialValueFor("damage_perc")*self.parent:GetMaxHealth()/100
	if IsServer() then
		if self.parent.MonstrousStrengthAcquired then 
			--[[local qCD = caster:FindAbilityByName("arcueid_what"):GetCooldownTimeRemaining()
			caster:FindAbilityByName("arcueid_what"):EndCooldown()
			if qCD > 0 then
				caster:FindAbilityByName("arcueid_what"):StartCooldown(qCD - 1)
			end

			local wCD = caster:FindAbilityByName("arcueid_shut_up"):GetCooldownTimeRemaining()
			caster:FindAbilityByName("arcueid_shut_up"):EndCooldown()
			if wCD > 0 then
				caster:FindAbilityByName("arcueid_shut_up"):StartCooldown(wCD - 1)
			end

			local eCD = caster:FindAbilityByName("arcueid_ready"):GetCooldownTimeRemaining()
			caster:FindAbilityByName("arcueid_ready"):EndCooldown()
			if eCD > 0 then
				caster:FindAbilityByName("arcueid_ready"):StartCooldown(eCD - 1)
			end

			local rCD = caster:FindAbilityByName("arcueid_you"):GetCooldownTimeRemaining()
			caster:FindAbilityByName("arcueid_you"):EndCooldown()
			if rCD > 0 then
				caster:FindAbilityByName("arcueid_you"):StartCooldown(rCD - 1)
			end]]
		
			DoDamage(self.parent, args.target, damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
			self.parent:Heal(damage/2, self:GetAbility())

			local effect_cast = ParticleManager:CreateParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent )
			ParticleManager:ReleaseParticleIndex( effect_cast )
		end
	end
end

modifier_arcueid_combo_window = class({})

function modifier_arcueid_combo_window:IsHidden() return true end
function modifier_arcueid_combo_window:IsDebuff() return false end
function modifier_arcueid_combo_window:OnCreated()
	if IsServer() then
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(4):GetName() == "arcueid_impulses" then	    		
			caster:SwapAbilities("arcueid_melty", "arcueid_impulses", true, false)	
		end
	end
end
function modifier_arcueid_combo_window:OnDestroy()
	if IsServer() then
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(4):GetName() == "arcueid_melty" then
			caster:SwapAbilities("arcueid_melty", "arcueid_impulses", false, true)
		end
	end
end