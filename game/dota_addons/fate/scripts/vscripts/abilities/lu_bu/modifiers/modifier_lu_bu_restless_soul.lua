modifier_lu_bu_restless_soul = class({})



LinkLuaModifier("modifier_lu_bu_restless_soul_active", "abilities/lu_bu/modifiers/modifier_lu_bu_restless_soul_active", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lu_bu_restless_soul_bkb", "abilities/lu_bu/modifiers/modifier_lu_bu_restless_soul_bkb", LUA_MODIFIER_MOTION_NONE)

function modifier_lu_bu_restless_soul:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

if IsServer() then
	function modifier_lu_bu_restless_soul:OnTakeDamage(args)
		if args.unit ~= self:GetParent() then return end
		local ability = self:GetAbility()
		local caster = self:GetParent()


		if args.damage < 99999 
			and caster:GetHealth() <= 0 
			and not caster:HasModifier("modifier_lu_bu_restless_soul_cooldown") 
			and IsRevivePossible(caster)
			and not caster:HasModifier("round_pause")
			then
			
			local passive_heal = self:GetAbility():GetSpecialValueFor("passive_heal")

			caster:SetHealth(passive_heal)
			
			HardCleanse(caster)
			caster:EmitSound("lu_bu_bc")
			caster:AddNewModifier(caster, ability, "modifier_lu_bu_restless_soul_active", { Duration = 0 })
		end
	end
end

function modifier_lu_bu_restless_soul:OnProjectileThink(vLocation)
	--[[print("thonkang")

	if IsValidEntity(self.NailDummy) then		
		self.NailDummy:SetAbsOrigin(GetGroundPosition(vLocation, nil))
	end	]]

	--self:SyncFx(vLocation)
end

function modifier_lu_bu_restless_soul:IsHidden()
	return false
end