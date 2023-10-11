kuro_gae_bolg = class({})

function kuro_gae_bolg:GetCooldown(iLevel)
	local cooldown = self:GetSpecialValueFor("cooldown")

	--[[if self:GetCaster():HasModifier("modifier_kuro_projection") then
		cooldown = cooldown - (cooldown * 35 / 100)
	end]]

	return cooldown
end

function kuro_gae_bolg:GetManaCost(iLevel)
	local caster = self:GetCaster()
	local manacostrecud = caster:FindAbilityByName("kuro_projection"):GetSpecialValueFor("manacost_reduction")
	local manacost = self:GetSpecialValueFor("manacost")
	if(manacost - manacostrecud *caster:GetModifierStackCount("modifier_projection_active",caster)  < 0 ) then
		return 0
	else
		return manacost - manacostrecud  *caster:GetModifierStackCount("modifier_projection_active",caster)
	end
end



function kuro_gae_bolg:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" then 
			return UF_FAIL_CUSTOM 		
		elseif not self:GetCaster():HasModifier("modifier_projection_active") and not self:GetCaster():HasModifier("modifier_kuro_projection_overpower") then
			return UF_FAIL_CUSTOM
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function kuro_gae_bolg:GetCustomCastErrorTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" then
		return "#Invalid_Target"	
	else
		return "#Cannot_Cast"
	end
end

function kuro_gae_bolg:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()

	local close_ability = self:GetCaster():FindAbilityByName("kuro_spellbook_close")
	close_ability:OnSpellCalled(self)	

	if IsSpellBlocked(hTarget) then
		return
	end
	
	hCaster:EmitSound("chloe_gae_bolg")
	hTarget:EmitSound("chloe_gae_bolg")	

	giveUnitDataDrivenModifier(hCaster, hCaster, "pause_sealdisabled", 0.5)
	StartAnimation(hCaster, {duration=2, activity=ACT_DOTA_DISABLED , rate=1})

	local damage = self:GetSpecialValueFor("damage")
	local stuns = 0

	if hCaster:HasModifier("modifier_projection_active") then
		if hCaster:HasModifier("modifier_kuro_projection") then
			damage = damage + hCaster:FindAbilityByName("kuro_projection"):GetSpecialValueFor("gae_bolg_damage")
			stuns = hCaster:FindAbilityByName("kuro_projection"):GetSpecialValueFor("gae_stun_duration")
		end
		if hCaster:HasModifier("modifier_projection_active") and not hCaster:HasModifier("modifier_kuro_projection_overpower") then
			if hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()>1 then		
				hCaster:FindModifierByName("modifier_projection_active"):SetStackCount(hCaster:FindModifierByName("modifier_projection_active"):GetStackCount()-1)
			elseif not hCaster:HasModifier("modifier_kuro_projection_overpower") then
				hCaster:RemoveModifierByName("modifier_projection_active")
			end
		end
	end

	self.ForwardVector = hCaster:GetForwardVector()

	Timers:CreateTimer(0.5, function() 
		if hCaster:IsAlive() and hTarget:IsAlive() then
			self.target = hTarget 
			local tProjectile = {
		        Target = hTarget,
		        Source = hCaster,
		        Ability = self,
		        EffectName = "particles/custom/archer/archer_hrunting_orb.vpcf",
		        iMoveSpeed = 3000,
		        vSourceLoc = hCaster:GetAbsOrigin(),
		        bDodgeable = false,
		        flExpireTime = GameRules:GetGameTime() + 10,
		        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
		        ExtraData = { fDamage = damage, fStunDur = stuns }
		    }

		    FATE_ProjectileManager:CreateTrackingProjectile(tProjectile)

		    if hCaster:IsAlive() then
		    	giveUnitDataDrivenModifier(hCaster, hCaster, "jump_pause", 5)
		    	StartAnimation(hCaster, {duration=5, activity=ACT_DOTA_ATTACK_EVENT , rate=0.2})
		    end
		end
	end)   

end

function kuro_gae_bolg:OnProjectileThink_ExtraData(vLocation, tData)
	local caster = self:GetCaster()

	vLocation = GetGroundPosition(vLocation, nil)

	caster:SetAbsOrigin(vLocation)
	caster:SetForwardVector(self.target:GetAbsOrigin() - caster:GetAbsOrigin())
end

function kuro_gae_bolg:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	if hTarget == nil then return end

	local hCaster = self:GetCaster()
	local damage = tData["fDamage"]
	local heartbreak = self:GetSpecialValueFor("heartbreak")

	hCaster:RemoveModifierByName("jump_pause")
	FindClearSpaceForUnit(hCaster, hCaster:GetAbsOrigin(), true)
	hCaster:SetForwardVector(self.ForwardVector)
	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_PURE, 0, self, false)

	if tData["fStunDur"] > 0 then
		hTarget:AddNewModifier(hCaster, hTarget, "modifier_stunned", { Duration = tData["fStunDur"] })
	end

	hTarget:EmitSound("Hero_Lion.Impale")
	local culling_kill_particle = ParticleManager:CreateParticle("particles/custom/lancer/lancer_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, hTarget)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 1, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 2, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 4, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(culling_kill_particle, 8, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(culling_kill_particle)

	Timers:CreateTimer( 3.0, function()
		ParticleManager:DestroyParticle( culling_kill_particle, false )
	end)
	if self:GetCaster():HasModifier("modifier_kuro_projection") then
		if hTarget:GetHealthPercent() < heartbreak then
			local hb = ParticleManager:CreateParticle("particles/custom/lancer/lancer_heart_break_txt.vpcf", PATTACH_CUSTOMORIGIN, hTarget)
			ParticleManager:SetParticleControl( hb, 0, hTarget:GetAbsOrigin())

			Timers:CreateTimer( 3.0, function()			
				ParticleManager:DestroyParticle( hb, false )
			end)
			hTarget:Execute(self, hCaster, { bExecution = true })
		end
	end
end