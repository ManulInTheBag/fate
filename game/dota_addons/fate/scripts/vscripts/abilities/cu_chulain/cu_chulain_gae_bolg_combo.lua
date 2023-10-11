cu_chulain_gae_bolg_combo = class({})

LinkLuaModifier("modifier_self_disarm", "abilities/cu_chulain/modifiers/modifier_self_disarm", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wesen_cooldown", "abilities/cu_chulain/modifiers/modifier_wesen_cooldown", LUA_MODIFIER_MOTION_NONE)

function cu_chulain_gae_bolg_combo:CastFilterResultTarget(hTarget)
	local caster = self:GetCaster()
	local filter = UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, caster:GetTeamNumber())

	if(filter == UF_SUCCESS) then
		if hTarget:GetName() == "npc_dota_ward_base" or caster:IsDisarmed() then 
			return UF_FAIL_CUSTOM 		
		else
			return UF_SUCCESS
		end
	else
		return filter
	end
end

function cu_chulain_gae_bolg_combo:GetCustomCastErrorTarget(hTarget)
	if hTarget:GetName() == "npc_dota_ward_base" then
		return "#Invalid_Target"
	elseif self:GetCaster():IsDisarmed() then
		return "#Disarmed"
	else
		return "#Cannot_Cast"
	end
end

function cu_chulain_gae_bolg_combo:OnSpellStart()
	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()
	local ability = hCaster:FindAbilityByName("cu_chulain_gae_bolg")

	if not hCaster.HeartSeekerImproved and IsSpellBlocked(hTarget) then
		return
	end

	local soundQueue = math.random(1,4)

	if soundQueue ~= 4 then
		hCaster:EmitSound("Cu_Combo_" .. soundQueue)
		hTarget:EmitSound("Cu_Combo_" .. soundQueue)
	else
		hCaster:EmitSound("Lancer.Heartbreak")
		hTarget:EmitSound("Lancer.Heartbreak")
	end

	LoopOverPlayers(function(player, playerID, playerHero)
        --print("looping through " .. playerHero:GetName())
        if playerHero.gachi == true then
            -- apply legion horn vsnd on their client
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="ya_trahnu"})
            --caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        end
    end) 

	giveUnitDataDrivenModifier(hCaster, hCaster, "pause_sealdisabled", 1.9)

	ability:StartCooldown(ability:GetCooldown(ability:GetLevel()))

	--hCaster:AddNewModifier(hCaster, self, "modifier_self_disarm", { Duration = 10 })
	hCaster:AddNewModifier(hCaster, self, "modifier_wesen_cooldown", { Duration = self:GetCooldown(1) })

	local masterCombo = hCaster.MasterUnit2:FindAbilityByName("cu_chulain_gae_bolg_combo")
	masterCombo:EndCooldown()
	masterCombo:StartCooldown(masterCombo:GetCooldown(1))

	self.ForwardVector = hCaster:GetForwardVector()

	Timers:CreateTimer(1.8, function() 
		if (hCaster.HeartSeekerImproved or hCaster:IsAlive()) and hTarget:IsAlive() then
			self.target = hTarget 
			local tProjectile = {
		        Target = hTarget,
		        Source = hCaster,
		        Ability = self,
		        level = 0,
		        EffectName = "particles/custom/archer/archer_hrunting_orb.vpcf",
		        iMoveSpeed = 3000,
		        vSourceLoc = hCaster:GetAbsOrigin(),
		        bDodgeable = false,
		        flExpireTime = GameRules:GetGameTime() + 10,
		        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
		    }

		    FATE_ProjectileManager:CreateTrackingProjectile(tProjectile)

		    if hCaster:IsAlive() then
		    	giveUnitDataDrivenModifier(hCaster, hCaster, "jump_pause", 5)
		    	StartAnimation(hCaster, {duration=5, activity=ACT_DOTA_ATTACK , rate=0.2})
		    end
		end
	end)   

end

function cu_chulain_gae_bolg_combo:OnProjectileThink_ExtraData(vLocation, table)
	local caster = self:GetCaster()

	vLocation = GetGroundPosition(vLocation, nil)

	caster:SetAbsOrigin(vLocation)
	caster:SetForwardVector(self.target:GetAbsOrigin() - caster:GetAbsOrigin())
end

function cu_chulain_gae_bolg_combo:OnProjectileHit_ExtraData(hTarget, vLocation, table)
	if hTarget == nil then return end

	local hCaster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage")
	local heartbreak = self:GetSpecialValueFor("heartbreak")	

	if hCaster.HeartSeekerImproved then
		heartbreak = self:GetSpecialValueFor("attribute_heartbreak")
	end

	LoopOverPlayers(function(player, playerID, playerHero)
        	--print("looping through " .. playerHero:GetName())
        		if playerHero.gachi == true then
            	-- apply legion horn vsnd on their client
            		CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="pomnish_menya"})
            		--caster:EmitSound("Hero_LegionCommander.PressTheAttack")
        		end
    		end) 

	hCaster:RemoveModifierByName("jump_pause")
	
	FindClearSpaceForUnit(hCaster, hCaster:GetAbsOrigin(), true)
	hCaster:SetForwardVector(self.ForwardVector)

	hTarget:RemoveModifierByName("modifier_heart_of_harmony")
	--hTarget:RemoveModifierByName("modifier_share_damage")
	hTarget:RemoveModifierByName("modifier_master_intervention")
	--ApplyStrongDispel(hTarget)

	DoDamage(hCaster, hTarget, damage, DAMAGE_TYPE_PURE, DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY, self, false)

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

	if hTarget:GetHealthPercent() < heartbreak and not (hTarget:IsMagicImmune() or hTarget:HasModifier("modifier_avalon")) then
		local hb = ParticleManager:CreateParticle("particles/custom/lancer/lancer_heart_break_txt.vpcf", PATTACH_CUSTOMORIGIN, hTarget)
		ParticleManager:SetParticleControl( hb, 0, hTarget:GetAbsOrigin())

		Timers:CreateTimer( 3.0, function()			
			ParticleManager:DestroyParticle( hb, false )
		end)
		hTarget:Execute(self, hCaster, { bExecution = true })
	end
end