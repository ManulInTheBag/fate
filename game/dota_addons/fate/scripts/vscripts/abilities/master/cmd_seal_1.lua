cmd_seal_1 = class({})
LinkLuaModifier("modifier_command_seal_1", "abilities/master/cmd_seal_1", LUA_MODIFIER_MOTION_NONE)

--[[
function cmd_seal_1:GetManaCost(iLevel)
	local caster = self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()
	 if(hero.ProsperityCount) then
		return 3 - hero.ProsperityCount
	 else
	 	return  3
	 end
end
]]
function cmd_seal_1:OnSpellStart()
	local caster =  self:GetCaster()
	local ply = caster:GetPlayerOwner()
	local hero = ply:GetAssignedHero()

	if caster:GetHealth() <= 2 then
		caster:SetMana(caster:GetMana()+self:GetManaCost(-1)) 
		self:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Master_Not_Enough_Health")
		return 
	end
	
	if not hero:IsAlive() or  ( IsRevoked(hero) and not hero:HasModifier("modifier_master_intervention")) then
		caster:SetMana(caster:GetMana()+self:GetManaCost(-1)) 
		self:EndCooldown() 
		SendErrorMessage(caster:GetPlayerOwnerID(), "#Revoked_Error")
		return
	end
	if(hero.ProsperityCount) then
		--caster:SetMana(caster:GetMana()+hero.ProsperityCount) 
	end
	if hero:GetName() == "npc_dota_hero_doom_bringer" and RandomInt(1, 100) <= 35 then
		EmitGlobalSound("Shiro_Onegai")
	end

	hero.ServStat:useQSeal()

	-- Set master 2's mana 
	local master2 = hero.MasterUnit2
	master2:SetMana(caster:GetMana())
	-- Set master's health
	caster:SetHealth(caster:GetHealth() - 1)

	-- Particle
	hero:EmitSound("Misc.CmdSeal")
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_elder_titan/elder_titan_ancestral_spirit_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 2, hero:GetAbsOrigin())

	hero:AddNewModifier(caster, self, "modifier_command_seal_1", { Duration = 10 })
	caster:AddNewModifier(caster, self, "modifier_command_seal_1", { Duration = 10 })
 	
 	self:EndCooldown()
 	self:StartCooldown( 60 - ( (hero.ProsperityCount or 0) * 15 ) )

	caster.IsFirstSeal = true
	
	Timers:CreateTimer({
		endTime = 10.0,
		callback = function()
		caster.IsFirstSeal = false
	end
	})
end


modifier_command_seal_1 = class({})

function modifier_command_seal_1:IsHidden()
	return false 
end

function modifier_command_seal_1:RemoveOnDeath()
	return false
end

function modifier_command_seal_1:IsDebuff()
	return false 
end

function modifier_command_seal_1:GetEffectName()
    return  "particles/custom/misc/cmd_seal_1_a.vpcf"
end
function modifier_command_seal_1:GetTexture()
    return  "custom/cmd_seal_1"
end