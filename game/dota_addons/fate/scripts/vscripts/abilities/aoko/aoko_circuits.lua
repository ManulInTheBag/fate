LinkLuaModifier("modifier_aoko_circuits_passive", "abilities/aoko/aoko_circuits", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_circuits_overload", "abilities/aoko/aoko_circuits", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_circuits_cc_immune", "abilities/aoko/aoko_circuits", LUA_MODIFIER_MOTION_NONE)

local cd_ability_list = {
	"aoko_shield",
    "aoko_facebreaker",
    "aoko_short_beam",
    "aoko_intimidation",
    "aoko_jumpback",
    --"aoko_sphere",
    "aoko_lazers",
    "aoko_3_beams"
}

local melee = {
    "aoko_shield",
    "aoko_facebreaker",
    "aoko_short_beam",
    "aoko_circuits",
    "aoko_sphere",
    "aoko_intimidation",
    "attribute_bonus_custom"
}

local range = {
    "aoko_shield",
    "aoko_jumpback",
    "aoko_lazers",
    "aoko_circuits",
    "aoko_sphere",
    "aoko_3_beams",
    "attribute_bonus_custom"
}

local ampable = {
	["aoko_facebreaker"] = true,
    ["aoko_short_beam"] = true,
    ["aoko_intimidation"] = true,
    ["aoko_jumpback"] = true,
    ["aoko_lazers"] = true,
    ["aoko_sphere"] = true,
    ["aoko_3_beams"] = true,
    ["aoko_blue"] = true,
    ["aoko_earthlight_starbow"] = true,
    ["aoko_earthlight_starbow_recast"] = true
}

aoko_circuits = class({})

function aoko_circuits:GetIntrinsicModifierName()
	return "modifier_aoko_circuits_passive"
end

function aoko_circuits:CastFilterResult()
	local caster = self:GetCaster()
	if IsServer() then
		if caster:HasModifier("modifier_aoko_earthlight_caster") then
			return UF_FAIL_CUSTOM
		end
	end
	return UF_SUCCESS
end

function aoko_circuits:GetCustomCastError()
    return "#Earthlight_Starbow_Active"
end

function aoko_circuits:OnSpellStart()
	local caster = self:GetCaster()
    
    if not self.form then
    	self.form = 1
    end

    if self.form == 1 then
    	UpdateAbilityLayout(caster, range)
    	self.form = 2
    else
    	UpdateAbilityLayout(caster, melee)
    	self.form = 1
    end
end

function aoko_circuits:GainStacks(number)
	local caster = self:GetCaster()

	caster:FindModifierByName("modifier_aoko_circuits_passive"):RaiseStackCount(number)
end

function aoko_circuits:GetStacks()
	local caster = self:GetCaster()

	if not caster:HasModifier("modifier_aoko_circuits_passive") then
		return 0
	end

	return caster:GetModifierStackCount("modifier_aoko_circuits_passive", caster)
end

function aoko_circuits:StartOverload()
	local caster = self:GetCaster()

	caster:FindModifierByName("modifier_aoko_circuits_passive"):StartOverload()
end

function aoko_circuits:StartComboOverload()
	local caster = self:GetCaster()

	caster:FindModifierByName("modifier_aoko_circuits_passive"):StartComboOverload()
end

function aoko_circuits:Reset()
	local caster = self:GetCaster()

	caster:FindModifierByName("modifier_aoko_circuits_passive"):Reset()
end

modifier_aoko_circuits_passive = class ({})

function modifier_aoko_circuits_passive:IsHidden() return false end
function modifier_aoko_circuits_passive:IsDebuff() return false end

function modifier_aoko_circuits_passive:DeclareFunctions()
    local func = { MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    				MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    				MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
    return func
end

function modifier_aoko_circuits_passive:GetModifierConstantManaRegen()
	return self:GetStackCount()*self:GetAbility():GetSpecialValueFor("manaregen_per_stack")
end

function modifier_aoko_circuits_passive:GetModifierMagicalResistanceBonus()
	return (self:GetParent():HasModifier("modifier_aoko_circuits_overload") and self:GetAbility():GetSpecialValueFor("overload_magres") or 0)
end

function modifier_aoko_circuits_passive:GetModifierPhysicalArmorBonus()
	return (self:GetParent():HasModifier("modifier_aoko_circuits_overload") and self:GetAbility():GetSpecialValueFor("overload_armor") or 0)
end

function modifier_aoko_circuits_passive:GetModifierMoveSpeedBonus_Percentage()
	return (self:GetParent():HasModifier("modifier_aoko_circuits_overload") and self:GetAbility():GetSpecialValueFor("overload_ms") or 0)
end

function modifier_aoko_circuits_passive:OnTakeDamage(args)
	if IsServer() then
		if args.attacker ~= self:GetParent() then return end
		if (args.unit:GetTeam() == self:GetParent():GetTeam()) then return end
		if not self.parent:HasModifier("modifier_aoko_circuits_overload") then return end
		if args.damage_type == 2 then
			args.attacker:Heal(args.damage*self:GetAbility():GetSpecialValueFor("overload_lifesteal")/100, self:GetAbility())
		
			--[[local particle_cast = "particles/aoko/aoko_spell_lifesteal.vpcf"

			local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, args.attacker )
			ParticleManager:ReleaseParticleIndex( effect_cast )]]
		end
	end
