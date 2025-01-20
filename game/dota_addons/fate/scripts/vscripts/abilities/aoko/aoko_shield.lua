LinkLuaModifier("modifier_aoko_shield", "abilities/aoko/aoko_shield", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_shield_window", "abilities/aoko/aoko_shield", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_shield_particle", "abilities/aoko/aoko_shield", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_combo_window", "abilities/aoko/aoko_shield", LUA_MODIFIER_MOTION_NONE)

local cd_ability_list = {
	--"aoko_shield",
    "aoko_facebreaker",
    "aoko_short_beam",
    "aoko_intimidation",
    "aoko_jumpback",
    --"aoko_sphere",
    "aoko_lazers",
    "aoko_3_beams"
}

aoko_shield = class({})

function aoko_shield:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("aoko_jumpback"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("aoko_jumpback"):SetLevel(self:GetLevel())
    end
end

function aoko_shield:GetManaCost()
	local caster = self:GetCaster()
	local ability = caster:FindAbilityByName("aoko_circuits")

	local stacks = ability:GetStacks()

	local base_manacost = self:GetSpecialValueFor("mana_cost")
	local increment = ability:GetSpecialValueFor("manacost_increase_per_stack")

	local result = math.min(base_manacost*(1 + stacks*increment/100), caster:GetMaxMana())

	return result
end

--[[function aoko_shield:OnAbilityPhaseStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_aoko_shield_particle", {duration = self:GetSpecialValueFor("cast_point") + self:GetChannelTime()})
	return true
end

function aoko_shield:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()

	caster:RemoveModifierByName("modifier_aoko_shield_particle")
end]]

function aoko_shield:OnSpellStart()
	local caster = self:GetCaster()
	local tpoint = self:GetCursorPosition()

	local dir = (tpoint - caster:GetAbsOrigin()):Normalized()
	dir.z = 0
	if not (tpoint == caster:GetAbsOrigin()) then
		caster:SetForwardVector(dir)
	end

	caster:AddNewModifier(caster, self, "modifier_aoko_shield", {duration = self:GetChannelTime()})
	caster:AddNewModifier(caster, self, "modifier_aoko_shield_particle", {duration = self:GetChannelTime()})

	caster:EmitSound("aoko_barrier")

	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
	    if self:GetAutoCastState() and caster:FindAbilityByName("aoko_blue"):IsCooldownReady() and caster:IsAlive() then	    		
	    	caster:AddNewModifier(caster, self, "modifier_aoko_combo_window", {duration = 2})
		end
	end
end

function aoko_shield:OnChannelFinish()
	local caster = self:GetCaster()

	caster:RemoveModifierByName("modifier_aoko_shield")
	caster:RemoveModifierByName("modifier_aoko_shield_particle")
end

function aoko_shield:Counter()
	local caster = self:GetCaster()
	local dir = caster:GetForwardVector()
	local dist = self:GetSpecialValueFor("distance")
	local mana = self:GetSpecialValueFor("mana")
	local cdr = self:GetSpecialValueFor("cooldown_reduction")

	local circuits = caster:FindAbilityByName("aoko_circuits")
	local stacks = self:GetSpecialValueFor("stack_gain")

	circuits:GainStacks(stacks)

	local rand = math.random(1,3)
	caster:EmitSound("aoko_shield_sfx_proc_"..rand)
	caster:EmitSound("aoko_barrier_proc_"..math.random(1, 2))

	local point = caster:GetAbsOrigin() - dir*dist

	local particle1 = ParticleManager:CreateParticle("particles/aoko/aoko_red_warp.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle1, 0, caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_hitloc")))

	FindClearSpaceForUnit(caster, point, true)

	local particle1 = ParticleManager:CreateParticle("particles/aoko/aoko_blue_warp.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle1, 0, caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_hitloc")))

	caster:GiveMana(caster:GetMaxMana()*mana/100)

	HardCleanse(caster)
	Timers:CreateTimer(FrameTime(), function()
		HardCleanse(caster)
	end)

	if caster.CircuitsAcquired then
		for i = 1, #cd_ability_list do
			local pepe_ability = caster:FindAbilityByName(cd_ability_list[i])
			local cooldown = pepe_ability:GetCooldownTimeRemaining()
			pepe_ability:EndCooldown()
			if (cooldown - cdr) > 0 then
				pepe_ability:StartCooldown(cooldown - cdr)
			end
		end
	end
end

modifier_aoko_shield = class({})

function modifier_aoko_shield:IsHidden() return false end
function modifier_aoko_shield:IsDebuff() return false end

function modifier_aoko_shield:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end

function modifier_aoko_shield:OnCreated()

end

function modifier_aoko_shield:DeclareFunctions()
	local hFunc = 	{	
						--MODIFIER_PROPERTY_MAGICAL_CONSTANT_BLOCK,
						MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
					}
	return hFunc
