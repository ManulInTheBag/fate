LinkLuaModifier("modifier_khsn_mde", "abilities/kinghassan/khsn_mde", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_mde_active", "abilities/kinghassan/khsn_mde", LUA_MODIFIER_MOTION_NONE)

khsn_mde = class({})

function khsn_mde:GetIntrinsicModifierName() return "modifier_khsn_mde" end
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
		
		self:StartIntervalThink(0.25)
		self:OnIntervalThink()

		self.fRegenHP = self:GetAbility():GetSpecialValueFor("hp_regen")
		self.fArmor   = self:GetAbility():GetSpecialValueFor("bonus_armor")

		--[[if self.parent:HasModifier("modifier_khsn_bk_improved") then
			self.fRegenHP = self.fRegenHP + 40
			self.fArmor   = self.fArmor + 25
		end]]

		--[[if self.parent:GetAbilityByIndex(1):GetName() ~= "khsn_mde_end" then
			self.parent:SwapAbilities("khsn_mde", "khsn_mde_end", false, true)
		end]]
	end
end
function modifier_khsn_mde_active:OnRefresh(tTable)
	self:OnCreated(tTable)
end
function modifier_khsn_mde_active:OnDestroy()
	--[[if self.parent:GetAbilityByIndex(1):GetName() ~= "khsn_mde" then
		self.parent:SwapAbilities("khsn_mde", "khsn_mde_end", true, false)
	end]]
end

function modifier_khsn_mde_active:OnIntervalThink()
	if IsServer() then
		local enemies2 = FindUnitsInRadius(  self.parent:GetTeamNumber(),
	                                            self.parent:GetAbsOrigin(), 
	                                            nil, 
	                                            self:GetAbility():GetSpecialValueFor("attr_radius"), 
	                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
	                                            DOTA_UNIT_TARGET_HERO, 
	                                            0, 
	                                            FIND_ANY_ORDER, 
	                                            false)
		for _,enemy in ipairs(enemies2) do
			DoDamage(self.parent, enemy, self:GetAbility():GetSpecialValueFor("dps")/4, self.parent.PresenceAcquired and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
			self.parent:Heal(self:GetAbility():GetSpecialValueFor("dps")/4, self.parent)
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





LinkLuaModifier("modifier_khsn_bk_improved", "abilities/kinghassan/khsn_mde", LUA_MODIFIER_MOTION_NONE)

modifier_khsn_bk_improved = modifier_khsn_bk_improved or class({})

function modifier_khsn_bk_improved:IsHidden() return true end
function modifier_khsn_bk_improved:RemoveOnDeath() return false end
function modifier_khsn_bk_improved:IsPurgable() return false end
function modifier_khsn_bk_improved:IsPurgeException() return false end


LinkLuaModifier("modifier_khsn_bc_active", "abilities/kinghassan/khsn_mde", LUA_MODIFIER_MOTION_NONE)

modifier_khsn_bc_active = modifier_khsn_bc_active or class(modifier_khsn_mde_active)