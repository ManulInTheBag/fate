modifier_holy_mother = class({})

LinkLuaModifier("modifier_holy_mother_buff", "abilities/jtr/modifiers/modifier_holy_mother_buff", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_holy_mother_debuff", "abilities/jtr/modifiers/modifier_holy_mother", LUA_MODIFIER_MOTION_NONE)

function modifier_holy_mother:DeclareFunctions()
	return { --MODIFIER_EVENT_ON_ATTACK_LANDED
	 }
end

if IsServer() then 
	function modifier_holy_mother:OnAttackLanded(args)
		if args.attacker ~= self:GetParent() then return end

		local target = args.target
		if not target then return end
		if not target:IsAlive() then return end
		local caster = self:GetParent()
		local damage = self:GetAbility():GetSpecialValueFor("damage_per_stack")--caster:GetAgility()*0.25
		target:AddNewModifier(caster, self:GetAbility(), "modifier_holy_mother_debuff", {duration = self:GetAbility():GetSpecialValueFor("stack_duration")})
		--[[if IsFemaleServant(target) then
			damage = damage*2
			caster:AddNewModifier(caster, self:GetAbility(), "modifier_holy_mother_buff", { Duration = self:GetAbility():GetSpecialValueFor("duration"),
																						    AgiPerStack = self:GetAbility():GetSpecialValueFor("agi_per_stack")})
		end]]
		DoDamage(caster, target, damage*target:FindModifierByName("modifier_holy_mother_debuff"):GetStackCount(), DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
	end
end

function modifier_holy_mother:IsHidden()
	return true 
end

--

modifier_holy_mother_debuff = class({})

function modifier_holy_mother_debuff:IsDebuff() return true end
function modifier_holy_mother_debuff:IsHidden() return false end

function modifier_holy_mother_debuff:OnCreated()
	if IsServer() then
		self:SetStackCount(1)
	end
end
function modifier_holy_mother_debuff:OnRefresh()
	if IsServer() then
		self:SetStackCount(self:GetStackCount() + 1)
	end
end