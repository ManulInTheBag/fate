lishuwen_presence_concealment = class({})

LinkLuaModifier("modifier_pc_invis", "abilities/lishuwen/modifiers/modifier_pc_invis", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pc_nss_cooldown_recovery", "abilities/lishuwen/modifiers/modifier_pc_nss_cooldown_recovery", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_li_shuwen_idle_animation", "abilities/lishuwen/lishuwen_presence_concealment", LUA_MODIFIER_MOTION_NONE)
function lishuwen_presence_concealment:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	StartAnimation(caster, {duration=1, activity=ACT_DOTA_ALCHEMIST_CHEMICAL_RAGE_START, rate=1})
end

function lishuwen_presence_concealment:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    EndAnimation(caster)
end

function lishuwen_presence_concealment:GetIntrinsicModifierName()
	return "modifier_li_shuwen_idle_animation"
end
modifier_li_shuwen_idle_animation = class({})
function modifier_li_shuwen_idle_animation:OnCreated(args)
    self.activity = "not_in_fight"
	self:StartIntervalThink(0.5)
end
function modifier_li_shuwen_idle_animation:OnIntervalThink()
	if self:GetRemainingTime() < 0.5 then
		self.activity = "not_in_fight"
	end
end
function modifier_li_shuwen_idle_animation:OnTakeDamage(args)
	if args.unit ~= self:GetParent() then return end
 	self.activity = "in_fight"
	self:SetDuration(4, true)
end
function modifier_li_shuwen_idle_animation:OnAttackLanded(args)
    if args.attacker ~= self:GetParent() then return end
    self.activity = "in_fight"
	self:SetDuration(4, true)
end

function modifier_li_shuwen_idle_animation:IsHidden() return true end
function modifier_li_shuwen_idle_animation:IsDebuff() return false end
function modifier_li_shuwen_idle_animation:IsPurgable() return false end
function modifier_li_shuwen_idle_animation:IsPurgeException() return false end
function modifier_li_shuwen_idle_animation:DestroyOnExpire() return false end
function modifier_li_shuwen_idle_animation:RemoveOnDeath() return false end

function modifier_li_shuwen_idle_animation:DeclareFunctions()
    local func = {    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS}
    return func
end

function modifier_li_shuwen_idle_animation:GetActivityTranslationModifiers()
	return self.activity
end



function lishuwen_presence_concealment:GetTexture()
	return "custom/lishuwen_presence_concealment"
end

function lishuwen_presence_concealment:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	EmitZlodemonTrueSound("moskes_li_q",caster)
	ProjectileManager:ProjectileDodge(caster)

	local stopOrder = {
		UnitIndex = caster:entindex(),
		OrderType = DOTA_UNIT_ORDER_HOLD_POSITION
	}
	ExecuteOrderFromTable(stopOrder) 
	caster:EmitSound("Hero_PhantomLancer.Doppelwalk")
	
	caster:AddNewModifier(caster, ability, "modifier_pc_invis", { BreakDelay = self:GetSpecialValueFor("break_delay"),
																HealthRegenPct = self:GetSpecialValueFor("health_regen"),
																ManaRegenPct = self:GetSpecialValueFor("mana_regen"),
																BonusDamage = self:GetSpecialValueFor("bonus_damage"), 
																AttackBuffDuration = self:GetSpecialValueFor("atk_buff_duration"),
																AttackCount = self:GetSpecialValueFor("number_attacks")})

	if caster.bIsMartialArtsImproved then
		caster:AddNewModifier(caster, ability, "modifier_pc_nss_cooldown_recovery", {})
	end
	self:CheckCombo()
end

function lishuwen_presence_concealment:CheckCombo()
	local caster = self:GetCaster()
	local ability = self
	if caster:GetStrength() >= 29.1 and caster:GetAgility() >= 29.1 and caster:GetIntellect() >= 29.1 then      
    	if caster:FindAbilityByName("lishuwen_raging_dragon_strike"):IsCooldownReady() 
    		and caster:FindAbilityByName("lishuwen_tiger_strike"):IsCooldownReady() 
    		and not caster:HasModifier("modifier_tiger_strike_tracker") then

    		caster:SwapAbilities("lishuwen_combo_trigger", "lishuwen_presence_concealment", true, false)

    		Timers:CreateTimer('dragon_trigger_window',{
		        endTime = 2,
		        callback = function()
		        if caster:GetAbilityByIndex(0):GetName() ~= "lishuwen_presence_concealment" then
		       		caster:SwapAbilities("lishuwen_combo_trigger", "lishuwen_presence_concealment", false, true)
		       	end
		    end
		    })


    		--[[if not caster:HasModifier("modifier_lishuwen_combo_seq") then
    			caster:AddNewModifier(caster, self, "modifier_lishuwen_combo_seq", {Duration = 5})
    			self:EndCooldown()
    			caster:GiveMana(self:GetManaCost(self:GetLevel()))
    			return false
    		end]]

    		
            --return true
        end
    end

    --return false
end