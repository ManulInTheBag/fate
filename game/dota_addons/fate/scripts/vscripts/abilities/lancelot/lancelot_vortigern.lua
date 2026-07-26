-- lancelot_vortigern — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/lancelot/lancelot_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

lancelot_vortigern = class({})

-- Логика перенесена из scripts/vscripts/lancelot_ability.lua, scripts/vscripts/saber_alter_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnVortigernStart, OnKnightUsed, OnVortigernHit, ArsenalReturnMana, OnKnightClosed

OnVortigernStart = function(keys)
	ArsenalReturnMana(keys.caster)
	local caster = keys.caster
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()
	local forward = ( keys.ability:GetCursorPosition() - caster:GetAbsOrigin() ):Normalized() -- caster:GetForwardVector() 
	local angle = 120
	local increment_factor = 30
	local origin = caster:GetAbsOrigin()
	local destination = origin + forward

	if (math.abs(destination.x - origin.x) < 0.01) and (math.abs(destination.y - origin.y) < 0.01) then
		destination = caster:GetForwardVector() + caster:GetAbsOrigin()
	end
	keys.caster:AddNewModifier(keys.caster, ability, "modifier_merlin_self_pause", {Duration = 0.70}) 
	--giveUnitDataDrivenModifier(keys.caster, keys.caster, "pause_sealdisabled", 0.70) -- Beam interval * 9 + 0.44
	EmitGlobalSound("Saber_Alter.Vortigern")
	if keys.caster:GetName() == "npc_dota_hero_sven" then
		EmitZlodemonTrueSoundEveryone("moskes_lanc_vort")
	end
	local vortigernBeam =
	{
		Ability = keys.ability,
		EffectName = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf",
		iMoveSpeed = 3000,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = 600,
		Source = caster,
		fStartRadius = 75,
        fEndRadius = 120,
		bHasFrontialCone = true,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_ALL,
		fExpireTime = GameRules:GetGameTime() + 0.4,
		bDeleteOnHit = false,
		vVelocity = 0,
	}

	if caster.IsFerocityImproved then
		if caster:HasModifier("modifier_vortigern_ferocity") then
			local ferocity_modifier = caster:FindModifierByName("modifier_vortigern_ferocity")
			local stacks = ferocity_modifier:GetStackCount()
			if stacks > 1 then
				ability:EndCooldown()
				ferocity_modifier:SetStackCount(stacks - 1)
			else
				caster:RemoveModifierByName("modifier_vortigern_ferocity")
			end
		else
			local ferocity_modifier = caster:AddNewModifier(caster, ability, "modifier_vortigern_ferocity", { Duration = 3 })
			ability:EndCooldown()
			ferocity_modifier:SetStackCount(2)
		end		
	end

	
	--[[local casterAngle = QAngle(0, 120 ,0)
	Timers:CreateTimer(function() 
			if vortigernCount == 10 then vortigernCount = 0 return end -- finish spell
			vortigernBeam.vVelocity = RotatePosition(caster:GetAbsOrigin(), casterAngle, forward * 3000) 
			local projectile = ProjectileManager:CreateLinearProjectile(vortigernBeam)
			casterAngle.y = casterAngle.y - 24;
			print(casterAngle.y)
			vortigernCount = vortigernCount + 1; 
			
			return 0.040 
		end
	)]]
	
	-- Base variables


	vortigernCount = 0
	Timers:CreateTimer( function()
			-- Finish spell, need to include the last angle as well
			-- Note that the projectile limit is currently at 9, to increment this, need to create either dummy or thinker to store them
			if vortigernCount == 9 then return end
			
			-- Start rotating
			local theta = ( angle - vortigernCount * increment_factor ) * math.pi / 180
			local px = math.cos( theta ) * ( destination.x - origin.x ) - math.sin( theta ) * ( destination.y - origin.y ) + origin.x
			local py = math.sin( theta ) * ( destination.x - origin.x ) + math.cos( theta ) * ( destination.y - origin.y ) + origin.y

			local new_forward = ( Vector( px, py, origin.z ) - origin ):Normalized()
			vortigernBeam.vVelocity = new_forward * 3000
			vortigernBeam.fExpireTime = GameRules:GetGameTime() + 0.4
			
			-- Fire the projectile
			local projectile = ProjectileManager:CreateLinearProjectile( vortigernBeam )
			vortigernCount = vortigernCount + 1
			
			-- Create particles
			local fxIndex1 = ParticleManager:CreateParticle( "particles/custom/saber_alter/saber_alter_vortigern_line.vpcf", PATTACH_CUSTOMORIGIN, caster )
			ParticleManager:SetParticleControl( fxIndex1, 0, caster:GetAbsOrigin() )
			ParticleManager:SetParticleControl( fxIndex1, 1, vortigernBeam.vVelocity )
			ParticleManager:SetParticleControl( fxIndex1, 2, Vector( 0.2, 0.2, 0.2 ) )
			
			Timers:CreateTimer( 0.2, function()
					ParticleManager:DestroyParticle( fxIndex1, false )
					ParticleManager:ReleaseParticleIndex( fxIndex1 )
					return nil
				end
			)
			
			return 0.06
		end
	)
