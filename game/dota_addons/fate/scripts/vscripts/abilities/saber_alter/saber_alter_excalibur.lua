-- saber_alter_excalibur — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/saber_alter/saber_alter_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

saber_alter_excalibur = class({})

LinkLuaModifier("dark_excalibur_VFX_controller", "abilities/saber_alter/saber_alter_excalibur", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("dark_excalibur_vfx_phase_1", "abilities/saber_alter/saber_alter_excalibur", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("dark_excalibur_vfx_phase_2", "abilities/saber_alter/saber_alter_excalibur", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("dark_excalibur_vfx_phase_3", "abilities/saber_alter/saber_alter_excalibur", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/saber_alter_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnDexStart, OnDexHit, OnDexVfxControllerStart, OnDexVfxPhase2Start

OnDexStart = function(keys)

	local caster = keys.caster

	local ability = keys.ability 

	--caster:AddNewModifier(caster, ability, "modifier_merlin_self_pause", {Duration = 3}) 

	giveUnitDataDrivenModifier(keys.caster, keys.caster, "pause_sealdisabled", 3)

	keys.Range = keys.Range - keys.Width -- We need this to take end radius of projectile into account

	--print(keys.Range)

	local range = keys.Range

	local width = keys.Width

	if caster:HasModifier("modifier_hero_selection_skin") then

		--caster:AddNewModifier(caster, nil, "modifier_salter_model_swap_jopa", {duration = 3.0})

		caster:SetBodygroup(0, 1)

	end

	EmitGlobalSound("Saber.Caliburn")

	--EmitGlobalSound("Excalibur_Morgan_Precast")

	caster:AddNewModifier(caster, ability, "dark_excalibur_VFX_controller", {})

	StartAnimation(caster, {duration = 3, activity = ACT_DOTA_CAST_ABILITY_4, rate = 1.35})

	local dex = 

	{

		Ability = keys.ability,

        EffectName = "",

        iMoveSpeed = keys.Speed,

        vSpawnOrigin = nil,

        fDistance = keys.Range,

        fStartRadius = keys.Width,

        fEndRadius = keys.Width,

        Source = caster,

        bHasFrontalCone = true,

        bReplaceExisting = false,

        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,

        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,

        iUnitTargetType = DOTA_UNIT_TARGET_ALL,

        fExpireTime = GameRules:GetGameTime() + 5.0,

		bDeleteOnHit = false,

		vVelocity = caster:GetForwardVector() * keys.Speed

	}	



	Timers:CreateTimer(0, function() 

		if caster:IsAlive() then

			EmitGlobalSound("Excalibur_Morgan")

		end

	end)



	Timers:CreateTimer(2, function()

		if caster:IsAlive() then

			dex.vSpawnOrigin = caster:GetAbsOrigin() 

			dex.vVelocity = caster:GetForwardVector() * keys.Speed/0.3

			

			local counter = 10

			Timers:CreateTimer(0, function()        

            counter = counter -1

            if not caster:IsAlive() then return end

            local projectile = ProjectileManager:CreateLinearProjectile(dex)

            	if(counter == 0) then

					if caster:HasModifier("modifier_hero_selection_skin") then

						--caster:AddNewModifier(caster, nil, "modifier_salter_model_swap_jopa", {duration = 3.0})

						Timers:CreateTimer(0.2, function() 

							caster:SetBodygroup(0, 0)

						end)

					end

                return  

            	end

            return 0.08

        	end)

			ScreenShake(caster:GetOrigin(), 5, 0.1, 2, 20000, 0, true)

			AddFOWViewer(2,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100, 10, 1, false)

    		AddFOWViewer(3,Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100, 10, 1, false)

			local excalFxIndex = ParticleManager:CreateParticle("particles/saber_alter/saber_alter_excalibur_beam.vpcf", PATTACH_ABSORIGIN, caster)

			local pepega_end = GetGroundPosition(caster:GetAbsOrigin() + caster:GetForwardVector()*(range + width-100), caster)

			local pepega_vec = (pepega_end - caster:GetAbsOrigin()):Normalized()

   			ParticleManager:SetParticleControl(excalFxIndex, 0, Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z + 200) + caster:GetForwardVector()*100)

   			ParticleManager:SetParticleControl(excalFxIndex, 1, caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.0 + Vector(0, 0, 266)) 

		   	Timers:CreateTimer(0.8, function()

		   		ParticleManager:DestroyParticle( excalFxIndex, false )

				ParticleManager:ReleaseParticleIndex( excalFxIndex )

			end)

			Timers:CreateTimer(0.1, function()

				AddFOWViewer(2,caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.2 + Vector(0, 0, 266), 10, 1, false)

    			AddFOWViewer(3,caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.2 + Vector(0, 0, 266), 10, 1, false)

				local excalpepegFxIndex = ParticleManager:CreateParticle("particles/saber_alter/saber_alter_excalibur_beam_pepeg.vpcf", PATTACH_ABSORIGIN, caster)

   				ParticleManager:SetParticleControl(excalpepegFxIndex, 0, caster:GetAbsOrigin() + pepega_vec*(range + width-100)/3.2 + Vector(0, 0, 266))

   				ParticleManager:SetParticleControl(excalpepegFxIndex, 1, pepega_end + Vector(0,0,400)) 
				ParticleManager:SetParticleControl(excalpepegFxIndex, 9, Vector(0.8,0,0)) 
				ParticleManager:SetParticleControl(excalpepegFxIndex, 3, Vector(width,0,0)) 
				ParticleManager:SetParticleControl(excalpepegFxIndex, 63, Vector(0.3,0, 0.5)) 
				ParticleManager:SetParticleControl(excalpepegFxIndex, 15, caster:GetAbsOrigin() )
				ParticleManager:SetParticleControl(excalpepegFxIndex, 16, caster:GetAbsOrigin() + pepega_vec*(range + width)) 

			   	Timers:CreateTimer(0.8, function()

			   		ParticleManager:DestroyParticle( excalpepegFxIndex, false )

					ParticleManager:ReleaseParticleIndex( excalpepegFxIndex )

				end)

			end)

		else

			caster:SetBodygroup(0, 0)



		end

	end)

end

OnDexHit = function(keys)

	local caster = keys.caster

	local target = keys.target

	local ability = keys.ability

	local damagetotal = keys.Damage + keys.Damagelvl * caster:GetLevel()

	local ply = caster:GetPlayerOwner()

	if caster.IsDarklightAcquired then 

		damagetotal = damagetotal + caster:GetMaxMana()*(2.5)/100 

	end

	if target:GetUnitName() == "gille_gigantic_horror" then 

		DoDamage(keys.caster, keys.target, damagetotal*1.3 , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)

	else

		DoDamage(keys.caster, keys.target, damagetotal , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)

	end

	target:AddNewModifier(caster, ability, "modifier_morgan_slow", {Duration = 1})

	giveUnitDataDrivenModifier(caster, target, "locked", 1)

end

OnDexVfxControllerStart = function(keys)

	local caster = keys.caster

	local ability = keys.ability

	caster:AddNewModifier(caster, ability, "dark_excalibur_vfx_phase_1", {})

	caster:AddNewModifier(caster, ability, "dark_excalibur_vfx_phase_3", {})

end

OnDexVfxPhase2Start = function(keys)

	local caster = keys.caster

	local ability = keys.ability

	caster:AddNewModifier(caster, ability, "dark_excalibur_vfx_phase_2", {})

end


function saber_alter_excalibur:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: saber_alter_ability / OnDexStart
	OnDexStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Speed = self:GetSpecialValueFor("speed"),
		Width = self:GetSpecialValueFor("width"),
		Range = self:GetSpecialValueFor("length")
	})
end

function saber_alter_excalibur:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: saber_alter_ability / OnDexHit
	OnDexHit({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage"),
		Damagelvl = self:GetSpecialValueFor("damagelvl")
	})
	local fx = ParticleManager:CreateParticle("particles/custom/saber_alter/excalibur/hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(fx)
	return false
end

dark_excalibur_VFX_controller = class({})

function dark_excalibur_VFX_controller:IsHidden() return true end

function dark_excalibur_VFX_controller:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "%pause_duration" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(self:GetAbility():GetSpecialValueFor("pause_duration"), true)
	end
	-- DD RunScript: saber_alter_ability / OnDexVfxControllerStart
	OnDexVfxControllerStart({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

function dark_excalibur_VFX_controller:OnRefresh(kv)
	self:OnCreated(kv)
end

dark_excalibur_vfx_phase_1 = class({})

function dark_excalibur_vfx_phase_1:IsHidden() return true end

function dark_excalibur_vfx_phase_1:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.05" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.05, true)
	end
	self:StartIntervalThink(0.75)
	local fx = ParticleManager:CreateParticle("particles/custom/saber_alter/saber_alter_excalibur_cast.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
	ParticleManager:SetParticleControlEnt(fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_sword", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(fx, false, false, -1, false, false)
	local fx = ParticleManager:CreateParticle("particles/custom/saber_alter/saber_alter_excalibur_cast.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
	ParticleManager:SetParticleControlEnt(fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_sword", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(fx, false, false, -1, false, false)
	local fx = ParticleManager:CreateParticle("particles/custom/saber_alter/saber_alter_excalibur_cast.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
	ParticleManager:SetParticleControlEnt(fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_sword", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(fx, false, false, -1, false, false)
end

function dark_excalibur_vfx_phase_1:OnRefresh(kv)
	self:OnCreated(kv)
end

function dark_excalibur_vfx_phase_1:OnIntervalThink()
	if not IsServer() then return end
	-- DD RunScript: saber_alter_ability / OnDexVfxPhase2Start
	OnDexVfxPhase2Start({
		caster = self:GetCaster(),
		ability = self:GetAbility(),
		unit = self:GetParent(),
		target = self:GetParent()
	})
end

dark_excalibur_vfx_phase_2 = class({})

function dark_excalibur_vfx_phase_2:IsHidden() return true end

function dark_excalibur_vfx_phase_2:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "1.3" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(1.3, true)
	end
	local fx = ParticleManager:CreateParticle("particles/custom/saber_alter/saber_alter_excalibur_beam.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	self:AddParticle(fx, false, false, -1, false, false)
	local fx = ParticleManager:CreateParticle("particles/custom/saber_alter/saber_alter_excalibur_overcharge.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
	ParticleManager:SetParticleControlEnt(fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_sword", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(fx, false, false, -1, false, false)
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_enigma/enigma_blackhole_n.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
	ParticleManager:SetParticleControlEnt(fx, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_origin", self:GetParent():GetAbsOrigin(), true)
	self:AddParticle(fx, false, false, -1, false, false)
end

function dark_excalibur_vfx_phase_2:OnRefresh(kv)
	self:OnCreated(kv)
end

dark_excalibur_vfx_phase_3 = class({})

function dark_excalibur_vfx_phase_3:IsHidden() return true end

function dark_excalibur_vfx_phase_3:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "2.1" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(2.1, true)
	end
	local fx = ParticleManager:CreateParticle("particles/econ/items/doom/doom_f2p_death_effect/doom_bringer_f2p_death_ring_d_black.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	self:AddParticle(fx, false, false, -1, false, false)
end

function dark_excalibur_vfx_phase_3:OnRefresh(kv)
	self:OnCreated(kv)
end

-- modifier_morgan_slow ← saber_alter_ability.lua (монолит удалён)
LinkLuaModifier("modifier_morgan_slow", "abilities/saber_alter/saber_alter_excalibur", LUA_MODIFIER_MOTION_NONE)
modifier_morgan_slow = class({})

function modifier_morgan_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_morgan_slow:GetModifierMoveSpeedBonus_Percentage()
	return -self:GetAbility():GetSpecialValueFor("slow_power")
end

function modifier_morgan_slow:IsHidden()
	return false
end
