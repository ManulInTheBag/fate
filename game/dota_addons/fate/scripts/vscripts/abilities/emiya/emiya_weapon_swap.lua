local emiyaSkillsTable =   {
                    --1
                    {   
                        ["i_current_weapon_index"]    = 1, ---maybe i shoud have started with 0... dont care now  
                        ["model"] = "models/emiya/emiya.vmdl",                     ----tried swapping models but its really annoying when trying to make nice animations.
                        ["s_current_weapon_sound"]    = "Hero_juggernaut.Attack",  ----Using SetBodyGroup instead. Not using it here since overedge is a buff, not stance   
						["i_attack_capability"] = 1,
                        ["h_abilities_list"] = 
                        {
                            "emiya_kanshou_byakuya",
                            "emiya_double_slash",
                            "emiya_crane_wings",
                            "emiya_rho_aias",

                            "emiya_weapon_swap", 

                            "emiya_unlimited_bladeworks"
                        }
                    },
                    --2
                    {
                        ["i_current_weapon_index"]    = 2,
                        ["model"] = "models/emiya/emiya.vmdl",
                        ["s_current_weapon_sound"]    = "Hero_DrowRanger.Attack",
						["i_attack_capability"] = 2,
                        ["h_abilities_list"] = 
                        {
                            "emiya_arrows", 
                            "emiya_change",
                            "emiya_caladbolg",
                            "emiya_clairvoyance",

                            "emiya_weapon_swap", 

                            "emiya_unlimited_bladeworks"  
                        }
                    },
                    --3
                    {
                        ["i_current_weapon_index"]    = 3,
                        ["model"] = "models/emiya/emiya.vmdl",
                        ["s_current_weapon_sound"]    = "",
						["i_attack_capability"] = 2,
                        ["h_abilities_list"] = 
                        {   
                            "emiya_barrage_moonwalk",
                            "emiya_big_swords",
                            "emiya_gae_bolg",
                            "emiya_rho_aias",

                            "emiya_barrage_rain", 

                            "emiya_nine_lives"
                        }
                    }
                }


emiya_weapon_swap = emiya_weapon_swap or class({})

function emiya_weapon_swap:GetAbilityTextureName()
	local caster = self:GetCaster()
     return "custom/emiya_form"..caster:GetModifierStackCount("modifier_emiya_weapon_swap", caster) 
end

function emiya_weapon_swap:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local form = caster:GetModifierStackCount("modifier_emiya_weapon_swap", caster) 
    if(form == 1) then
        StartAnimation(caster, {duration= 0.2 , activity=ACT_DOTA_CAST_ABILITY_5, rate= 1}) ----this shit is so bad because i wanted SMOOTH transitions mid-animations
	    Timers:CreateTimer("swap_model_1", {
		    endTime = 0.1,
		    callback = function()
		    caster:SetBodygroup(0,1)
	    end})

        Timers:CreateTimer("swap_model_2", {
		    endTime = 0.2,
		    callback = function()
		    caster:SetBodygroup(0,2)
	    end})

    elseif(form == 2) then
        StartAnimation(caster, {duration= 0.24 , activity=ACT_DOTA_CAST_ABILITY_ROT, rate= 1})
        Timers:CreateTimer("swap_model_1", {
		    endTime = 0.12,
		    callback = function()
		    caster:SetBodygroup(0,1)
	    end})

        Timers:CreateTimer("swap_model_2", {
		    endTime = 0.24,
		    callback = function()
		    caster:SetBodygroup(0,0)
	    end})


    end
 
return
end

function emiya_weapon_swap:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
    local form = caster:GetModifierStackCount("modifier_emiya_weapon_swap", caster) 
    EndAnimation(caster)
    if(form == 1) then
        if(caster:HasModifier("emiya_overedge_modifier")) then
            caster:SetBodygroup(0,3) --- 0 - swords, 1 bow, 2 ubw, 3 overedge
        else
            caster:SetBodygroup(0,0)
        end
        

    elseif (form == 2) then
        caster:SetBodygroup(0,2)

    end
	
	Timers:RemoveTimer("swap_model_1")
	Timers:RemoveTimer("swap_model_2")
end

 
function emiya_weapon_swap:IsStealable()                                  return false end
function emiya_weapon_swap:IsHiddenWhenStolen()                           return false end
function emiya_weapon_swap:IsLearned()                                    return true end
function emiya_weapon_swap:GetIntrinsicModifierName()
    return "modifier_emiya_weapon_swap"
end

