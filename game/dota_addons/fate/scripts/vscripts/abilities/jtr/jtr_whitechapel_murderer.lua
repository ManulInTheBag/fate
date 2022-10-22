jtr_whitechapel_murderer = class({})

LinkLuaModifier("modifier_whitechapel_murderer", "abilities/jtr/modifiers/modifier_whitechapel_murderer", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_whitechapel_murderer_ally", "abilities/jtr/modifiers/modifier_whitechapel_murderer_ally", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_whitechapel_murderer_enemy", "abilities/jtr/modifiers/modifier_whitechapel_murderer_enemy", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_whitechapel_cooldown", "abilities/jtr/modifiers/modifier_whitechapel_cooldown", LUA_MODIFIER_MOTION_NONE)

function jtr_whitechapel_murderer:CastFilterResult()
	return UF_SUCCESS
end

function jtr_whitechapel_murderer:OnSpellStart()
	local caster = self:GetCaster()

    EmitGlobalSound("jtr_combo")
    LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="Swordland"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end) 
    

	caster:AddNewModifier(caster, self, "modifier_whitechapel_murderer", { Duration = self:GetSpecialValueFor("duration"),
																		   AgiBonus = self:GetSpecialValueFor("agi_bonus")
	})

    caster:AddNewModifier(caster, self, "modifier_whitechapel_cooldown", { Duration = self:GetCooldown(1) })

    local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))

	--[[LoopOverPlayers(function(player, playerID, playerHero)
        if playerHero:GetTeamNumber() ~= caster:GetTeamNumber() and playerHero:IsAlive() then
        	playerHero:AddNewModifier(caster, self, "modifier_whitechapel_murderer_enemy", { Duration = self:GetSpecialValueFor("duration") })
        elseif playerHero:GetTeamNumber() == caster:GetTeamNumber() and playerHero:IsAlive() and playerHero ~= self:GetCaster() then
        	playerHero:AddNewModifier(caster, self, "modifier_whitechapel_murderer_ally", { Duration = self:GetSpecialValueFor("duration") })
        end
     end)]]
end

function jtr_whitechapel_murderer:EndCombo()
	LoopOverPlayers(function(player, playerID, playerHero)        
        playerHero:RemoveModifierByName("modifier_whitechapel_murderer_ally")
        playerHero:RemoveModifierByName("modifier_whitechapel_murderer_enemy")        
    end)
end