scathach_gae_bolg_spawn = class({})
LinkLuaModifier("modifier_scat_gae_bolg_replicas", "abilities/scathach/scathach_gae_bolg_spawn", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scat_gae_bolg_replicas_movement_controller", "abilities/scathach/scathach_gae_bolg_spawn", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_stachach_gae_bolg_curse", "abilities/scathach/scathach_gae_bolg.lua", LUA_MODIFIER_MOTION_NONE)
function scathach_gae_bolg_spawn:OnUpgrade()
	local caster = self:GetCaster()
    
    if caster:FindAbilityByName("scathach_gae_bolg_shoot"):GetLevel() ~= self:GetLevel() then
    	caster:FindAbilityByName("scathach_gae_bolg_shoot"):SetLevel(self:GetLevel())
    end
end
function scathach_gae_bolg_spawn:OnSpellStart()
	local caster = self:GetCaster()
	local gb_counter = 4
	caster:AddNewModifier(caster, self, "modifier_scat_gae_bolg_replicas", { Duration = 10, gb_count = gb_counter})
	if caster:GetAbilityByIndex(5):GetName() == "scathach_gae_bolg_spawn"  then
		caster:SwapAbilities("scathach_gae_bolg_spawn", "scathach_gae_bolg_shoot", false, true)
	end
	
	
end

modifier_scat_gae_bolg_replicas = class({})


function modifier_scat_gae_bolg_replicas:OnCreated(args)
	if IsServer() then
		self:SetStackCount(args.gb_count)
	end
	local caster = self:GetParent()
	if IsServer() then 
		if IsNotNull(self.gb_list) then 
			if #self.gb_list > 0 then
				self:RemoveGBs()
			end
		end
	end
	self.gb_list = {}
	self.gb_particle_indexes_list = {}
	self:CreateMultimpleGBs()

end
function modifier_scat_gae_bolg_replicas:OnRefresh(args)
	self:OnCreated(args)
end

function modifier_scat_gae_bolg_replicas:IsHidden()
	return false 
end
function modifier_scat_gae_bolg_replicas:OnDestroy()
	self:RemoveGBs()
	self:RestoreAbilityLayout()
end

function modifier_scat_gae_bolg_replicas:RestoreAbilityLayout()
	if IsServer() then 
		local caster = self:GetCaster()
		if caster:GetAbilityByIndex(5):GetName() == "scathach_gae_bolg_shoot"  then
			caster:SwapAbilities("scathach_gae_bolg_spawn", "scathach_gae_bolg_shoot", true, false)
		end
	end
end

function modifier_scat_gae_bolg_replicas:RemoveOnDeath()
	return true
end

function modifier_scat_gae_bolg_replicas:RemoveSpecificGb(gb, particleIndex, indexInTable)
	if  type(particleIndex) == "number"  then 
		ParticleManager:DestroyParticle(particleIndex, false)
		ParticleManager:ReleaseParticleIndex(particleIndex)
	end
	if IsNotNull(gb) then 
		gb:RemoveSelf()
	end
	table.remove(self.gb_list, indexInTable)
	table.remove(self.gb_particle_indexes_list, indexInTable)
end

function modifier_scat_gae_bolg_replicas:RemoveGBs()
	for i = #self.gb_list , 1, -1 do
		if IsNotNull(self.gb_list[i]) then 
			if self.gb_list[i].state ~= 1  and self.gb_list[i].state ~= 2 then 
				self:RemoveSpecificGb(self.gb_list[i], self.gb_particle_indexes_list[i], i)
			end
		end
		
	end
end