end
function modifier_aoko_shield:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end
function modifier_aoko_shield:GetModifierIncomingDamageConstant(keys)
	if IsServer() then
        if keys.damage > 0 then
            local block_now   = self:GetStackCount()
            local block_check = block_now - keys.original_damage
            local blocked = 0
            if block_check > 0 then
            	blocked = keys.original_damage
                self:SetStackCount(block_check)
                self.fBarrierBlock = block_check
            else
            	blocked = keys.original_damage--block_now
            	local damage = keys.original_damage - block_now

            	local IsBScrollIgnored = false
            	if keys.damage_type == DAMAGE_TYPE_MAGICAL then
			        if keys.inflictor then
			        	if BIgnoreCheck(keys.inflictor) then
			        		IsBScrollIgnored = true
			        	end

				        if (keys.inflictor:GetAbilityName() == "karna_brahmastra" 
				            or keys.inflictor:GetAbilityName() == "karna_brahmastra_kundala")
				            and keys.attacker.ManaBurstAttribute then
				            IsBScrollIgnored = true
				        end

				        if IsBScrollIgnored == false and keys.target:HasModifier("modifier_b_scroll") then 
				            local originalDamage = damage - keys.target.BShieldAmount
				            keys.target.BShieldAmount = keys.target.BShieldAmount - damage
				            if keys.target.BShieldAmount <= 0 then
				                damage = originalDamage
				                keys.target:RemoveModifierByName("modifier_b_scroll")
				            else 
				                damage = 0
				            end
				        end
				    end
			    end
				damage = damage - self.hAbility:GetSpecialValueFor("shield_damage_decrease_flat_value")
				self:ActivateCounter()
				if damage > 0 then
					local dmgtable = {
						attacker = keys.attacker,
						victim = keys.target,
						damage = damage,
						damage_type = keys.damage_type,
						damage_flags = keys.damage_flags,
						ability = keys.inflictor
					}
					self:Destroy()
					ApplyDamage(dmgtable)
				end
            end

            return -1*blocked
        end
	else
        return self:GetStackCount()
    end
end

function modifier_aoko_shield:OnCreated(hTable)
	self.hCaster  = self:GetCaster()
	self.hParent  = self:GetParent()
	self.hAbility = self:GetAbility()

	self.fBarrierBlock = self.hAbility:GetSpecialValueFor("shield_amount")
    
    --[[if not self.iShieldPFX then
	    self.iShieldPFX = ParticleManager:CreateParticle( "particles/custom/jeanne/jeanne_luminosite_eternelle_barrier.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.hParent ) 
	    ParticleManager:SetParticleControl( self.iShieldPFX, 0, self.hCaster:GetAbsOrigin() )

	    self:AddParticle(self.iShieldPFX, false, false, -1, false, false)
	end]]

	if IsServer() then
		self.hCaster:EmitSound("aoko_shield_sfx")
		self:SetStackCount(self.fBarrierBlock)
	end
end
function modifier_aoko_shield:OnRefresh(hTable)
	self:OnCreated(hTable)
end

function modifier_aoko_shield:ActivateCounter()
	self.hAbility:EndChannel(false)
	self.hAbility:Counter()
end

--

modifier_aoko_shield_particle = class({})

function modifier_aoko_shield_particle:IsHidden() return true end
function modifier_aoko_shield_particle:IsDebuff() return false end

function modifier_aoko_shield_particle:OnCreated()
	self.caster = self:GetCaster()

	if IsServer() then
		if not self.shield_fx then
			local ori = self.caster:GetAbsOrigin() + self.caster:GetForwardVector()*100 + Vector(0, 0, 150)

		    self.shield_fx = ParticleManager:CreateParticle( "particles/aoko/aoko_shield.vpcf", PATTACH_CUSTOMORIGIN, self.caster ) 
		    ParticleManager:SetParticleControl( self.shield_fx, 0, ori )

		    self:AddParticle(self.shield_fx, false, false, -1, false, false)
		end
	end
end

--

modifier_aoko_combo_window = class({})

function modifier_aoko_combo_window:IsHidden() return true end
function modifier_aoko_combo_window:IsDebuff() return false end
function modifier_aoko_combo_window:OnCreated()
	if IsServer() then
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(4):GetName() == "aoko_circuits" then	    		
			caster:SwapAbilities("aoko_blue", "aoko_circuits", true, false)	
		end
	end
end
function modifier_aoko_combo_window:OnDestroy()
	if IsServer() then
		local caster = self:GetParent()
		if caster:GetAbilityByIndex(4):GetName() == "aoko_blue" then
			caster:SwapAbilities("aoko_blue", "aoko_circuits", false, true)
		end
	end
end
