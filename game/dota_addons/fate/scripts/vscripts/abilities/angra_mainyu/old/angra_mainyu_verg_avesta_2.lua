angra_mainyu_verg_avesta = class({})

LinkLuaModifier("modifier_verg_avesta_counter", "abilities/angra_mainyu/angra_mainyu_verg_avesta", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("angra_mainyu_verg_avesta_slow", "abilities/angra_mainyu/angra_mainyu_verg_avesta", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_verg_avesta_buff", "abilities/angra_mainyu/angra_mainyu_verg_avesta", LUA_MODIFIER_MOTION_NONE)

--function angra_mainyu_verg_avesta:GetAOERadius()
	--return self:GetSpecialValueFor("radius")
--end

function angra_mainyu_verg_avesta:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local radius = self:GetAOERadius()
	local delay = self:GetSpecialValueFor("delay")
	--local target = self:GetCursorTarget()


	EmitGlobalSound("Avenger.Berg")

	EmitGlobalSound("Avenger.BergShout")

	caster:AddNewModifier(caster,self,"modifier_verg_avesta_counter", {duration = self:GetSpecialValueFor("reset_delay"), DIACQUIRED = caster.IsDIAcquired})
	caster:AddNewModifier(caster,self,"modifier_verg_avesta_buff", {duration = self:GetSpecialValueFor("angra_regen"), DIACQUIRED = caster.IsDIAcquired})

	local casterHealthPct = caster:GetHealthPercent()
	local targetHealthPct = target:GetHealthPercent()

	print(caster:GetMaxHealth()/100*30)

	if caster:GetHealth() <= caster:GetMaxHealth()/100*30 then

		--caster:SetHealth(math.max(caster:GetMaxHealth() * targetHealthPct / 100, 1))
		target:SetHealth(caster:GetMaxHealth()* casterHealthPct / 100 * 30)

	else

		--caster:SetHealth(math.max(caster:GetMaxHealth() * targetHealthPct / 100, 1))
		target:SetHealth(caster:GetMaxHealth() * casterHealthPct / 100)

	end

	local verg_particle = ParticleManager:CreateParticle("particles/custom/avenger/avenger_verg_avesta.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(verg_particle, 0, caster:GetAbsOrigin())

	Timers:CreateTimer(10, function()
		ParticleManager:DestroyParticle( verg_particle, false )
		ParticleManager:ReleaseParticleIndex( verg_particle )
		return nil
	end)

	
end

modifier_verg_avesta_counter = class({})

function modifier_verg_avesta_counter:IsDebuff()
	return false 
end
function modifier_verg_avesta_counter:OnCreated(table)
	self.DIACQUIRED = table.DIACQUIRED
end
function modifier_verg_avesta_counter:IsHidden()
	return false 
end
function modifier_verg_avesta_counter:OnTakeDamage(args)
    if IsServer() then
        if args.unit ~= self:GetParent() then return end
		if args.attacker:GetTeamNumber() ~= self:GetParent():GetTeamNumber() and GetDistance(args.attacker, self:GetParent()) <= self:GetAbility():GetSpecialValueFor("radius") then

			self:GetParent():GiveMana(args.damage * self:GetAbility():GetSpecialValueFor("mana_restore_percentage") * 0.01)

		end
		if args.unit:IsAlive() and not args.unit:IsMagicImmune() then

			if args.attacker:GetTeamNumber() ~= self:GetParent():GetTeamNumber() and GetDistance(args.attacker, self:GetParent()) <= self:GetAbility():GetSpecialValueFor("radius") then
				local return_percentage = self:GetAbility():GetSpecialValueFor("multiplier")
				if self.DIACQUIRED and self:GetParent():HasModifier("modifier_true_form") then
					return_percentage = return_percentage + self:GetAbility():GetSpecialValueFor("return_bonus")
				end
				local damage  = args.damage*return_percentage/100
				DoDamage(self:GetCaster(), args.attacker, damage, DAMAGE_TYPE_PURE, 0, self:GetAbility(), false)
				if self.DIACQUIRED then
					args.attacker:AddNewModifier(self:GetParent(), self:GetAbility() , "angra_mainyu_verg_avesta_slow",{duration = 0.5})
				end
			end
		end
    end
end

modifier_verg_avesta_buff = class({})

function modifier_verg_avesta_buff:DeclareFunctions()
	local func = {	MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
				}
	return func
end

function modifier_verg_avesta_buff:OnCreated(table)
	self.DIACQUIRED = table.DIACQUIRED
end

--function modifier_verg_avesta_buff:GetModifierConstantHealthRegen()
	--return self:GetParent():GetSpecialValueFor("angra_regen")
--end

function modifier_verg_avesta_buff:IsDebuff()
    return false
end

function modifier_verg_avesta_buff:RemoveOnDeath()
    return true
end



angra_mainyu_verg_avesta_slow = class({})

function angra_mainyu_verg_avesta_slow:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    }
 
    return funcs
end

function angra_mainyu_verg_avesta_slow:GetModifierMoveSpeedBonus_Percentage() 
    return -50
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