end

function modifier_aoko_circuits_passive:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self:SetStackCount(0)

	self.beamcounter = 0

	self.ability:SetLevel(2)
end


function modifier_aoko_circuits_passive:GetMaxStackCount()
	return self:GetAbility():GetSpecialValueFor("stack_max")
end

function modifier_aoko_circuits_passive:RaiseStackCount(count)
	if IsServer() then
		if not IsNotNull(self.parent) then return end
		local mod = self.parent:FindModifierByName("modifier_aoko_3_beams_stacks")
		self.beamability = self.parent:FindAbilityByName("aoko_3_beams")
		-- без aoko_3_beams заряды луча просто не копим, но стаки контуров идут дальше
		self.stacks_for_beam = self.beamability and self.beamability:GetSpecialValueFor("stacks_for_charge") or 0
		self.beam_max_charges = self.beamability and self.beamability:GetSpecialValueFor("max_charges") or 0
		if mod and self.beamability and (mod:GetStackCount() < self.beam_max_charges) then
			self.beamcounter = self.beamcounter + count
			if self.beamcounter >= self.stacks_for_beam then
				local beamstacks = math.floor(self.beamcounter/self.stacks_for_beam)
				self.beamcounter = math.fmod(self.beamcounter, self.stacks_for_beam)
				for i = 1, beamstacks do
					if mod:GetStackCount() < self.beam_max_charges then
						mod:IncrementStackCount()
					end
				end
			end
		else
			self.beamcounter = 0
		end

		if self.parent:HasModifier("modifier_aoko_circuits_overload") then
			self:StartOverload()
			if self.parent.HighSpeedIncantationAcquired then
				local overload = self.parent:FindModifierByName("modifier_aoko_circuits_overload")
				if overload then overload:OnBlueCircuitStackGain(count) end
			end
			return
		end

		local stacks = self:GetStackCount()
		if self.aoko ~= nil then 
			ParticleManager:DestroyParticle(self.aoko, true)
		end
		self.aoko = ParticleManager:CreateParticle("particles/aoko/aoko_circuits_blue.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		Timers:RemoveTimer("aoko_circuits")
		if (stacks + count <= self:GetMaxStackCount()) then
			self:SetStackCount(stacks+count)
		else
			self:SetStackCount(self:GetMaxStackCount())
		end
		stacks = self:GetStackCount()
		if stacks >= 100 then
			self.parent:EmitSound("aoko_overload_sfx")

			if not (self.parent:HasModifier("modifier_aoko_blue_damage_field") or self.parent:HasModifier("modifier_aoko_earthlight_damage_field")) then
				self.parent:EmitSound("aoko_overload")
			end

			if self.parent.MagicianOfFifthAcquired then
				self.parent:AddNewModifier(self.parent, self.ability, "modifier_aoko_circuits_cc_immune", {duration = self.ability:GetSpecialValueFor("overload_cc_immune_duration")})
			end
			
			self:StartOverload()
		end
		Timers:CreateTimer("aoko_circuits", {
			endTime = self:GetAbility():GetSpecialValueFor("stacks_duration"),
			callback = function()
				if self:IsNull() then return end
				self:SetStackCount(0)
				local beamStacks = self.parent:FindModifierByName("modifier_aoko_3_beams_stacks")
				if beamStacks then beamStacks:SetStackCount(0) end
				if self.aoko then ParticleManager:DestroyParticle(self.aoko, true) end
			end})
	end
end

function modifier_aoko_circuits_passive:StartOverload()
	if IsServer() then
		if not IsNotNull(self.parent) then return end
		-- модификатор может не примениться (например, цель уже мертва) — хендл берём с возврата
		local overload = self.parent:AddNewModifier(self.parent, self.ability, "modifier_aoko_circuits_overload", {duration = self.ability:GetSpecialValueFor("overload_duration")})
		if overload and self.parent.CircuitsAcquired then
			overload:OnRedEnter()
		end
		if overload and self.parent.HighSpeedIncantationAcquired then
			overload:OnBlueEnter()
		end
		local stacks = self:GetStackCount()
		if self.aoko ~= nil then 
			ParticleManager:DestroyParticle(self.aoko, true)
		end
		self.aoko = ParticleManager:CreateParticle("particles/aoko/aoko_circuits_red.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		self:SetStackCount(self:GetMaxStackCount())
		Timers:RemoveTimer("aoko_circuits")
		Timers:CreateTimer("aoko_circuits", {
			endTime = self:GetAbility():GetSpecialValueFor("overload_duration"),
			callback = function()
				if self:IsNull() then return end
				self:SetStackCount(0)
				local beamStacks = self.parent:FindModifierByName("modifier_aoko_3_beams_stacks")
				if beamStacks then beamStacks:SetStackCount(0) end
				if self.aoko then ParticleManager:DestroyParticle(self.aoko, true) end
			end})
	end
end

--[[function modifier_aoko_circuits_passive:StartComboOverload()
	if IsServer() then
		self.parent:EmitSound("aoko_overload_sfx")
		self.parent:AddNewModifier(self.parent, self.ability, "modifier_aoko_circuits_overload", {duration = self.parent:FindAbilityByName("aoko_blue"):GetSpecialValueFor("duration")})
		if self.parent.CircuitsAcquired then
			self.parent:AddNewModifier(self.parent, self.ability, "modifier_aoko_circuits_cc_immune", {duration = self.ability:GetSpecialValueFor("blue_cc_immune_duration")})
		end
		local stacks = self:GetStackCount()
		if self.aoko ~= nil then 
			ParticleManager:DestroyParticle(self.aoko, true)
		end
		self.aoko = ParticleManager:CreateParticle("particles/aoko/aoko_circuits_overload.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		self:SetStackCount(self:GetMaxStackCount())
		Timers:RemoveTimer("aoko_circuits")
		Timers:CreateTimer("aoko_circuits", {
			endTime = self.parent:FindAbilityByName("aoko_blue"):GetSpecialValueFor("duration"), 
			callback = function()
				self:SetStackCount(0)
			end})
	end
end]]

function modifier_aoko_circuits_passive:Reset()
	if IsServer() then
		Timers:RemoveTimer("aoko_circuits")
		self:SetStackCount(0)
	end
end

--

modifier_aoko_circuits_overload = class ({})

function modifier_aoko_circuits_overload:IsHidden() return false end
function modifier_aoko_circuits_overload:IsDebuff() return false end

function modifier_aoko_circuits_overload:DeclareFunctions()
    local func = { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE}
    return func
end

function modifier_aoko_circuits_overload:GetModifierTotalDamageOutgoing_Percentage(keys)
	if not (keys.attacker == self:GetParent()) then return 0 end

    if keys.inflictor then	
    	if ampable[keys.inflictor:GetName()] then
	    	if self.dmg_output then
	        	return (self.dmg_output)
	        end
	    end
        return 0
    end
    return 0
end

function modifier_aoko_circuits_overload:OnCreated()
	if IsServer() then
		self.parent = self:GetParent()

		self.ability = self:GetAbility()

		self.amp_per_stack = self.ability:GetSpecialValueFor("attribute_blue_amp_per_stack")
		self.red_amp = self.ability:GetSpecialValueFor("attribute_red_amp")
		self.red_amp_per_level = self.ability:GetSpecialValueFor("attribute_red_amp_per_level")

		self.internal_stacks = 0

		self.dmg_output = 0

		self.blue = false
		self.red = false

		--self.parent:FindAbilityByName("aoko_sphere"):RefreshCharges()

		self:StartIntervalThink(FrameTime())
	end
end

function modifier_aoko_circuits_overload:OnRefresh()
	if IsServer() then
	end
end

function modifier_aoko_circuits_overload:OnBlueCircuitStackGain(gain)
	if IsServer() then
		self.internal_stacks = self.internal_stacks + gain
		self.dmg_output = self.internal_stacks*self.amp_per_stack
		self:SetStackCount(self.dmg_output)

		local cdr = self.ability:GetSpecialValueFor("attribute_cdr_per_stack")*gain
		for i = 1, #cd_ability_list do
			local pepe_ability = self.parent:FindAbilityByName(cd_ability_list[i])
			local cooldown = pepe_ability:GetCooldownTimeRemaining()
			pepe_ability:EndCooldown()
			if (cooldown - cdr) > 0 then
				pepe_ability:StartCooldown(cooldown - cdr)
			end
		end
	end
end

function modifier_aoko_circuits_overload:OnRedEnter()
	if IsServer() then
		if self.blue then
			self.blue = false
			self.internal_stacks = 0
			self.dmg_output = 0
		end
		self.red = true
		self.dmg_output = self.ability:GetSpecialValueFor("attribute_red_amp") + self.parent:GetLevel()*self.red_amp_per_level
		self:SetStackCount(self.dmg_output)
	end
end

function modifier_aoko_circuits_overload:OnIntervalThink()
	if not IsServer() then return end

	if self.red then
		self.dmg_output = self.red_amp + self.parent:GetLevel()*self.red_amp_per_level
	end
	self:SetStackCount(self.dmg_output)
end

function modifier_aoko_circuits_overload:OnBlueEnter()
	if IsServer() then
		if self.red then
			self.red = false
			self.dmg_output = 0
		end
		self.blue = true
		self:SetStackCount(self.dmg_output)
	end
end

function modifier_aoko_circuits_overload:GetEffectName()
	return "particles/aoko/aoko_overload_ambient.vpcf"
end

function modifier_aoko_circuits_overload:GetEffectAttachType()
	return PATTACH_CUSTOMORIGIN_FOLLOW
end

modifier_aoko_circuits_cc_immune = class({})

function modifier_aoko_circuits_cc_immune:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end

function modifier_aoko_circuits_cc_immune:IsHidden()
	return false
end

function modifier_aoko_circuits_cc_immune:GetEffectName()
	return "particles/aoko/aoko_cc_immune.vpcf"
end