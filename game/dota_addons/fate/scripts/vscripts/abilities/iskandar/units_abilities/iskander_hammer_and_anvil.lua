iskander_hammer_and_anvil = class({})

local aotkCenter = Vector(288,-4564, 261)
local ubwCenter = Vector(5926, -4837, 222)

function iskander_hammer_and_anvil:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local castFx = ParticleManager:CreateParticle("particles/units/heroes/hero_chaos_knight/chaos_knight_reality_rift.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(castFx, 1, caster:GetAbsOrigin()) -- target effect location
	ParticleManager:SetParticleControl(castFx, 2, caster:GetAbsOrigin()) -- circle effect location
	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( castFx, false )
		ParticleManager:ReleaseParticleIndex( castFx )
	end)
	return true
end

function iskander_hammer_and_anvil:OnSpellStart()
	local caster = self:GetCaster()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local damage = self:GetSpecialValueFor("damage")

	self:CleanUpHammer(hero)

	local cavalryTable = {}
	table.insert(cavalryTable, caster)
	caster:EmitSound("Hero_Centaur.Stampede.Cast")

	if hero.IsAOTKDominant then
		caster:SetAbsOrigin(aotkCenter + Vector(-1400, 0, 0))
	else
		caster:SetAbsOrigin(ubwCenter + Vector(-1100, 0, 0))
	end

	for i=1, #hero.AOTKSoldiers do
		if IsValidEntity(hero.AOTKSoldiers[i]) then
			if hero.AOTKSoldiers[i]:IsAlive() then
				if hero.AOTKSoldiers[i]:GetUnitName() == "iskander_cavalry" then
					table.insert(cavalryTable, hero.AOTKSoldiers[i])
					if hero.IsAOTKDominant then
						hero.AOTKSoldiers[i]:SetAbsOrigin(aotkCenter + Vector(-1400, -600 + RandomInt(0, 1200), 0))
					else
						hero.AOTKSoldiers[i]:SetAbsOrigin(ubwCenter + Vector(-900, -600 + RandomInt(0,1200), 0))
					end
				end
			end
		end
	end

	hero.HammerTimers = #cavalryTable

	for i=1,#cavalryTable do
		local counter = 0
		Timers:CreateTimer("hammer_charge" .. i, {
			endTime = 0.0,
			callback = function()
			if counter > 3 then return end
			local targets = FindUnitsInRadius(cavalryTable[i]:GetTeam(), cavalryTable[i]:GetAbsOrigin(), nil, 150, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for k,v in pairs(targets) do
				if v.HammerChargeHit ~= true then
					v.HammerChargeHit = true
					Timers:CreateTimer(1.0, function()
						v.HammerChargeHit = false
					end)

					DoDamage(cavalryTable[i], v, damage, DAMAGE_TYPE_MAGICAL, 0, self, false)
					v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 1.00})
				else
					DoDamage(cavalryTable[i], v, damage/2, DAMAGE_TYPE_MAGICAL, 0, self, false)
				end
			end
			counter = counter+0.15
			return 0.15
		end})

		giveUnitDataDrivenModifier(caster, caster, "round_pause", 2.0)
		local cavalryUnit = Physics:Unit(cavalryTable[i])
		cavalryTable[i]:PreventDI()
		cavalryTable[i]:SetPhysicsFriction(0)
		cavalryTable[i]:SetPhysicsVelocity((hero:GetAbsOrigin() - cavalryTable[i]:GetAbsOrigin()):Normalized() * 1500)
		cavalryTable[i]:SetNavCollisionType(PHYSICS_NAV_NOTHING)
		cavalryTable[i]:FollowNavMesh(false)
		StartAnimation(cavalryTable[i], {duration = 1, activity=ACT_DOTA_CAST_ABILITY_1, rate=1})
		cavalryTable[i]:OnPhysicsFrame(function(unit)
			local diff = hero:GetAbsOrigin() - cavalryTable[i]:GetAbsOrigin()
			local dir = diff:Normalized()
			local particle = ParticleManager:CreateParticle("particles/econ/items/tinker/boots_of_travel/teleport_end_bots_dust.vpcf", PATTACH_ABSORIGIN, cavalryTable[i])
			ParticleManager:SetParticleControl(particle, 0, cavalryTable[i]:GetAbsOrigin())
			Timers:CreateTimer( 2.0, function()
				ParticleManager:DestroyParticle( particle, false )
				ParticleManager:ReleaseParticleIndex( particle )
			end)
			unit:SetPhysicsVelocity(unit:GetPhysicsVelocity():Length() * dir)
			unit:SetForwardVector(dir)
			if diff:Length() < 50 then
				unit:PreventDI(false)
				unit:SetPhysicsVelocity(Vector(0,0,0))
				unit:OnPhysicsFrame(nil)
				unit:RemoveModifierByName("round_pause")
				Timers:RemoveTimer("hammer_charge" .. i)
			end
		end)
	end
	hero.CavalryTable = cavalryTable
end

function iskander_hammer_and_anvil:CleanUpHammer(hero)
	local hammerTimers = hero.HammerTimers
	if hammerTimers ~= nil then
		for i=1,hammerTimers do
			Timers:RemoveTimer("hammer_charge" .. i)
		end
	end
	local oldCavalryTable = hero.CavalryTable
	if oldCavalryTable ~= nil then
		for i=1,#oldCavalryTable do
			local unit = oldCavalryTable[i]
			if unit ~= nil and not unit:IsNull() then
				unit:PreventDI(false)
				unit:SetPhysicsVelocity(Vector(0,0,0))
				unit:OnPhysicsFrame(nil)
				unit:RemoveModifierByName("round_pause")
			end
		end
	end

	hero.CavalryTable = nil
	hero.HammerTimers = nil
end