end

OnKnightUsed = function(keys)
        local caster = keys.caster
        local ply = caster:GetPlayerOwner()
        local ability = keys.ability

        if not caster.KnightLevel and not caster.ArsenalLevel then
                OnKnightClosed(keys)
                caster:FindAbilityByName("lancelot_knight_of_honor"):StartCooldown(ability:GetCooldown(ability:GetLevel()))
        end
end

OnVortigernHit = function(keys)
	local caster = keys.caster
	local target = keys.target
	local ply = caster:GetPlayerOwner()
	local damage = keys.Damage
	local StunDuration = keys.StunDuration
	local vortSwingDamage = 5

	damage = damage * (80 + vortigernCount * vortSwingDamage) / 100

	--[[if caster.IsFerocityImproved then 
		if caster:HasModifier("modifier_vortigern_ferocity") then
			damage = damage * 0.66
		end		
	end]]
	if caster.ImproveKnightOfOwner then
		StunDuration = StunDuration + 0.2
	end
	StunDuration = StunDuration * (80 + vortigernCount * 5)/100
	if target.IsVortigernHit ~= true then
		target.IsVortigernHit = true
		Timers:CreateTimer(0.54, function() target.IsVortigernHit = false return end)
		DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
		target:AddNewModifier(caster, caster, "modifier_stunned", {Duration = StunDuration})
		print(damage)
		
	end

end

ArsenalReturnMana = function(caster)
    if caster:GetName() == "npc_dota_hero_sven" and caster.ArsenalLevel == 2 then
        caster:GiveMana(caster:FindAbilityByName("lancelot_knight_of_honor_arsenal"):GetSpecialValueFor("mana_return"))
    end
end

OnKnightClosed = function(keys)
        local caster = keys.caster
        caster.IsKnightOpen = false
        local a1 = caster:GetAbilityByIndex(0)
        local a2 = caster:GetAbilityByIndex(1)
        local a3 = caster:GetAbilityByIndex(2)
        local a4 = caster:GetAbilityByIndex(3)
        local a5 = caster:GetAbilityByIndex(4)
        local a6 = caster:GetAbilityByIndex(5)
        -- if knight attribute is not taken, caster.KnightLevel~=nil is false and therefore kills off queueing a 2nd skill. 
        caster:SwapAbilities(a1:GetName(), "lancelot_minigun", false ,true) 
        caster:SwapAbilities(a2:GetName(), "lancelot_parry", false, true) 
        caster:SwapAbilities(a3:GetName(), "lancelot_knight_of_honor", false, true)
        if caster.nukeAvail == true then 
            caster:SwapAbilities(a4:GetName(), "lancelot_nuke", false, true) 
        elseif caster:HasAbility("lancelot_blessing_of_fairy") then 
            caster:SwapAbilities(a4:GetName(), "lancelot_blessing_of_fairy", false, true) 
        else 
            caster:SwapAbilities(a4:GetName(), "fate_empty1", false, true) 
        end
        caster:SwapAbilities(a5:GetName(), "lancelot_arms_mastership", false, true) 
        
        if caster:HasModifier("modifier_arondite") then
            caster:SwapAbilities(a6:GetName(), "lancelot_arondight_overload", false, true )     
        else
            caster:SwapAbilities(a6:GetName(), "lancelot_arondite", false, true )     
        end
end


function lancelot_vortigern:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	-- DD RunScript: saber_alter_ability / OnVortigernStart
	OnVortigernStart({
		caster = caster,
		ability = self,
		target = caster,
		target_points = { point },
		Target = "POINT",
		Radius = self:GetSpecialValueFor("radius"),
		Damage = self:GetSpecialValueFor("damage"),
		StunDuration = self:GetSpecialValueFor("stun_duration")
	})
	-- DD RunScript: lancelot_ability / OnKnightUsed
	OnKnightUsed({ caster = caster, ability = self, target = caster, target_points = { point } })
end

function lancelot_vortigern:OnProjectileHit(target, location)
	if target == nil then return false end
	local caster = self:GetCaster()
	-- DD RunScript: saber_alter_ability / OnVortigernHit
	OnVortigernHit({
		caster = caster,
		ability = self,
		target = target,
		Damage = self:GetSpecialValueFor("damage"),
		StunDuration = self:GetSpecialValueFor("stun_duration")
	})
	return false
end
