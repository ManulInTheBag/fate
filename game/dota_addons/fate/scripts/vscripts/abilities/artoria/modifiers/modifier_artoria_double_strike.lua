-----------------------------
--    Modifier: Artoria Double Strike    --
-----------------------------
LinkLuaModifier( "modifier_artoria_crit", "abilities/artoria/modifiers/modifier_artoria_double_strike", LUA_MODIFIER_MOTION_NONE )

modifier_artoria_double_strike = class({})

function modifier_artoria_double_strike:OnCreated(args)
	if IsServer() then
		self.ProcReady = true
		--self:StartIntervalThink(0.1)
	end
end

function modifier_artoria_double_strike:OnRefresh(args)
	self:OnCreated(args)
end

function modifier_artoria_double_strike:OnAttackStart(args)
	if IsServer() then
		if args.attacker ~= self:GetParent() then 
			return 
		end
		
		--Identification--
		local caster = args.attacker
		local caster_position = args.attacker:GetAbsOrigin()
		local target = args.target
		
		--Random Number Generator--
		local proc = RandomInt(1, 100)
		
		--Condition--
		if proc < 36 and self.ProcReady and caster:HasModifier("modifier_artoria_improve_instinct_attribute") then
			--DoDamage(args.attacker, args.target, damage , DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
			caster:AddNewModifier(caster, self:GetAbility(), "modifier_artoria_crit", {})
		end
	end
end

function modifier_artoria_double_strike:OnIntervalThink()
	self.ProcReady = true
	self:StartIntervalThink(-1)
	--print("passive double attack cooldown")
end

function modifier_artoria_double_strike:IsHidden()
	return true
end

function modifier_artoria_double_strike:RemoveOnDeath()
	return false
end

function modifier_artoria_double_strike:IsDebuff()
	return false 
end

function modifier_artoria_double_strike:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

modifier_artoria_crit = class({})

function modifier_artoria_crit:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE}
end

function modifier_artoria_crit:IsHidden() return true end

function modifier_artoria_crit:GetModifierPreAttack_CriticalStrike()
	return 200
end

function modifier_artoria_crit:OnAttackLanded(args)
	if args.attacker == self:GetCaster() then
		self:Destroy()
	end
end