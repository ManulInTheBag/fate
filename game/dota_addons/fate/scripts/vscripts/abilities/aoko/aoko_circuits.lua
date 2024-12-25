LinkLuaModifier("modifier_aoko_circuits_passive", "abilities/aoko/aoko_circuits", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoko_circuits_overload", "abilities/aoko/aoko_circuits", LUA_MODIFIER_MOTION_NONE)

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

aoko_circuits = class({})

function aoko_circuits:CastFilterResult()
	local caster = self:GetCaster()
	if IsServer() then
		local stacks = caster:FindModifierByName("modifier_aoko_circuits_passive"):GetStackCount()

		if stacks < self:GetSpecialValueFor("overload_threshold") then 
			return UF_FAIL_CUSTOM
		end
	end
	return UF_SUCCESS
end

function aoko_circuits:GetCustomCastError()
    return "#Not_enough_stacks"
end

function aoko_circuits:GetIntrinsicModifierName()
	return "modifier_aoko_circuits_passive"
end

function aoko_circuits:OnSpellStart()
	local caster = self:GetCaster()

	self:StartOverload()
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
    local func = { MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
    				MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    				MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
    return func
end

function modifier_aoko_circuits_passive:GetModifierTotalPercentageManaRegen()
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
end


function modifier_aoko_circuits_passive:GetMaxStackCount()
	return self:GetAbility():GetSpecialValueFor("stack_max")
end

function modifier_aoko_circuits_passive:RaiseStackCount(count)
	if IsServer() then
		if self.parent:HasModifier("modifier_aoko_circuits_overload") then
			if self.parent.MagicianOfFifthAcquired then
				local cdr = self.ability:GetSpecialValueFor("attribute_cdr_per_stack")*count
				for i = 1, #cd_ability_list do
					local pepe_ability = self.parent:FindAbilityByName(cd_ability_list[i])
					local cooldown = pepe_ability:GetCooldownTimeRemaining()
					pepe_ability:EndCooldown()
					if (cooldown - cdr) > 0 then
						pepe_ability:StartCooldown(cooldown - cdr)
					end
				end
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
		Timers:CreateTimer("aoko_circuits", {
			endTime = self:GetAbility():GetSpecialValueFor("stacks_duration"), 
			callback = function()
				self:SetStackCount(0)
			end})
	end
end

function modifier_aoko_circuits_passive:StartOverload()
	if IsServer() then
		self.parent:EmitSound("aoko_overload_sfx")
		self.parent:EmitSound("aoko_overload")
		self.parent:AddNewModifier(self.parent, self.ability, "modifier_aoko_circuits_overload", {duration = self.ability:GetSpecialValueFor("overload_duration")})
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
				self:SetStackCount(0)
			end})
	end
end

function modifier_aoko_circuits_passive:StartComboOverload()
	if IsServer() then
		self.parent:EmitSound("aoko_overload_sfx")
		self.parent:AddNewModifier(self.parent, self.ability, "modifier_aoko_circuits_overload", {duration = self.parent:FindAbilityByName("aoko_blue"):GetSpecialValueFor("duration")})
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
end

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

function modifier_aoko_circuits_overload:OnCreated()
	if IsServer() then
		self.parent = self:GetParent()

		self.ability = self:GetAbility()

		--self.parent:FindAbilityByName("aoko_sphere"):RefreshCharges()

		--self:StartIntervalThink(1)
	end
end

function modifier_aoko_circuits_overload:OnIntervalThink()
	if IsServer() then
		for i = 1, #cd_ability_list do
			local pepe_ability = self.parent:FindAbilityByName(cd_ability_list[i])
			local cooldown = pepe_ability:GetCooldownTimeRemaining()
			pepe_ability:EndCooldown()
			if (cooldown - 1) > 0 then
				pepe_ability:StartCooldown(cooldown - 1)
			end
		end
	end
end

function modifier_aoko_circuits_overload:GetEffectName()
	return "particles/aoko/aoko_overload_ambient.vpcf"
end

function modifier_aoko_circuits_overload:GetEffectAttachType()
	return PATTACH_CUSTOMORIGIN_FOLLOW
end