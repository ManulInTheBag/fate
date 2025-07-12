LinkLuaModifier("modifier_arash_clair_stacking", "abilities/arash/arash_clair", LUA_MODIFIER_MOTION_NONE)
arash_clair = class({})


function arash_clair:GetAOEradius()
	return self:GetSpecialValueFor("radius")
end




function arash_clair:OnSpellStart()
	local caster = self:GetCaster()
	self.radius = self:GetSpecialValueFor("radius")
	local targetLoc = self:GetCursorPosition()
	EmitGlobalSound("Arash_clair_cast")
	caster:FindAbilityByName("arash_arrow_construction"):GetConstructionBuff()
	StartAnimation(caster, {duration=3, activity=ACT_DOTA_ITEM_PICKUP, rate=1.0})
	self.visiondummy = SpawnVisionDummy(caster, targetLoc, self.radius, self:GetSpecialValueFor("duration") + 0.3, caster.ArashClairvoyance)
	
	 self.circleFxIndexEnemyTeam = ParticleManager:CreateParticleForTeam( "particles/custom/archer/archer_clairvoyance_circle_enemyteam.vpcf",  PATTACH_WORLDORIGIN, nil, caster:GetOpposingTeamNumber() )
	ParticleManager:SetParticleShouldCheckFoW(self.circleFxIndexEnemyTeam , false)
	ParticleManager:SetParticleControl( self.circleFxIndexEnemyTeam , 0, self.visiondummy:GetAbsOrigin() )
	ParticleManager:SetParticleControl( self.circleFxIndexEnemyTeam , 1, Vector( self.radius, self.radius, self.radius ) )
	ParticleManager:SetParticleControl( self.circleFxIndexEnemyTeam , 2, Vector( 8, 0, 0 ) )

	 self.circleFxIndexTeam = ParticleManager:CreateParticleForTeam( "particles/custom/archer/archer_clairvoyance_circle_yourteam.vpcf", PATTACH_WORLDORIGIN, nil,caster:GetTeamNumber() )
	ParticleManager:SetParticleControl( self.circleFxIndexTeam, 0, self.visiondummy:GetAbsOrigin() )
	ParticleManager:SetParticleControl( self.circleFxIndexTeam, 1, Vector( self.radius, self.radius, self.radius ) )
	ParticleManager:SetParticleControl( self.circleFxIndexTeam, 2, Vector( 8, 0, 0 ) )
	ParticleManager:SetParticleControl( self.circleFxIndexTeam, 3, Vector( 100, 255, 255 ) )
	
	 self.dustFxIndex = ParticleManager:CreateParticle( "particles/custom/archer/archer_clairvoyance_dust.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleShouldCheckFoW(self.dustFxIndex, false)
	ParticleManager:SetParticleControl( self.dustFxIndex, 0, self.visiondummy:GetAbsOrigin() )
	ParticleManager:SetParticleControl( self.dustFxIndex, 1, Vector( self.radius, self.radius, self.radius ) )
	
	self.visiondummy.dust_fx = self.dustFxIndex 
	ParticleManager:SetParticleControl( self.dustFxIndex, 1, Vector( self.radius, self.radius, self.radius ) )
			
	-- Destroy particle after delay
	-- Timers:CreateTimer(self:GetSpecialValueFor("duration"), function()
	-- 	ParticleManager:DestroyParticle( self.circleFxIndexEnemyTeam, false )
	-- 		ParticleManager:DestroyParticle( self.dustFxIndex, false )
	-- 		ParticleManager:ReleaseParticleIndex( self.circleFxIndexEnemyTeam )
	-- 		ParticleManager:ReleaseParticleIndex( self.dustFxIndex )
	-- 		ParticleManager:DestroyParticle( self.circleFxIndexTeam, false )
	-- 		ParticleManager:ReleaseParticleIndex( self.circleFxIndexTeam )
	-- 		if  not self.visiondummy:IsNull() then
	-- 			self.visiondummy:RemoveSelf()
	-- 		end
	-- 	return nil
	-- end)
	self.ChannelTime = 0
	EmitSoundOnLocationWithCaster(targetLoc, "Hero_KeeperOfTheLight.BlindingLight", self.visiondummy)
end


function arash_clair:OnChannelThink(fInterval)
    self.ChannelTime = self.ChannelTime + fInterval
	local enemies = FindUnitsInRadius(  self:GetCaster():GetTeamNumber(),
			self.visiondummy:GetAbsOrigin(),
			nil,
			self.radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false)
	if #enemies > 0 then 
		for _,enemy in pairs(enemies) do
			enemy:AddNewModifier(self:GetCaster(), self, "modifier_arash_clair_stacking", {Duration = 0.1, stacks = fInterval/1.5 * 100 +  enemy:GetModifierStackCount("modifier_arash_clair_stacking", self:GetCaster()) })
		end
	end
	if IsServer() then 
  	  self:GetCaster():FaceTowards(self.visiondummy:GetAbsOrigin())
	end
end

function arash_clair:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	EndAnimation(caster)
	ParticleManager:DestroyParticle( self.circleFxIndexEnemyTeam, true )
	ParticleManager:DestroyParticle( self.dustFxIndex, true )
	ParticleManager:ReleaseParticleIndex( self.circleFxIndexEnemyTeam )
	ParticleManager:ReleaseParticleIndex( self.dustFxIndex )
	ParticleManager:DestroyParticle( self.circleFxIndexTeam, true )
	ParticleManager:ReleaseParticleIndex( self.circleFxIndexTeam )
	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
				self.visiondummy:GetAbsOrigin(),
				nil,
				self.radius,
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO,
				DOTA_UNIT_TARGET_FLAG_NONE,
				FIND_ANY_ORDER,
				false)
	self.visiondummy:RemoveSelf()
	if #enemies > 0 then 

		for _,enemy in pairs(enemies) do
					local damage =  enemy:GetModifierStackCount( "modifier_arash_clair_stacking", caster)/100*self:GetSpecialValueFor("damage")/2 + self:GetSpecialValueFor("damage")/2 
		damage = damage * (1 + (caster.ArashClairvoyance and caster.MasterUnit2:FindAbilityByName("arash_clairvoyance"):GetSpecialValueFor("star_arrow_bonus_damage")/100 or 0))
			local info = {
				Target = enemies[_],
				Source = caster,
				vSourceLoc = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_attack1")), 
				Ability = self,
				bHasFrontalCone = false,
				bReplaceExisting = false,
				iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
				iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
				iUnitTargetType = DOTA_UNIT_TARGET_HERO,
				EffectName = "particles/arash/arash_clair_arrows.vpcf",
				iMoveSpeed = 2500,
				fExpireTime = GameRules:GetGameTime() + 2,
				bDeleteOnHit = true,
				ExtraData = {fDamage =damage},
				
			}	
		ProjectileManager:CreateTrackingProjectile(info) 
		end
	end
		
	
