LinkLuaModifier("modifier_jeanne_curse_active", "abilities/jeanne_alter/jeanne_curse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_curse_weak", "abilities/jeanne_alter/jeanne_curse", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_curse_buff", "abilities/jeanne_alter/jeanne_curse", LUA_MODIFIER_MOTION_NONE)

jeanne_curse = class({})

function jeanne_curse:GetIntrinsicModifierName()
	return "modifier_jeanne_curse_buff"
end

function jeanne_curse:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if IsSpellBlocked(target) then return end

	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.voice == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="nasus_issohni"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end)

	target:AddNewModifier(caster, self, "modifier_jeanne_curse_active", {duration = self:GetSpecialValueFor("duration")})
end

function jeanne_curse:WeakCurse(target)
	target:AddNewModifier(self:GetCaster(), self, "modifier_jeanne_curse_weak", {duration = 0.5})
end

modifier_jeanne_curse_active = class({})

--[[function modifier_jeanne_curse_active:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE]	= true,
		[MODIFIER_STATE_DISARMED]		= true
	}
end]]

function modifier_jeanne_curse_active:OnCreated()
	if IsServer() then
		self.ability = self:GetAbility()
		self.caster = self.ability:GetCaster()
		self.parent = self:GetParent()
		self.damage = self.ability:GetSpecialValueFor("damage_per_second")
		self.duration_remaining = self.ability:GetSpecialValueFor("duration")
		local modifier = self.caster:FindModifierByName("modifier_jeanne_curse_buff")

		modifier:IncrementStackCount()
		modifier:IncrementStackCount()

		self:StartIntervalThink(1/4)
	end
end

function modifier_jeanne_curse_active:OnRefresh()
	if IsServer() then
		self.duration_remaining = self.ability:GetSpecialValueFor("duration")
	end
end

function modifier_jeanne_curse_active:OnDestroy()
	if IsServer() then
		local modifier = self.caster:FindModifierByName("modifier_jeanne_curse_buff")
		modifier:DecrementStackCount()
		modifier:DecrementStackCount()
	end
end

function modifier_jeanne_curse_active:OnIntervalThink()
	if IsServer() then
		--self.caster:Heal(self.damage/4, self.ability)
		self.duration_remaining = self.duration_remaining - 0.25
		--print(self.duration_remaining)
		DoDamage(self.caster, self.parent, self.damage/4, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	end
end

function modifier_jeanne_curse_active:IsHidden() return false end
function modifier_jeanne_curse_active:IsDebuff() return true end

function modifier_jeanne_curse_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		--MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_jeanne_curse_active:OnTakeDamage(args)
    if IsServer() then
        if args.unit ~= self:GetParent() then return end

        self.damage = self.damage + args.damage*self.ability:GetSpecialValueFor("damage_percent")/100
    end
end

function modifier_jeanne_curse_active:GetModifierMoveSpeedBonus_Percentage()
	return -1*self:GetAbility():GetSpecialValueFor("slow")
end

function modifier_jeanne_curse_active:GetModifierAttackSpeedBonus_Constant()
	return -1*self:GetAbility():GetSpecialValueFor("as_slow")
end

function modifier_jeanne_curse_active:GetEffectName()
	return "particles/jeanne_alter/bane_fiends_grip.vpcf"
end

function modifier_jeanne_curse_active:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end

modifier_jeanne_curse_weak = class({})

--[[function modifier_jeanne_curse_active:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE]	= true,
		[MODIFIER_STATE_DISARMED]		= true
	}
end]]

function modifier_jeanne_curse_weak:OnCreated()
	if IsServer() then
		self.ability = self:GetAbility()
		self.caster = self.ability:GetCaster()
		self.parent = self:GetParent()
		self.damage = self.ability:GetSpecialValueFor("damage_per_second")

		local modifier = self.caster:FindModifierByName("modifier_jeanne_curse_buff")

		modifier:IncrementStackCount()

		self:StartIntervalThink(1/4)
	end
end

function modifier_jeanne_curse_weak:OnRefresh()
end

function modifier_jeanne_curse_weak:OnDestroy()
	if IsServer() then
		local modifier = self.caster:FindModifierByName("modifier_jeanne_curse_buff")
		modifier:DecrementStackCount()
	end
end

function modifier_jeanne_curse_weak:OnIntervalThink()
	if IsServer() then
		--self.caster:Heal(self.damage/8, self.ability)
		DoDamage(self.caster, self.parent, self.damage/8, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
	end
end

function modifier_jeanne_curse_weak:GetEffectName()
	return "particles/jeanne_alter/bane_fiends_grip.vpcf"
end

function modifier_jeanne_curse_weak:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end

function modifier_jeanne_curse_weak:IsHidden() return false end
function modifier_jeanne_curse_weak:IsDebuff() return true end

function modifier_jeanne_curse_weak:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		--MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_jeanne_curse_weak:OnTakeDamage(args)
    if IsServer() then
        if args.unit ~= self:GetParent() then return end

        self.damage = self.damage + args.damage*self.ability:GetSpecialValueFor("damage_percent")/100
    end
end

function modifier_jeanne_curse_weak:GetModifierMoveSpeedBonus_Percentage()
	return -1*self:GetAbility():GetSpecialValueFor("slow")/2
end

function modifier_jeanne_curse_weak:GetModifierAttackSpeedBonus_Constant()
	return -1*self:GetAbility():GetSpecialValueFor("as_slow")/2
end

modifier_jeanne_curse_buff = class({})

function modifier_jeanne_curse_buff:IsHidden() return false end
function modifier_jeanne_curse_buff:IsDebuff() return false end
function modifier_jeanne_curse_buff:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_jeanne_curse_buff:IsPurgable() return false end
function modifier_jeanne_curse_buff:IsPurgeException() return false end
function modifier_jeanne_curse_buff:RemoveOnDeath() return false end
function modifier_jeanne_curse_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
	}
end

function modifier_jeanne_curse_buff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetStackCount()*self:GetAbility():GetSpecialValueFor("slow")/2
end

function modifier_jeanne_curse_buff:GetModifierAttackSpeedBonus_Constant()
	return self:GetStackCount()*self:GetAbility():GetSpecialValueFor("as_slow")/2
end

function modifier_jeanne_curse_buff:GetModifierConstantHealthRegen()
	return self:GetStackCount()*self:GetAbility():GetSpecialValueFor("damage_per_second")/2
end

function modifier_jeanne_curse_buff:GetTexture()
	return "custom/jeanne_alter/jeanne_curse"
end

--[[function modifier_jeanne_curse_buff:GetEffectName()
	return "particles/jeanne_alter/bane_fiends_grip.vpcf"
end

function modifier_jeanne_curse_buff:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end]]