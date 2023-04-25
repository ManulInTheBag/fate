LinkLuaModifier("modifier_altera_whip", "abilities/altera/altera_whip", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_whip_stats", "abilities/altera/altera_whip", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_whip_tracker", "abilities/altera/altera_whip", LUA_MODIFIER_MOTION_NONE)

altera_whip = class({})

function altera_whip:GetIntrinsicModifierName()
	return "modifier_altera_whip_stats"
end

function altera_whip:GetCastAnimation()
	if self:GetCaster():HasModifier("modifier_altera_whip_tracker") then
		self.anim = true
		return ACT_DOTA_CAST_ABILITY_1_END
	end
	self.anim = false
	return ACT_DOTA_CAST_ABILITY_1
end

function altera_whip:GetCooldown()
	if self:GetCaster().CrestAcquired then
		return self:GetSpecialValueFor("attribute_cooldown")
	end
	return self:GetSpecialValueFor("cooldown")
end

function altera_whip:OnSpellStart()
	local caster = self:GetCaster()

	if not self.anim then
		caster:AddNewModifier(caster, self, "modifier_altera_whip_tracker", {duration = 2})
		self:Whip1()
	else
		caster:RemoveModifierByName("modifier_altera_whip_tracker")
		self:Whip2()
	end

	local form = "int"

	if caster:HasModifier("modifier_altera_form_str") then
    	form = "str"
    end
    if caster:HasModifier("modifier_altera_form_agi") then
    	form = "agi"
    end
    if caster:HasModifier("modifier_altera_form_int") then
       	form = "int"
    end

	--caster:AddNewModifier(caster, self, "modifier_altera_whip", {duration = self:GetSpecialValueFor("duration")})

	local stk = caster:FindModifierByName("modifier_altera_whip_stats"):GetStackCount()
	local str = caster:GetStrength() - stk*self:GetSpecialValueFor("stat_per_stack")*(form == "str" and 1 or 1/2)
	local agi = caster:GetAgility() - stk*self:GetSpecialValueFor("stat_per_stack")*(form == "agi" and 1 or 1/2)
	local int = caster:GetIntellect() - stk*self:GetSpecialValueFor("stat_per_stack")*(form == "int" and 1 or 1/2) 

    if str >= 29.1 and agi >= 29.1 and int >= 29.1 then
	    if caster:FindAbilityByName("altera_teardrop"):IsCooldownReady() and caster:FindAbilityByName("altera_beam"):IsCooldownReady() and caster:IsAlive() and not (caster:GetAbilityByIndex(5):GetName() == "altera_teardrop") then	    		
	    	caster:SwapAbilities("altera_teardrop", "altera_beam", true, false)
	    	Timers:CreateTimer(4, function()
	    		if caster:GetAbilityByIndex(5):GetName() == "altera_teardrop" then
	    			caster:SwapAbilities("altera_teardrop", "altera_beam", false, true)
	    		end
	    	end)
		end
	end
end

function altera_whip:Whip1()
	local caster = self:GetCaster()
	local form = "int"
	local part = "blue"

	if caster:HasModifier("modifier_altera_form_str") then
    	form = "str"
    	part = "red"
    end
    if caster:HasModifier("modifier_altera_form_agi") then
    	form = "agi"
    	part = "green"
    end
    if caster:HasModifier("modifier_altera_form_int") then
       	form = "int"
       	part = "blue"
    end

	local forw = Vector(0, 0, VectorToAngles(caster:GetForwardVector())[2])

	local slash_fx = ParticleManager:CreateParticle("particles/altera/altera_blade_fury_"..part..".vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(slash_fx, 5, Vector(600, 1, 1))
	ParticleManager:SetParticleControl(slash_fx, 10, forw + Vector(0, 0, -80))

	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        600,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_NONE,
                                        FIND_ANY_ORDER,
                                        false)

	local forw_ori = caster:GetAbsOrigin() + caster:GetForwardVector()*600
	forw_ori = RotatePosition(caster:GetAbsOrigin(), QAngle(0, 30, 0), forw_ori)
	local forw = (forw_ori - caster:GetAbsOrigin()):Normalized()
	for _,enemy in pairs(enemies) do
		local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
		local origin_diff_norm = origin_diff:Normalized()
		if forw:Dot(origin_diff_norm) > 0 then
			self:WhipImpact(enemy, form)
		end
	end
end