function modifier_scat_gae_bolg_replicas:InitGaeBolg(pos,height, rw_component_scale, bw_component_scale)
	if IsServer() then 
		local caster = self:GetParent()
		local right_vector = -caster:GetLeftVector()
		local back_vector = caster:GetForwardVector() * -1

		local gaeDummy = CreateUnitByName("gae_bolg_alternative", caster:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
		--gaeDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
		local unseen = gaeDummy:FindAbilityByName("dummy_unit_passive")
		unseen:SetLevel(1)
		gaeDummy:SetAbsOrigin(pos + Vector(0, 0, height) + right_vector * rw_component_scale + back_vector * bw_component_scale)
		gaeDummy:SetForwardVector(caster:GetForwardVector())

	
		--gaeDummy:SetModel("models/scathach/scathach_weapon.vmdl")
		
		gaeDummy:AddNewModifier(caster, self:GetAbility(), "modifier_scat_gae_bolg_replicas_movement_controller", { rw_component_scale = rw_component_scale, bw_component_scale = bw_component_scale, height1 = height, particleIndex = particle_gb_fx })
		table.insert(self.gb_list, gaeDummy)
		--table.insert(self.gb_particle_indexes_list, particle_gb_fx)
	end
end

function modifier_scat_gae_bolg_replicas:CreateMultimpleGBs()
	local caster_abs_origin = self:GetCaster():GetAbsOrigin()
	self:InitGaeBolg(caster_abs_origin, 80, 110, 300)
	self:InitGaeBolg(caster_abs_origin, 80, -110, 300)
	self:InitGaeBolg(caster_abs_origin, 150, 130, 300)
	self:InitGaeBolg(caster_abs_origin, 150, -130, 300)
end

function modifier_scat_gae_bolg_replicas:OnStackCountChanged(stackCount)
	if stackCount == 1 then
		self:Destroy()
	end

end
function modifier_scat_gae_bolg_replicas:ShootGaeBolg(targetpos)

	print(self:GetStackCount())
	if IsServer() then 
		local random = self:GetStackCount()
		self.gb_list[random]:FindModifierByName("modifier_scat_gae_bolg_replicas_movement_controller"):ShootIntoDirection(targetpos)
		local trail_fx =   ParticleManager:CreateParticle("particles/custom/scathach/spear_trail_multiple.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.gb_list[random])
		local particle_gb_fx = ParticleManager:CreateParticle("particles/custom/scathach/gae_bolg_alt_outline.vpcf", PATTACH_ABSORIGIN_FOLLOW,  self.gb_list[random])
		ParticleManager:SetParticleControlEnt(particle_gb_fx, 2, self.gb_list[random], PATTACH_POINT_FOLLOW, "1", self:GetParent():GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle_gb_fx, 0, self.gb_list[random],  PATTACH_POINT_FOLLOW ,"2", self:GetParent():GetAbsOrigin(), true)
		Timers:CreateTimer(0.75, function()
			self:RemoveSpecificGb(self.gb_list[random], self.gb_particle_indexes_list[random], random)
				ParticleManager:DestroyParticle(trail_fx, false)
				ParticleManager:ReleaseParticleIndex(trail_fx)
				ParticleManager:DestroyParticle(particle_gb_fx, false)
				ParticleManager:ReleaseParticleIndex(particle_gb_fx)
		end)
	end
		--self:DecrementStackCount()
end


modifier_scat_gae_bolg_replicas_movement_controller = class({})

function modifier_scat_gae_bolg_replicas_movement_controller:OnCreated(hui)
	self.parent = self:GetParent()
	self.casterToFollow = self:GetCaster()
	self.rw_component_scale = hui.rw_component_scale
	self.bw_component_scale = hui.bw_component_scale
	self.height = hui.height1
	self.dtTotal = 0
	self.parent.state = 0
	self.speed = 3000
	self.ability = self:GetAbility()
	self.particleIndex = hui.particleIndex
	self.parentOldPos = Vector(0,0,0)
	self.damage = self:GetAbility():GetSpecialValueFor("damage")
	self.hit_radius = 100
	self.height_addi = RandomInt(-50, 50)
	self.HittedTargets = {}
	self.target_vector_jopa = Vector(0,0,0)
	if IsServer() then
		self.randomPositionVector = RandomVector(50)
		self:StartIntervalThink(FrameTime())
		if self:ApplyHorizontalMotionController() == false then
            self:Destroy()
        end
	end
end

function modifier_scat_gae_bolg_replicas_movement_controller:IsHidden() return true end
function modifier_scat_gae_bolg_replicas_movement_controller:IsDebuff() return false end
function modifier_scat_gae_bolg_replicas_movement_controller:RemoveOnDeath() return true end
function modifier_scat_gae_bolg_replicas_movement_controller:GetPriority() return MODIFIER_PRIORITY_HIGH end

function modifier_scat_gae_bolg_replicas_movement_controller:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    --[MODIFIER_STATE_DISARMED] = true,
                    --[MODIFIER_STATE_SILENCED] = true,
                    --[MODIFIER_STATE_MUTED] = true,
                    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
					[MODIFIER_STATE_FLYING] = true }

    return state
end
function modifier_scat_gae_bolg_replicas_movement_controller:OnRefresh(hui)
    self:OnCreated(hui)
end
function modifier_scat_gae_bolg_replicas_movement_controller:OnDestroy()
	
end

function modifier_scat_gae_bolg_replicas_movement_controller:UpdateHorizontalMotion(me, dt)
	if self.parent.state == 0 then
		self.dtTotal = self.dtTotal + dt
		if self.dtTotal > 0.5 then
			self.dtTotal = self.dtTotal - 0.5
			self.randomPositionVector = RandomInt(-100, 100) * self.casterToFollow:GetRightVector() + RandomInt(-100, 100) * self.casterToFollow:GetForwardVector() + RandomInt(-100, 100) * Vector(0,0,1) 
			self.height_addi = RandomInt(-50, 50)
		end
		local pos = self.parent:GetAbsOrigin()
		local targetpos = self.casterToFollow:GetAbsOrigin()  + self.casterToFollow:GetForwardVector() * - self.bw_component_scale + Vector(0,0,self.height  + self.height_addi) 
		+ self.casterToFollow:GetRightVector() * self.rw_component_scale + self.randomPositionVector

		local distance =  (pos - targetpos):Length()
		local speed =distance*2 + 50
		
		local direction = targetpos - pos
		local target = pos + direction:Normalized() * (speed * dt)

		self.parent:FaceTowards(self.casterToFollow:GetForwardVector() * 500 + self.casterToFollow:GetAbsOrigin())

		--ParticleManager:SetParticleControl(self.particleIndex, 1, Vector(1,0,targetpos.z - GetGroundHeight(self.parent:GetAbsOrigin(), self.parent)))
		self.parent:SetAbsOrigin(target)
	elseif self.parent.state == 1 then
		self:SearchTargetsAndDealDamage()
		local pos = self.parent:GetOrigin()
		local speed = self.speed
		local direction = -self.target_vector_jopa 
		local target = pos + direction:Normalized() * (speed * dt)

		self.parent:FaceTowards(direction * 500 + target)
		
		--ParticleManager:SetParticleControl(self.particleIndex, 1, Vector(1,0,pos.z - GetGroundHeight(self.parent:GetAbsOrigin(), self.parent)))
		self.parent:SetAbsOrigin(target)
	else
		local pos = self.parent:GetAbsOrigin()
		local targetpos = self.parentOldPos

		local distance =  (pos - targetpos):Length()
		local speed =distance*10 + 10

		if distance <= 10 then
			self.parent.state = 1
		end
		
		local direction = targetpos - pos
		local target = pos + direction:Normalized() * (speed * dt) 

		self.parent:FaceTowards(-self.target_vector_jopa * 500 + self.casterToFollow:GetAbsOrigin())
		self.parent:SetAbsOrigin(target)
	end
		
end
function modifier_scat_gae_bolg_replicas_movement_controller:ShootIntoDirection(pos)
	self.parentOldPos = self.casterToFollow:GetAbsOrigin()
	self.parent.state = 2 

	self.target_vector_jopa = (self.casterToFollow:GetAbsOrigin() - pos):Normalized()
	--self.parent.state = 1

end

function modifier_scat_gae_bolg_replicas_movement_controller:SearchTargetsAndDealDamage()
	 if IsServer() and IsNotNull(self.parent) then
        local enemies = FindUnitsInRadius(  self.casterToFollow:GetTeamNumber(), 
                                            self.parent:GetAbsOrigin(), 
                                            nil, 
                                            self.hit_radius, 
                                            self.ability:GetAbilityTargetTeam(), 
                                            self.ability:GetAbilityTargetType(), 
                                            self.ability:GetAbilityTargetFlags(), 
                                            FIND_ANY_ORDER, 
                                            false)

        for _, enemy in pairs(enemies) do
            if enemy and not enemy:IsNull() then
                if not self.HittedTargets[enemy:entindex()] then
                    self.HittedTargets[enemy:entindex()] = true

                    local slash_pfx =   ParticleManager:CreateParticle("particles/emiya/emiya_swords_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
                                        ParticleManager:SetParticleControlEnt(slash_pfx, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
                                        ParticleManager:ReleaseParticleIndex(slash_pfx)

                                        enemy:EmitSound("Hero_Juggernaut.OmniSlash.Damage")

                    DoDamage(self.casterToFollow, enemy, self.damage, DAMAGE_TYPE_MAGICAL, 0, self.ability, false)
					enemy:AddNewModifier(self.casterToFollow, self.ability, "modifier_stachach_gae_bolg_curse", {duration = 10})
                end
            end
        end
    
    end
end


function modifier_scat_gae_bolg_replicas_movement_controller:GetModifierTurnRate_Override()
	return 1000
end

function modifier_scat_gae_bolg_replicas_movement_controller:DeclareFunctions()
	return { MODIFIER_PROPERTY_TURN_RATE_OVERRIDE , }
end

function modifier_scat_gae_bolg_replicas_movement_controller:OnHorizontalMotionInterrupted()  end