end

 
function arash_clair:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
  	local hCaster = self:GetCaster()
	if(hTarget ~= nil) then
		if hTarget:HasModifier("modifier_protection_from_arrows_active") then return end

		local explosionFx =  ParticleManager:CreateParticle("particles/arash/arash_star_arrow_explosion_hit.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleShouldCheckFoW(explosionFx, false)
		ParticleManager:SetParticleAlwaysSimulate( explosionFx)
		ParticleManager:SetParticleControl( explosionFx, 3, hTarget:GetAbsOrigin() + Vector(0,0,50))
		ParticleManager:SetParticleControl( explosionFx, 6, Vector(1,0,0))
		local color  = Vector(0,100,255)
		ParticleManager:SetParticleControl( explosionFx, 15, color)
		ParticleManager:ReleaseParticleIndex(explosionFx)


		DoDamage(hCaster, hTarget, tData.fDamage, DAMAGE_TYPE_MAGICAL, 0, self, false)

		if hCaster.ArashClairvoyance then 
			hCaster:FindAbilityByName("arash_star_arrow"):CreateClair(hTarget:GetAbsOrigin())
		end
		hTarget:EmitSound("arash_attack_hit")

		
	end

	return true
end



modifier_arash_clair_stacking = class({})

function modifier_arash_clair_stacking:OnCreated(tdata)
	self:SetStackCount(0)
end
function modifier_arash_clair_stacking:OnRefresh(tdata)
	if type(tdata.stacks) == "number" then
		if tdata.stacks< 100 then 
			self:SetStackCount(tdata.stacks)
		else
			self:SetStackCount(100)
		end
	end
end

function modifier_arash_clair_stacking:IsDebuff()                                                             return false end
function modifier_arash_clair_stacking:IsPurgable()                                                           return false end
function modifier_arash_clair_stacking:IsPurgeException()                                                     return false end
function modifier_arash_clair_stacking:RemoveOnDeath()                                                        return true end
function modifier_arash_clair_stacking:IsHidden()															  return false end

function modifier_arash_clair_stacking:GetEffectName()
	return "particles/arash/crosshair/arash_clair_crosshair.vpcf"
end

function modifier_arash_clair_stacking:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end