function altera_whip:Whip2()
	local caster = self:GetCaster()
	local form = "int"
	local part = "blue"

	if caster:HasModifier("modifier_altera_form_str") then
    	form = "str"
    	part = "red"
    end
    if caster:HasModifier("modifier_altera_form_agi") then
    	form = "agi"
    	part = "green"
    end
    if caster:HasModifier("modifier_altera_form_int") then
       	form = "int"
       	part = "blue"
    end

	local forw = Vector(0, 0, VectorToAngles(caster:GetForwardVector())[2])

	local slash_fx = ParticleManager:CreateParticle("particles/altera/altera_blade_fury_"..part..".vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(slash_fx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(slash_fx, 5, Vector(600, 1, 1))
	ParticleManager:SetParticleControl(slash_fx, 10, forw + Vector(180, 0, 80))

	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
                                        caster:GetAbsOrigin(),
                                        nil,
                                        600,
                                        DOTA_UNIT_TARGET_TEAM_ENEMY,
                                        DOTA_UNIT_TARGET_ALL,
                                        DOTA_UNIT_TARGET_FLAG_NONE,
                                        FIND_ANY_ORDER,
                                        false)

	local forw_ori = caster:GetAbsOrigin() + caster:GetForwardVector()*600
	forw_ori = RotatePosition(caster:GetAbsOrigin(), QAngle(0, -30, 0), forw_ori)
	local forw = (forw_ori - caster:GetAbsOrigin()):Normalized()
	for _,enemy in pairs(enemies) do
		local origin_diff = enemy:GetAbsOrigin() - caster:GetAbsOrigin()
		local origin_diff_norm = origin_diff:Normalized()
		if forw:Dot(origin_diff_norm) > 0 then
			self:WhipImpact(enemy, form)
		end
	end
end

function altera_whip:WhipImpact(enemy, form)
	local caster = self:GetCaster()

	local damage = self:GetSpecialValueFor(form.."_damage")
	DoDamage(caster, enemy, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
	if caster.EndlessAcquired then
		local slow_duration = self:GetSpecialValueFor("attribute_slow_duration")
		if enemy:IsConsideredHero() then
			local stack_duration = self:GetSpecialValueFor("attribute_stat_duration")
			local stat_modifier = caster:FindModifierByName("modifier_altera_whip_stats")
			stat_modifier:IncrementStackCount()
			Timers:CreateTimer(stack_duration, function()
				stat_modifier:DecrementStackCount()
			end)
		end
		enemy:AddNewModifier(caster, self, "modifier_altera_whip", {duration = slow_duration})
	end
	if form == "str" then
		local healing = self:GetSpecialValueFor("str_heal")
		if enemy:IsConsideredHero() then
			caster:Heal(healing, self)
		end
	elseif form == "agi" then
		enemy:AddNewModifier(caster, self, "modifier_silence", {duration = self:GetSpecialValueFor("agi_silence_duration")})
	else
		giveUnitDataDrivenModifier(caster, enemy, "locked", self:GetSpecialValueFor("int_lock_duration"))
	end
end

--

modifier_altera_whip_tracker = class({})

function modifier_altera_whip_tracker:IsHidden() return true end

function modifier_altera_whip_tracker:OnCreated()
	if IsServer() then
		self:GetAbility():EndCooldown()
	end
end 

function modifier_altera_whip_tracker:OnDestroy()
	if IsServer() then
		self:GetAbility():UseResources(false, false, false, true)
	end
end

--

modifier_altera_whip = class({})
function modifier_altera_whip:IsHidden() return false end
function modifier_altera_whip:IsDebuff() return false end
function modifier_altera_whip:IsPurgable() return false end
function modifier_altera_whip:IsPurgeException() return false end
function modifier_altera_whip:RemoveOnDeath() return true end

function modifier_altera_whip:DeclareFunctions()
    local func = { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
    return func
end
function modifier_altera_whip:GetModifierMoveSpeedBonus_Percentage()
    return -1*self:GetAbility():GetSpecialValueFor("attribute_slow")
end

--

modifier_altera_whip_stats = class({})
function modifier_altera_whip_stats:IsHidden() return false end
function modifier_altera_whip_stats:IsDebuff() return false end
function modifier_altera_whip_stats:IsPurgable() return false end
function modifier_altera_whip_stats:IsPurgeException() return false end
function modifier_altera_whip_stats:RemoveOnDeath() return true end

function modifier_altera_whip_stats:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			 MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			 MODIFIER_PROPERTY_STATS_INTELLECT_BONUS}
end

function modifier_altera_whip_stats:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("stat_per_stack")*self:GetParent():GetModifierStackCount("modifier_altera_whip_stats", self:GetParent())*(self:GetParent():HasModifier("modifier_altera_form_str") and 1 or 0.5)
end

function modifier_altera_whip_stats:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("stat_per_stack")*self:GetParent():GetModifierStackCount("modifier_altera_whip_stats", self:GetParent())*(self:GetParent():HasModifier("modifier_altera_form_agi") and 1 or 0.5)
end

function modifier_altera_whip_stats:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("stat_per_stack")*self:GetParent():GetModifierStackCount("modifier_altera_whip_stats", self:GetParent())*(self:GetParent():HasModifier("modifier_altera_form_int") and 1 or 0.5)
end