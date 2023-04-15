LinkLuaModifier("modifier_altera_whip", "abilities/altera/altera_whip", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_whip_agi", "abilities/altera/altera_whip", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_whip_int", "abilities/altera/altera_whip", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_whip_int_ally", "abilities/altera/altera_whip", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_altera_whip_stats", "abilities/altera/altera_whip", LUA_MODIFIER_MOTION_NONE)

altera_whip = class({})

function altera_whip:OnSpellStart()
	local caster = self:GetCaster()

	caster:AddNewModifier(caster, self, "modifier_altera_whip", {duration = self:GetSpecialValueFor("duration")})

    if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then
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

modifier_altera_whip = class({})
function modifier_altera_whip:IsHidden() return false end
function modifier_altera_whip:IsDebuff() return false end
function modifier_altera_whip:IsPurgable() return false end
function modifier_altera_whip:IsPurgeException() return false end
function modifier_altera_whip:RemoveOnDeath() return true end

function modifier_altera_whip:DeclareFunctions()
    local func = {  MODIFIER_EVENT_ON_ATTACK_ALLIED,
                MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
            	MODIFIER_PROPERTY_MODEL_CHANGE,
            	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
    return func
end
function modifier_altera_whip:GetModifierAttackSpeedBonus_Constant()
    return (true and (self:GetAbility():GetSpecialValueFor("agi_as") + (self:GetParent():HasModifier("modifier_altera_crest") and self:GetAbility():GetSpecialValueFor("agi_as_mult")*self:GetParent():GetAgility() or 0)) or 0)
end
function modifier_altera_whip:GetModifierModelChange()
  return "models/updated_by_seva_and_hudozhestvenniy_film_spizdili/altera/altera_whip.vmdl"
end
function modifier_altera_whip:GetModifierAttackRangeBonus()
    return self:GetAbility():GetSpecialValueFor("attack_range_bonus")
end
function modifier_altera_whip:OnAttackAllied(args)
	if args.attacker ~= self.parent then return end
	if self.form ~= "int" then return end
	--[[
	args.target:AddNewModifier(self.parent, self.ability, "modifier_altera_whip_int_ally", {duration = 1})
	Timers:CreateTimer(FrameTime(), function()
		if not (args.target:IsAlive() and args.attacker:IsAlive()) then return end
		local forcemove = {
			UnitIndex = nil,
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET ,
			TargetIndex = nil
		}
		forcemove.UnitIndex = self.parent:entindex()
		forcemove.TargetIndex = args.target:entindex()
		self.parent:Stop()
		ExecuteOrderFromTable(forcemove)
		Timers:CreateTimer(FrameTime(), function()
			args.target:RemoveModifierByName("modifier_altera_whip_int_ally")
		end)
		
	end)
	]]
end
function modifier_altera_whip:OnAttackLanded(args)
    if args.attacker ~= self.parent then return end

    local damage = 0
    local heal = 0

	if self.form == "str" then
		damage = self.ability:GetSpecialValueFor("str_damage")
		heal = self.ability:GetSpecialValueFor("str_heal")
		if self.parent.CrestAcquired then
			damage = damage + self.ability:GetSpecialValueFor("str_damage_mult")*self.parent:GetStrength()
			heal = heal + self.ability:GetSpecialValueFor("str_heal_mult")*self.parent:GetStrength()
		end
		DoDamage(args.attacker, args.target, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
		self.parent:Heal(self.ability:GetSpecialValueFor("str_heal"), self.ability)
	end
	if self.form == "agi" then
		damage = self.ability:GetSpecialValueFor("agi_damage")
		if self.parent.CrestAcquired then
			damage = damage + self.ability:GetSpecialValueFor("agi_damage_mult")*self.parent:GetAgility()
		end
		DoDamage(args.attacker, args.target, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	end
	if self.form == "int" then
		damage = self.ability:GetSpecialValueFor("int_damage")
		heal = self.ability:GetSpecialValueFor("int_heal")
		if self.parent.CrestAcquired then
			damage = damage + self.ability:GetSpecialValueFor("int_damage_mult")*self.parent:GetIntellect()
			heal = heal + self.ability:GetSpecialValueFor("int_heal_mult")*self.parent:GetIntellect()
		end
		if self.team ~= args.target:GetTeamNumber() then
	    	DoDamage(args.attacker, args.target, damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
			local targets = FindUnitsInRadius(self.parent:GetTeam(), args.target:GetAbsOrigin(), nil, self.ability:GetSpecialValueFor("heal_aoe"), 
												DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
		for i = 1, #targets do
			targets[i]:Heal(heal, self.ability)
			
		end
		local pulse = ParticleManager:CreateParticle( "particles/altera/altera_heal.vpcf", PATTACH_CUSTOMORIGIN, nil )
		ParticleManager:SetParticleControl( pulse, 1, args.target:GetAbsOrigin())
	    --else
	    	--args.target:AddNewModifier(self.parent, self.ability, "modifier_altera_whip_int_ally", {duration = FrameTime()})
	    	--args.target:Heal(self.ability:GetSpecialValueFor("int_heal"), self.ability)
	    end
	end
	if self.parent.EndlessAcquired then
		if self.add_duration < self.max_duration then
			self.add_duration = self.add_duration + self.duration_per_atk
			self.curr_duration = self.curr_duration + self.duration_per_atk
			local curr_duration = self.curr_duration
			local add_duration = self.add_duration
			local modifier = self.parent:AddNewModifier(self.parent, self.ability, "modifier_altera_whip", {duration = self.curr_duration, DoNotRemove = 1})
			modifier.curr_duration = curr_duration
			modifier.add_duration = add_duration
		end
		local stat_modifier = self.parent:AddNewModifier(self.parent, self.ability, "modifier_altera_whip_stats", {duration = self.curr_duration})
		stat_modifier:IncrementStackCount()
	end
end
--[[function modifier_altera_whip:GetModifierAttackSpeedBonus_Constant()
    return self:GetAbility():GetSpecialValueFor("as_bonus")
end]]

function modifier_altera_whip:OnCreated(args)
    if IsServer() then
        self.caster = self:GetCaster()
        self.parent = self:GetParent()
        self.ability = self:GetAbility()
        self.team = self.parent:GetTeamNumber()
        self.form = "neutral"
        self.duration_per_atk = self.ability:GetSpecialValueFor("duration_per_atk")
        self.curr_duration = self.ability:GetSpecialValueFor("duration")
        self.max_duration = self.curr_duration + self.ability:GetSpecialValueFor("max_bonus_duration")
        self.add_duration = self.ability:GetSpecialValueFor("duration")

        if not args.DoNotRemove then
        	self.parent:RemoveModifierByName("modifier_altera_whip_stats")
        	self.timer_sound = 0
        	EmitSoundOn("jtr_bloody_thirst_start", self.parent)
        end

        if self.parent:HasModifier("modifier_altera_form_str") then
        	self.form = "str"
        end
        if self.parent:HasModifier("modifier_altera_form_agi") then
        	self.form = "agi"
        end
        if self.parent:HasModifier("modifier_altera_form_int") then
        	self.form = "int"
        end
        self:StartIntervalThink(FrameTime())
    end
end

function modifier_altera_whip:OnRefresh(args)
	self:OnCreated(args)
end

function modifier_altera_whip:OnDestroy()
	StopSoundOn("jtr_bloody_thirst_middle", self:GetParent())
	EmitSoundOn("jtr_bloody_thirst_end", self:GetParent())
end

function modifier_altera_whip:OnIntervalThink()
	if IsServer() then
		self.curr_duration = self.curr_duration - FrameTime()
		self.timer_sound = self.timer_sound + FrameTime()
		if self.timer_sound >= 1.7 then
			self.timer_sound = 0
			EmitSoundOn("jtr_bloody_thirst_middle", self.parent)
		end
	end
end

function modifier_altera_whip:GetEffectName()
	if self:GetParent():HasModifier("modifier_altera_form_str") then
        return "particles/altera/altera_buff_red.vpcf"
    end
    if self:GetParent():HasModifier("modifier_altera_form_agi") then
        return "particles/altera/altera_buff_green.vpcf"
    end
    if self:GetParent():HasModifier("modifier_altera_form_int") then
        return "particles/altera/altera_buff_blue.vpcf"
    end
    return "particles/altera/altera_buff_blue.vpcf"
end

modifier_altera_whip_int_ally = class({})

function modifier_altera_whip_int_ally:IsHidden() return true end

function modifier_altera_whip_int_ally:CheckState()
    local state =   { 
                        [MODIFIER_STATE_SPECIALLY_DENIABLE] = true,
                    }
    return state
end

function modifier_altera_whip_int_ally:OnTakeDamage(args)
	if args.unit ~= self:GetParent() then return end

	if args.damage_type ~= 1 then return end

	args.unit:SetHealth(args.unit:GetHealth() + args.damage)
end



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
	return (self:GetParent():HasModifier("modifier_altera_form_str") and self:GetAbility():GetSpecialValueFor("stat_per_stack")*self:GetParent():GetModifierStackCount("modifier_altera_whip_stats", self:GetParent()) or 0)
end

function modifier_altera_whip_stats:GetModifierBonusStats_Agility()
	return (self:GetParent():HasModifier("modifier_altera_form_agi") and self:GetAbility():GetSpecialValueFor("stat_per_stack")*self:GetParent():GetModifierStackCount("modifier_altera_whip_stats", self:GetParent()) or 0)
end

function modifier_altera_whip_stats:GetModifierBonusStats_Intellect()
	return (self:GetParent():HasModifier("modifier_altera_form_int") and self:GetAbility():GetSpecialValueFor("stat_per_stack")*self:GetParent():GetModifierStackCount("modifier_altera_whip_stats", self:GetParent()) or 0)
end