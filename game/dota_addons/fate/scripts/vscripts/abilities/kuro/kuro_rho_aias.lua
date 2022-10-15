kuro_rho_aias = class({})

LinkLuaModifier("modifier_rho_aias", "abilities/kuro/modifiers/modifier_rho_aias", LUA_MODIFIER_MOTION_NONE)

local rhoTarget = nil

function kuro_rho_aias:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if (filter == UF_SUCCESS) then
		if not self:GetCaster():HasModifier("modifier_projection_active") and not self:GetCaster():HasModifier("modifier_kuro_projection_overpower") then
			return UF_FAIL_CUSTOM
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end
function kuro_rho_aias:GetManaCost(iLevel)
	local caster = self:GetCaster()
	local manacostrecud = caster:FindAbilityByName("kuro_projection"):GetSpecialValueFor("manacost_reduction")
	local manacost = self:GetSpecialValueFor("manacost")
	if(manacost - manacostrecud *caster:GetModifierStackCount("modifier_projection_active",caster)  < 0 ) then
		return 0
	else
		return manacost - manacostrecud  *caster:GetModifierStackCount("modifier_projection_active",caster)
	end
end

function kuro_rho_aias:GetCustomCastErrorTarget(hTarget)
	return "#Cannot_Cast"
end

function kuro_rho_aias:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	if self:GetCaster():HasModifier("modifier_kuro_projection") then
		cooldown = cooldown - (cooldown * 35 / 100)
	end

	return cooldown
end

function kuro_rho_aias:OnSpellStart()
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	local hCaster = self:GetCaster()
	local ability = self
	local ply = caster:GetPlayerOwner()

	local close_ability = self:GetCaster():FindAbilityByName("kuro_spellbook_close")
	close_ability:OnSpellCalled(self)
	
	rhoTarget = target 
	target.rhoShieldAmount = self:GetSpecialValueFor("shield_amount")
	if hCaster:HasModifier("modifier_projection_active") then
		if hCaster:HasModifier("modifier_kuro_projection") then
			target.rhoShieldAmount = target.rhoShieldAmount + self:GetSpecialValueFor("projection_bonus")
		end
		if hCaster:HasModifier("modifier_projection_active") and not hCaster:HasModifier("modifier_kuro_projection_overpower") then
			if hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()>1 then		
				hCaster:FindModifierByName("modifier_projection_active"):SetStackCount(hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()-1)
			elseif not hCaster:HasModifier("modifier_kuro_projection_overpower") then
				hCaster:RemoveModifierByName("modifier_projection_active")
			end
		end
	end

	--local soundQueue = math.random(1,2)

	--[[if soundQueue == 1 then
		caster:EmitSound("Archer.RhoAias" ) 
	else
		caster:EmitSound("Emiya_Rho_Aias_Alt")
	end]]
	caster:EmitSound("Hero_EmberSpirit.FlameGuard.Cast")

	target:AddNewModifier(caster, self, "modifier_rho_aias", { Duration = self:GetSpecialValueFor("duration") })
end