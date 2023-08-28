sasaki_windblade = class({})

LinkLuaModifier("modifier_exhausted", "abilities/sasaki/modifiers/modifier_exhausted", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_windblade_kojiro", "abilities/sasaki/modifiers/modifier_windblade_kojiro", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_windblade_kojiro_damage", "abilities/sasaki/sasaki_windblade", LUA_MODIFIER_MOTION_NONE)
function sasaki_windblade:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function sasaki_windblade:OnSpellStart()

	EmitGlobalSound("FA.Windblade")

	local caster = self:GetCaster()
	local casterInitOrigin = caster:GetAbsOrigin() 
	local empowered = false
	local number_of_slash = self:GetSpecialValueFor("base_slashes")
	if caster:HasModifier("modifier_sasaki_kappa") then
		number_of_slash = number_of_slash + 3
	end
	
	local targets = FindUnitsInRadius(caster:GetTeam(), casterInitOrigin, nil, self:GetAOERadius(), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

	--if caster:GetMana() > 99 then		
		--empowered = true
		--number_of_slash = number_of_slash + self:GetSpecialValueFor("empowered_slashes")
		--caster:EmitSound("Sasaki_Windblade_2")
		--if caster.IsGanryuAcquired then
		--	caster:FindAbilityByName("sasaki_tsubame_gaeshi"):EndCooldown()
	--	end
	--else
		caster:EmitSound("Sasaki_Windblade_1")
		LoopOverPlayers(function(player, playerID, playerHero)
			--print("looping through " .. playerHero:GetName())
			if playerHero.zlodemon == true then
				-- apply legion horn vsnd on their client
				CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="moskes_flex"})
				--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
			end
		end)
	--end

	caster:RemoveModifierByName("modifier_heart_of_harmony")
	--caster:AddNewModifier(caster, self, "modifier_exhausted", { Duration = self:GetSpecialValueFor("exhausted_duration") })

	caster:AddNewModifier(caster, self, "modifier_windblade_kojiro", { Duration = 0.6,
																	   RemainingHits = number_of_slash,
																	   Radius = self:GetAOERadius() + 150,
																	   Empowered = empowered,
																	   StunDuration = self:GetSpecialValueFor("stun_duration") })

	for k,v in pairs(targets) do
		if v:GetUnitName() ~= "ward_familiar" and not v:HasModifier("modifier_wind_protection_passive") then 			
			if v ~= empoweredTarget then  				
				local slashIndex = ParticleManager:CreateParticle( "particles/custom/false_assassin/tsubame_gaeshi/tsubame_gaeshi_windup_indicator_flare.vpcf", PATTACH_CUSTOMORIGIN, nil )
			    ParticleManager:SetParticleControl(slashIndex, 0, v:GetAbsOrigin())
			    ParticleManager:SetParticleControl(slashIndex, 1, Vector(500,0,150))
			    ParticleManager:SetParticleControl(slashIndex, 2, Vector(0.2,0,0))

			    if not IsKnockbackImmune(v) then
			    	--if caster:HasModifier("modifier_sasaki_kappa") then
			    		--giveUnitDataDrivenModifier(caster, v, "drag_pause", 0.5)
			    	--end
					local pushback = Physics:Unit(v)
					v:PreventDI()
					v:SetPhysicsFriction(0)
					v:SetPhysicsVelocity((v:GetAbsOrigin() - casterInitOrigin):Normalized() * 150)
					v:SetNavCollisionType(PHYSICS_NAV_NOTHING)
					v:FollowNavMesh(false)
					Timers:CreateTimer(0.5, function()  
						v:PreventDI(false)
						v:SetPhysicsVelocity(Vector(0,0,0))
						v:OnPhysicsFrame(nil)
						FindClearSpaceForUnit(v, v:GetAbsOrigin(), true)
						return 
					end)
				end
			end
		end
	end

	local risingWindFx = ParticleManager:CreateParticle("particles/custom/false_assassin/fa_thunder_clap.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	-- Destroy particle after delay
	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( risingWindFx, false )
		ParticleManager:ReleaseParticleIndex( risingWindFx )
		return nil
	end)

	caster:AddNewModifier(caster, caster, "modifier_stunned", {Duration = 0.1})

	--[[for i=1, #targets do
		if targets[i]:IsAlive() and targets[i]:GetName() ~= "npc_dota_ward_base" then
			--local diff = (caster:GetAbsOrigin() - targets[i]:GetAbsOrigin()):Normalized()
			caster:SetAbsOrigin(targets[i]:GetAbsOrigin() - targets[i]:GetForwardVector():Normalized() * 100)
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

			if empowered then
				empoweredTarget = targets[i]
				targets[i]:AddNewModifier(caster, self, "modifier_stunned", { Duration = self:GetSpecialValueFor("stun_duration")})

				local counter = 0
				local slashcount = self:GetSpecialValueFor("empowered_slashes")
				Timers:CreateTimer(function()
					if counter == slashcount or not caster:IsAlive() then return end 
					caster:PerformAttack( targets[i], true, true, true, true, false, false, false )
					CreateSlashFx(caster, targets[i]:GetAbsOrigin() + RandomVector(500), targets[i]:GetAbsOrigin() + RandomVector(500))
					counter = counter + 1
					return 0.1
				end)
			end

			break
		end
	end]]	
end

modifier_windblade_kojiro_damage = class({})

  
function modifier_windblade_kojiro_damage:IsHidden()
	return false 
end

function modifier_windblade_kojiro_damage:RemoveOnDeath()
	return true 
end

function modifier_windblade_kojiro_damage:IsDebuff()
	return true 
end


function modifier_windblade_kojiro_damage:OnCreated(args)
    if not IsServer() then return end
	self.damage = args.Damage
    self.slashIndex = ParticleManager:CreateParticle( "particles/saito/saito_inv_sword_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl(self.slashIndex, 0, self:GetParent():GetAbsOrigin() + Vector(0,0,100))
 
    Timers:CreateTimer(0.3, function()
        ParticleManager:DestroyParticle(self.slashIndex, true)
        ParticleManager:ReleaseParticleIndex(self.slashIndex)
    end)
end


function modifier_windblade_kojiro_damage:OnDestroy()
    if not IsServer() then return end
    DoDamage(self:GetCaster(), self:GetParent(), self.damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
    self.explosion = ParticleManager:CreateParticle( "particles/saito/saito_inv_sword_explosion_real.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
    ParticleManager:SetParticleControl(self.explosion, 0, self:GetParent():GetAbsOrigin() + Vector(0,0,100))
    Timers:CreateTimer(0.3, function()
    ParticleManager:DestroyParticle(self.explosion, true)
    ParticleManager:ReleaseParticleIndex(self.explosion)
 
    end)

end



function modifier_windblade_kojiro_damage:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end