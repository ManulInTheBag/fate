-----------------------------
--    Avalon - The Sword and the Scabbard    --
-----------------------------

artoria_ultimate_avalon = class({})

LinkLuaModifier( "modifier_artoria_ultimate_avalon", "abilities/artoria/modifiers/modifier_artoria_ultimate_avalon", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_avalon_immunity", "abilities/artoria/modifiers/modifier_artoria_avalon_immunity", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_avalon_heal", "abilities/artoria/modifiers/modifier_artoria_avalon_heal", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_ultimate_shirou_avalon", "abilities/artoria/modifiers/modifier_artoria_ultimate_shirou_avalon", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_ultimate_avalon_cooldown", "abilities/artoria/modifiers/modifier_artoria_ultimate_avalon_cooldown", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_artoria_final_slash_window", "abilities/artoria/modifiers/modifier_artoria_final_slash_window", LUA_MODIFIER_MOTION_NONE )

function artoria_ultimate_avalon:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local CasterOrigin = caster:GetOrigin()
	
	return true
end

function artoria_ultimate_avalon:OnSpellStart()
	local caster = self:GetCaster()
	local targets = DOTA_UNIT_TARGET_HERO
	
	caster:RemoveModifierByName("modifier_artoria_ultimate_avalon_window")
	
	caster:AddNewModifier(caster, self, "modifier_artoria_ultimate_avalon_cooldown", { Duration = self:GetCooldown(1) })
	
	caster:AddNewModifier(caster, self, "modifier_artoria_ultimate_avalon", { Duration = self:GetSpecialValueFor("duration")})
	
	caster:AddNewModifier(caster, self, "modifier_artoria_avalon_immunity", { Duration = self:GetSpecialValueFor("duration")})
	
	-- Create linear projectile
	Timers:CreateTimer(7.00, function()
		if caster:IsAlive() then
			caster:AddNewModifier(caster, self, "modifier_artoria_final_slash_window", { Duration = self:GetSpecialValueFor("duration")})
		end
	end)
	
	local masterCombo2 = caster.MasterUnit2:FindAbilityByName("artoria_combo_2_proxy")
	masterCombo2:EndCooldown()
	masterCombo2:StartCooldown(self:GetCooldown(1))
	
	if caster:HasModifier("modifier_artoria_ultimate_avalon_attribute") then
		caster:AddNewModifier(caster, self, "modifier_artoria_avalon_heal", { Duration = self:GetSpecialValueFor("duration")})
	end
	
	caster:EmitSound("Hero_Omniknight.GuardianAngel.Cast")
	EmitGlobalSound("shirou_avalon")
	
		local allies = FindUnitsInRadius(
			self:GetCaster():GetTeamNumber(),	-- int, your team number
			caster:GetOrigin(),	-- point, center point
			nil,	-- handle, cacheUnit. (not known)
			FIND_UNITS_EVERYWHERE,	-- float, radius. or use FIND_UNITS_EVERYWHERE
			DOTA_UNIT_TARGET_TEAM_FRIENDLY,	-- int, team filter
			targets,	-- int, type filter
			0,	-- int, flag filter
			0,	-- int, order filter
			false	-- bool, can grow cache
		)
		
		for _,target in pairs(allies) do
			if target:GetUnitName() == "npc_dota_hero_ember_spirit" and target:IsAlive() then
				target:AddNewModifier(target, self, "modifier_artoria_ultimate_shirou_avalon", { Duration = self:GetSpecialValueFor("duration")})
				target:AddNewModifier(target, self, "modifier_artoria_avalon_immunity", { Duration = self:GetSpecialValueFor("duration")})
				
				if caster:HasModifier("modifier_artoria_avalon_attribute") then
					target:AddNewModifier(target, self, "modifier_artoria_avalon_heal", { Duration = self:GetSpecialValueFor("duration")})
				end
			end
		end
end