function emiya_weapon_swap:SwapWeapons(iNewNumber)
    local hCaster = self:GetCaster()

    if(hCaster:HasModifier("emiya_overedge_modifier")) then
        hCaster.overedgeFastFix = 1 ---nasral
        hCaster:RemoveModifierByNameAndCaster("emiya_overedge_modifier",hCaster)
    end


    local hGLOBAL  = emiyaSkillsTable
	local iCurrentNum = hCaster:GetModifierStackCount("modifier_emiya_weapon_swap", hCaster)
    local hCURRENT = emiyaSkillsTable[iCurrentNum]

    local hAbilitySetup1 = hCURRENT
	hAbilitySetup2 = hGLOBAL[iNewNumber]

   
	 
		for i = 1, 6 do
			local sAbilityName1 = hCaster:GetAbilityByIndex(i - 1)
				  sAbilityName1 = IsNotNull(sAbilityName1)
								  and sAbilityName1:GetAbilityName()
								  or hAbilitySetup1["h_abilities_list"][i]
	
			local sAbilityName2 = hAbilitySetup2["h_abilities_list"][i]
	
			hCaster:SwapAbilities(sAbilityName1, sAbilityName2, false, true)
		end
	
	 
	  
	
		local hSkillsData = emiyaSkillsTable[iNewNumber]
		hCaster:AddNewModifier(hCaster, self, "modifier_emiya_weapon_swap",    {  
																							iWeaponIndex      = hSkillsData["i_current_weapon_index"],
																							--model= hSkillsData["model"],
																							sSoundModifier  = hSkillsData["s_current_weapon_sound"],
																							iAttackCapability = hSkillsData["i_attack_capability"]
	
																						})

	--StartAnimation(hCaster, {duration= 0.3 , activity=ACT_DOTA_CAST_ABILITY_4_END, rate= 1})																			
   
    

end

function emiya_weapon_swap:OnSpellStart()
    local hCaster = self:GetCaster()
	local iCurrentNum = hCaster:GetModifierStackCount("modifier_emiya_weapon_swap", hCaster)
    local iNewNumber
    if(iCurrentNum == 1) then
		iNewNumber = 2
	else
		iNewNumber = 1
	end
    self:SwapWeapons(iNewNumber)
end




LinkLuaModifier("modifier_emiya_weapon_swap", "abilities/emiya/emiya_weapon_swap", LUA_MODIFIER_MOTION_NONE)

modifier_emiya_weapon_swap = modifier_emiya_weapon_swap or class({})

function modifier_emiya_weapon_swap:IsHidden()                                                             return true end
function modifier_emiya_weapon_swap:IsDebuff()                                                             return false end
function modifier_emiya_weapon_swap:IsPurgable()                                                           return false end
function modifier_emiya_weapon_swap:IsPurgeException()                                                     return false end
function modifier_emiya_weapon_swap:RemoveOnDeath()                                                        return false end
function modifier_emiya_weapon_swap:GetAttributes()                                                        return MODIFIER_ATTRIBUTE_PERMANENT  end
function modifier_emiya_weapon_swap:GetPriority()                                                          return MODIFIER_PRIORITY_ULTRA end
function modifier_emiya_weapon_swap:DeclareFunctions()
    local hFunc =   {
                        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
                        MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
						--MODIFIER_PROPERTY_MODEL_CHANGE,
						MODIFIER_PROPERTY_ATTACK_RANGE_BASE_OVERRIDE,
						MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
						   
                    }
    return hFunc
end
function modifier_emiya_weapon_swap:GetModifierProjectileSpeedBonus()
	return 800
end
function modifier_emiya_weapon_swap:GetModifierAttackRangeOverride()
	return self.iAttack_range
end
function modifier_emiya_weapon_swap:GetActivityTranslationModifiers(keys)
    return self.__sActivityModifier
end
--[[
function modifier_emiya_weapon_swap:GetModifierModelChange(keys)
    return self.__model
end
]]
function modifier_emiya_weapon_swap:GetAttackSound(keys)
    return self.__sSoundModifier
end

function modifier_emiya_weapon_swap:OnCreated(hTable)
    self.hCaster  = self:GetCaster()
    self.hParent  = self:GetParent()
    self.hAbility = self:GetAbility()
    
    if IsServer()
        and IsNotNull(self.hParent) then
        self.__sSoundModifier    = hTable.sSoundModifier or self.__sSoundModifier or emiyaSkillsTable[1]["s_current_weapon_sound"]
		--self.__model = hTable.model or self.__model or emiyaSkillsTable[1]["model"]
		self.iWeaponIndex = hTable.iWeaponIndex or self.iWeaponIndex or 1
        self.__sActivityModifier = tostring(self.iWeaponIndex) or 1
        self.iAttack_capability = hTable.iAttackCapability or self.iAttack_capability or 1
        self:SetStackCount( self.iWeaponIndex ) 
		self.hParent:SetAttackCapability(self.iAttack_capability)
		if(	self.iWeaponIndex == 1) then
			self.iAttack_range = self.hAbility:GetSpecialValueFor("melee_range")
            if(self.hCaster:HasModifier("emiya_overedge_modifier")) then
                self.iAttack_range = self.hAbility:GetSpecialValueFor("melee_range_overedge")
            end
		elseif(	self.iWeaponIndex == 2) then
			self.iAttack_range = self.hAbility:GetSpecialValueFor("bow_range")
			self.hCaster:SetRangedProjectileName("particles/emiya/arrows_base.vpcf") ---didnt tested if i actually need to set it everytime, but dont care lol :trollge:  
		elseif(	self.iWeaponIndex == 3) then
			self.iAttack_range = self.hAbility:GetSpecialValueFor("ubw_range")
			self.hCaster:SetRangedProjectileName(nil) ---didnt tested if i actually need to set it everytime, but dont care lol :trollge:  
		end
    end
end
function modifier_emiya_weapon_swap:OnRefresh(hTable)
    self:OnCreated(hTable)
end

