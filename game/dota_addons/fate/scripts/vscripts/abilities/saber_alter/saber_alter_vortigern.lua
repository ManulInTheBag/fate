-- saber_alter_vortigern — портировано из datadriven панелью (dd2lua).
-- Источник: scripts/npc/abilities/saber_alter/saber_alter_abilities.kv
-- Проверить: TODO-пометки ниже, прекеш и места применения модификаторов.

saber_alter_vortigern = class({})

LinkLuaModifier("modifier_vortigern_chain", "abilities/saber_alter/saber_alter_vortigern", LUA_MODIFIER_MOTION_NONE)

-- Логика перенесена из scripts/vscripts/lancelot_ability.lua, scripts/vscripts/saber_alter_ability.lua (DD-обвязка удалена).
-- Функции локальные: одноимённые глобали в разных файлах —
-- отдельный класс ловушек, повторять его незачем.
local OnVortigernStart, OnVortigernHit, ArsenalReturnMana

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


function saber_alter_vortigern:OnSpellStart()
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
end

function saber_alter_vortigern:OnProjectileHit(target, location)
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

modifier_vortigern_chain = class({})

function modifier_vortigern_chain:IsHidden() return false end
function modifier_vortigern_chain:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_vortigern_chain:OnCreated(kv)
	if not IsServer() then return end
	-- DD: "Duration" "5" — применялась, если вызывающий не передал свою
	if kv == nil or kv.duration == nil then
		self:SetDuration(5, true)
	end
end

function modifier_vortigern_chain:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_vortigern_chain:OnDestroy()
	if not IsServer() then return end
end
