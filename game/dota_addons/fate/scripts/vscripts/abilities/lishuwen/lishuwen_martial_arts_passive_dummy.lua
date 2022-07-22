lishuwen_martial_arts_passive_dummy = class({})

LinkLuaModifier("modifier_martial_arts_passive", "abilities/lishuwen/modifiers/modifier_martial_arts_passive", LUA_MODIFIER_MOTION_NONE)

function lishuwen_martial_arts_passive_dummy:GetTexture()
	return "custom/lishuwen_attribute_improve_martial_arts"
end

function lishuwen_martial_arts_passive_dummy:GrantMartialArts()
	local caster = self:GetCaster()

	if caster.bIsMartialArtsImproved == true then
		Timers:CreateTimer(function()
			if caster:IsAlive() then 
				caster:AddNewModifier(caster, self, "modifier_martial_arts_passive", { ManaBurnAmount = self:GetSpecialValueFor("mana_burn_amount")})
				return nil
			else
				return 1
			end
		end)
	end
	--[[if not caster:HasModifier("modifier_martial_arts_passive") and caster.bIsMartialArtsImproved then
		caster:AddNewModifier(caster, self, "modifier_martial_arts_passive", { ManaBurnAmount = self:GetSpecialValueFor("mana_burn_amount")})
	else
		return
	end]]
end

function lishuwen_martial_arts_passive_dummy:OnUpgrade()
	self:GrantMartialArts()
end

function lishuwen_martial_arts_passive_dummy:OnRespawn()
	self:GrantMartialArts()
end