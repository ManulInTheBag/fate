LinkLuaModifier("modifier_khsn_mde", "abilities/kinghassan/khsn_mde", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_mde_active", "abilities/kinghassan/khsn_mde", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_mde_enemy", "abilities/kinghassan/khsn_mde", LUA_MODIFIER_MOTION_NONE)

khsn_mde = class({})

function khsn_mde:GetIntrinsicModifierName() return "modifier_khsn_mde" end

function khsn_mde:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("khsn_azrael"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("khsn_azrael"):SetLevel(self:GetLevel())
    end
end

function khsn_mde:OnSpellStart()
	local caster = self:GetCaster()
	LoopOverPlayers(function(player, playerID, playerHero)
		--print("looping through " .. playerHero:GetName())
		if playerHero.zlodemon == true   then
			-- apply legion horn vsnd on their client
			CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_kh_w" })
			--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
		end
	end)
	if caster.BattleContinuationAcquired then
		caster:AddNewModifier(caster, self, "modifier_khsn_bk_improved", {})
	end

	caster:AddNewModifier(caster, self, "modifier_khsn_mde_active", {duration = self:GetSpecialValueFor("duration")})
	caster:EmitSound("Hero_Necrolyte.SpiritForm.Cast")
	--caster:Heal(self:GetSpecialValueFor("heal"), caster)
	
end

khsn_mde_end = class({})

function khsn_mde_end:OnSpellStart()--combo is now on Q
	local caster = self:GetCaster()
	caster:SwapAbilities("khsn_azrael", "khsn_combo", false, true)
	caster:SwapAbilities("khsn_mde_end", "khsn_ambush", false, true)
	Timers:CreateTimer(3, function()
		caster:SwapAbilities("khsn_azrael", "khsn_combo", true, false)
	end)
end

modifier_khsn_mde = class({})

function modifier_khsn_mde:IsHidden() 
	return true
end

function modifier_khsn_mde:IsPermanent()
	return true
end

function modifier_khsn_mde:RemoveOnDeath()
	return false
end

function modifier_khsn_mde:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_khsn_mde:OnCreated()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
end

function modifier_khsn_mde:DeclareFunctions()
	return {	--MODIFIER_EVENT_ON_ATTACK_LANDED
		}
end

function modifier_khsn_mde:OnAttackLanded(args)
	if args.attacker ~= self.parent then return end

	local attacker = args.attacker
	local target = args.target
	local damage = self.ability:GetSpecialValueFor("damage_percent")/100*target:GetMaxHealth()

	DoDamage(self.parent, target, damage, self.parent.BoundaryAcquired and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
end











modifier_khsn_mde_active = modifier_khsn_mde_active or class({})

--[[function modifier_khsn_mde_active:CheckState()
	return {
		[MODIFIER_STATE_ATTACK_IMMUNE]	= true,
		[MODIFIER_STATE_DISARMED]		= true
	}
end]]

function modifier_khsn_mde_active:OnCreated()
	if IsServer() then
		self.parent = self:GetParent()
		self.ability = self:GetAbility()

		self.radius = self.ability:GetSpecialValueFor("radius")
		
		self:StartIntervalThink(FrameTime())
		self:OnIntervalThink()

		self.fRegenHP = self.ability:GetSpecialValueFor("hp_regen")
		self.fArmor   = self.ability:GetSpecialValueFor("bonus_armor")

		self.fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_shroud/khsn_shroud.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
		ParticleManager:SetParticleControl(self.fx, 1, Vector(self.radius, 0, 0))

		self:AddParticle(self.fx, false, false, -1, false, false)

		if self.parent:GetAbilityByIndex(1):GetName() ~= "khsn_azrael" then
			self.parent:SwapAbilities("khsn_mde", "khsn_azrael", false, true)
		end
	end
end
function modifier_khsn_mde_active:OnRefresh(tTable)
end
function modifier_khsn_mde_active:OnDestroy()
	if not IsServer() then return end
	if self.parent:GetAbilityByIndex(1):GetName() ~= "khsn_mde" then
		self.parent:SwapAbilities("khsn_mde", "khsn_azrael", true, false)
	end

	local abi = self.parent:FindAbilityByName("khsn_mde")

	abi:StartCooldown(abi:GetCooldown(-1))
end

function modifier_khsn_mde_active:OnIntervalThink()
	if IsServer() then
		local enemies2 = FindUnitsInRadius(  self.parent:GetTeamNumber(),
	                                            self.parent:GetAbsOrigin(), 
	                                            nil, 
	                                            self.radius, 
	                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
	                                            DOTA_UNIT_TARGET_HERO, 
	                                            0, 
	                                            FIND_ANY_ORDER, 
	                                            false)
		for _,enemy in ipairs(enemies2) do
			enemy:AddNewModifier(self.parent, self.ability, "modifier_khsn_mde_enemy", {duration = 0.1})
			--[[DoDamage(self.parent, enemy, self:GetAbility():GetSpecialValueFor("dps")/4, self.parent.PresenceAcquired and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
			self.parent:Heal(self:GetAbility():GetSpecialValueFor("dps")/4, self.parent)]]
	    end
	end
end

function modifier_khsn_mde_active:IsHidden() return false end
function modifier_khsn_mde_active:IsDebuff() return false end
function modifier_khsn_mde_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		--MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		--MODIFIER_PROPERTY_OVERRIDE_ANIMATION
	}
end

--[[function modifier_khsn_mde_active:GetOverrideAnimation()
    return ACT_DOTA_CAST_ABILITY_2
end]]

function modifier_khsn_mde_active:GetModifierPhysicalArmorBonus()
	return self.fArmor
end

function modifier_khsn_mde_active:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("ms_bonus")
end

--[[function modifier_khsn_mde_active:GetAbsoluteNoDamagePhysical()
	return 1
end]]
function modifier_khsn_mde_active:GetEffectName()
	return "particles/kinghassan/pugna_decrepify.vpcf"
end

function modifier_khsn_mde_active:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end



modifier_khsn_mde_enemy = modifier_khsn_mde_enemy or class({})

function modifier_khsn_mde_enemy:DeclareFunctions()
    return { MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
    		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
end

function modifier_khsn_mde_enemy:GetModifierHealAmplify_PercentageTarget()
	if self:GetCaster():HasModifier("modifier_khsn_presence_attribute") then
		return -1*self:GetAbility():GetSpecialValueFor("attribute_heal_reduction")
	end
	return 0
end

function modifier_khsn_mde_enemy:GetModifierHPRegenAmplify_Percentage()
	if self:GetCaster():HasModifier("modifier_khsn_presence_attribute") then
		return -1*self:GetAbility():GetSpecialValueFor("attribute_heal_reduction")
	end
	return 0
end

function modifier_khsn_mde_enemy:GetModifierTotalDamageOutgoing_Percentage()
	if(self:GetCaster().PresenceAcquired == true) then
		return -1*self:GetAbility():GetSpecialValueFor("attribute_damage_reduction")
	end
	return 0
end

function modifier_khsn_mde_enemy:GetModifierProvidesFOWVision()
    return 1
end

function modifier_khsn_mde_enemy:IsHidden()
    return false
end

function modifier_khsn_mde_enemy:IsDebuff()
    return true
end

function modifier_khsn_mde_enemy:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()
	self.radius = self.ability:GetSpecialValueFor("radius")
	self.linger_duration = self.ability:GetSpecialValueFor("linger_duration")

	self.timer = 0

	self.fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_siphon.vpcf", PATTACH_ABSORIGIN, self.caster)
	self.attach_caster = self.caster:ScriptLookupAttachment("maw")
	self.attach_parent = self.parent:ScriptLookupAttachment("attach_hitloc")
	ParticleManager:SetParticleControl(self.fx, 0, self.caster:GetAttachmentOrigin(self.attach_caster))
	ParticleManager:SetParticleControl(self.fx, 1, self.parent:GetAttachmentOrigin(self.attach_parent))

	self:AddParticle(self.fx, false, false, -1, false, false)

	self:StartIntervalThink(FrameTime())
end

function modifier_khsn_mde_enemy:OnRefresh()
end

function modifier_khsn_mde_enemy:OnIntervalThink()
	if not IsServer() then return end

	ParticleManager:SetParticleControl(self.fx, 0, self.caster:GetAttachmentOrigin(self.attach_caster))
	ParticleManager:SetParticleControl(self.fx, 1, self.parent:GetAttachmentOrigin(self.attach_parent))

	self.timer = self.timer + FrameTime()
	if self.timer >= 0.1 then
		self.timer = 0

		if ((self.caster:GetAbsOrigin() - self.parent:GetAbsOrigin()):Length2D() > self.radius) or (not self.caster:IsAlive() or not (self.caster:HasModifier("modifier_khsn_mde_active"))) then
			self:Destroy()
			return
		end

		local damage = self.ability:GetSpecialValueFor("dps")
		local heal = self.ability:GetSpecialValueFor("heal")

		DoDamage(self.caster, self.parent, damage/10, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
		self.caster:Heal(heal/10, self.caster)

		if self.parent:IsHero() then
			if self.caster.PresenceAcquired then
				self.caster:AddNewModifier(self.caster, self.ability, "modifier_khsn_mde_active", {duration = self.linger_duration})
			end
		end
	end
end


LinkLuaModifier("modifier_khsn_bk_improved", "abilities/kinghassan/khsn_mde", LUA_MODIFIER_MOTION_NONE)

modifier_khsn_bk_improved = modifier_khsn_bk_improved or class({})

function modifier_khsn_bk_improved:IsHidden() return true end
function modifier_khsn_bk_improved:RemoveOnDeath() return false end
function modifier_khsn_bk_improved:IsPurgable() return false end
function modifier_khsn_bk_improved:IsPurgeException() return false end


LinkLuaModifier("modifier_khsn_bc_active", "abilities/kinghassan/khsn_mde", LUA_MODIFIER_MOTION_NONE)

modifier_khsn_bc_active = modifier_khsn_bc_active or class(modifier_khsn_mde_active)