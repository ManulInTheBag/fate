LinkLuaModifier("modifier_khsn_combo_arena", "abilities/kinghassan/khsn_combo_arena", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_combo_arena_buff", "abilities/kinghassan/khsn_combo_arena", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_combo_arena_debuff", "abilities/kinghassan/khsn_combo_arena", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_khsn_combo_execute_anim", "abilities/kinghassan/khsn_combo_arena", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_azrael_combo_cd", "abilities/kinghassan/khsn_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_heal_reduction_tier_3", "modifiers/modifier_heal_reduction", LUA_MODIFIER_MOTION_NONE)
khsn_combo_arena = class({})

function khsn_combo_arena:OnSpellStart()
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")

	local ability = self

	local masterCombo = caster.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(ability:GetCooldown(1))
    caster:AddNewModifier(caster, self, "modifier_azrael_combo_cd", {duration = ability:GetCooldown(1)})

	EmitGlobalSound("azrael_start")
	LoopOverPlayers(function(player, playerID, playerHero)
        if playerHero.zlodemon == true   then
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_kh_combo_1" })
        end
    end)

    Timers:CreateTimer(1.63, function()
        EmitGlobalSound("azrael_middle")
        LoopOverPlayers(function(player, playerID, playerHero)
            if playerHero.zlodemon == true   then
                CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_kh_combo_2" })
            end
        end)
    end)

	self.dummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin() - caster:GetForwardVector()*150, false, nil, nil, caster:GetTeamNumber())
	self.dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	self.dummy:SetForwardVector(caster:GetForwardVector())
	self.dummy:AddNewModifier(caster, self, "modifier_khsn_combo_arena", {duration  = duration})
	AddFOWViewer(2, self.dummy:GetAbsOrigin(), 40, duration, false)
	AddFOWViewer(3, self.dummy:GetAbsOrigin(), 40, duration, false)
end

LinkLuaModifier("modifier_khsn_grab_dummy", "abilities/kinghassan/khsn_grab", LUA_MODIFIER_MOTION_NONE)

function khsn_combo_arena:HassanHunt(target)
	if target.IsAlreadyDamagedByKHCombo then return end
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("damage_punishment")
	local duration = self:GetSpecialValueFor("dummy_duration")
	print("hassan hunt started")
	print(target:GetName())

	local dummy = CreateUnitByName("kh_grab_unit_back", target:GetAbsOrigin() - 100*target:GetForwardVector(), false, nil, nil, caster:GetTeamNumber())
	dummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	dummy:SetDayTimeVisionRange(400)
	dummy:SetNightTimeVisionRange(400)
	dummy:SetForwardVector(target:GetForwardVector())
	dummy:AddNewModifier(caster, self, "modifier_khsn_grab_dummy", {duration  = duration})

	dummy:EmitSound("hassanchik_laugh")

	target:EmitSound("TA.SnatchStrike")
	target.IsAlreadyDamagedByKHCombo = true
	Timers:CreateTimer(10, function()
	target.IsAlreadyDamagedByKHCombo = false
	
	end)
	local fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_grab_dummy_smoke_appear.vpcf", PATTACH_ABSORIGIN, dummy)
	ParticleManager:ReleaseParticleIndex(fx)

	DoDamage(caster, target, damage, DAMAGE_TYPE_MAGICAL, 0, ability, false)

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_night_stalker/nightstalker_void.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())

	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( particle, false )
		ParticleManager:ReleaseParticleIndex( particle )
		return nil
	end)
end

function khsn_combo_arena:AzraelExecute(target)
	local caster = self:GetCaster()

	local slashFx = ParticleManager:CreateParticle("particles/kinghassan/khsn_feathers.vpcf", PATTACH_ABSORIGIN, target )
	ParticleManager:SetParticleControl( slashFx, 0, target:GetAbsOrigin() + Vector(0,0,300))

	Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( slashFx, false )
		ParticleManager:ReleaseParticleIndex( slashFx )
	end)
			
	EmitGlobalSound("azrael_bell")
	
	Timers:CreateTimer(2.0, function()
		EmitGlobalSound("azrael_bell")
	end)
	
	Timers:CreateTimer(4.0, function()
		EmitGlobalSound("azrael_bell")
	end)

	target:Execute(self, caster, { bExecution = true })
end

khsn_combo_arena_recast = class({})

function khsn_combo_arena_recast:OnSpellStart()
	local caster = self:GetCaster()
	local enemies = FindUnitsInRadius(  caster:GetTeamNumber(),
	                                            caster:GetAbsOrigin(), 
	                                            nil, 
	                                            999999, 
	                                            DOTA_UNIT_TARGET_TEAM_ENEMY, 
	                                            DOTA_UNIT_TARGET_HERO, 
	                                            0, 
	                                            FIND_ANY_ORDER, 
	                                            false)

	EmitGlobalSound("azrael_end")
        LoopOverPlayers(function(player, playerID, playerHero)
            if playerHero.zlodemon == true   then
                CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_kh_combo_3" })
            end
        end)

	local pepe = false
	for k,v in pairs(enemies) do
		if v:HasModifier("modifier_khsn_combo_arena_debuff") then
			pepe = true
			v:AddNewModifier(caster, self, "modifier_khsn_combo_execute_anim", {duration = 2.8})
		end
	end
	if pepe then
        Timers:CreateTimer(1.4, function()
        	EmitGlobalSound("azrael_finish")
            LoopOverPlayers(function(player, playerID, playerHero)
                if playerHero.zlodemon == true   then
                    CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="zlodemon_kh_combo_4" })
                end
            end)
        end)
    end
end

modifier_khsn_combo_arena = class({})

function modifier_khsn_combo_arena:OnCreated()
	if not IsServer() then return end

	self.parent = self:GetParent()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self.caster:SwapAbilities("khsn_combo_arena", "khsn_combo_arena_recast", false, true)
	self.caster:FindAbilityByName("khsn_combo_arena_recast"):StartCooldown(4.8)

	self.width = self.ability:GetSpecialValueFor("width")
	self.length = self.ability:GetSpecialValueFor("length")
	self.duration = self.ability:GetSpecialValueFor("duration")

	self.ori = self.parent:GetAbsOrigin()
	self.forward = self.parent:GetForwardVector()
	self.right = self.parent:GetRightVector()

	self.ori_1 = self.ori + self.right*self.width/2
	self.ori_2 = self.ori - self.right*self.width/2

	self.line_fx_1 = ParticleManager:CreateParticle("particles/kinghassan/khsn_combo_area_test/khsn_combo_area_ground_line.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(self.line_fx_1, 0, self.ori_1)
	ParticleManager:SetParticleControl(self.line_fx_1, 1, self.ori_1 + self.length*self.forward)

	self.line_fx_2 = ParticleManager:CreateParticle("particles/kinghassan/khsn_combo_area_test/khsn_combo_area_ground_line.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(self.line_fx_2, 0, self.ori_2)
	ParticleManager:SetParticleControl(self.line_fx_2, 1, self.ori_2 + self.length*self.forward)

	self:AddParticle(self.line_fx_1, true, false, -1, false, false)
	self:AddParticle(self.line_fx_2, true, false, -1, false, false)

	self.ray_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_combo_area_test/khsn_combo_area_ray.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControlTransformForward(self.ray_fx, 0, self.ori, self.forward)
	ParticleManager:SetParticleControl(self.ray_fx, 1, Vector(0, 0, 1000))
	ParticleManager:SetParticleControl(self.ray_fx, 2, Vector(self.length, 0, 1000))

	self:AddParticle(self.ray_fx, true, false, -1, false, false)

	self.clouds_fx = ParticleManager:CreateParticle("particles/kinghassan/khsn_combo_area_test/khsn_combo_area_clouds.vpcf", PATTACH_ABSORIGIN, self.parent)
	ParticleManager:SetParticleControl(self.clouds_fx, 0, self.ori)
	ParticleManager:SetParticleControl(self.clouds_fx, 1, self.ori + self.length*self.forward)

	self:AddParticle(self.clouds_fx, true, false, -1, false, false)


	self.fuck_table = {}

	self:StartIntervalThink(FrameTime())
	self:OnIntervalThink()
end

function modifier_khsn_combo_arena:OnIntervalThink()
	if not IsServer() then return end

	local enemies = FATE_FindUnitsInLine(
									        self.caster:GetTeamNumber(),
									        self.ori,
									        self.ori + self.length*self.forward,
									        self.width/2,
											DOTA_UNIT_TARGET_TEAM_ENEMY,
											DOTA_UNIT_TARGET_HERO,
											DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
											FIND_CLOSEST
		   								)

	for k,v in pairs(enemies) do
		if not self.fuck_table[v:entindex()] then
			v:AddNewModifier(self.caster, self.ability, "modifier_khsn_combo_arena_debuff", {duration = FrameTime()*3})
			v:AddNewModifier(self.caster, self.ability, "modifier_heal_reduction_tier_3", {duration = FrameTime()*3})
		end
	end

	local allies = FATE_FindUnitsInLine(
									        self.caster:GetTeamNumber(),
									        self.ori,
									        self.ori + self.length*self.forward,
									        self.width/2,
											DOTA_UNIT_TARGET_TEAM_FRIENDLY,
											DOTA_UNIT_TARGET_HERO,
											DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
											FIND_CLOSEST
		   								)

	for k,v in pairs(allies) do
		if v == self.caster then
			v:AddNewModifier(self.caster, self.ability, "modifier_khsn_combo_arena_buff", {duration = FrameTime()*3})
		end
	end
end

function modifier_khsn_combo_arena:OnDestroy()
	if not IsServer() then return end

	--[[for k,v in pairs(self.fuck_table) do
		self.ability:AzraelExecute(EntIndexToHScript(k))
	end]]

	self.caster:SwapAbilities("khsn_bc", "khsn_combo_arena_recast", true, false)
end

--

modifier_khsn_combo_arena_buff = class({})

function modifier_khsn_combo_arena_buff:IsHidden() return false end
function modifier_khsn_combo_arena_buff:IsDebuff() return false end
function modifier_khsn_combo_arena_buff:RemoveOnDeath() return false end
function modifier_khsn_combo_arena_buff:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_MIN_HEALTH}
    return func
end
function modifier_khsn_combo_arena_buff:GetMinHealth()
    if IsServer() then
        return 1
    end
end

function modifier_khsn_combo_arena_buff:OnCreated()
    if IsServer() then
    end
end

--

modifier_khsn_combo_arena_debuff = class({})

function modifier_khsn_combo_arena_debuff:IsDebuff() return true end
function modifier_khsn_combo_arena_debuff:IsHidden() return false end

function modifier_khsn_combo_arena_debuff:RemoveOnDeath()
	return true
end

-- function modifier_khsn_combo_arena_debuff:DeclareFunctions()
-- 	return {MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
-- 			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE}
-- end

-- function modifier_khsn_combo_arena_debuff:GetModifierHealAmplify_PercentageTarget()
-- 	return self:GetAbility():GetSpecialValueFor("heal_reduction")
-- end

-- function modifier_khsn_combo_arena_debuff:GetModifierHPRegenAmplify_Percentage()
-- 	return self:GetAbility():GetSpecialValueFor("heal_reduction")
-- end

function modifier_khsn_combo_arena_debuff:OnCreated()
	if not IsServer() then return end

	self.parent = self:GetParent()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self:StartIntervalThink(FrameTime())
	self:OnIntervalThink()
end

function modifier_khsn_combo_arena_debuff:OnIntervalThink()
	if not IsServer() then return end

	--[[if (self.parent:GetHealth()/self.parent:GetMaxHealth()*100 < self.ability:GetSpecialValueFor("health_threshold")) then
		self.parent:AddNewModifier(self.caster, self.ability, "modifier_khsn_combo_execute_anim", {})
		self.ability.dummy:FindModifierByName("modifier_khsn_combo_arena").fuck_table[self.parent:entindex()] = true
		self:Destroy()
	end]]
end

function modifier_khsn_combo_arena_debuff:OnDestroy()
	if not IsServer() then return end

	if not self.parent:HasModifier("modifier_khsn_combo_execute_anim") and self.ability.dummy:HasModifier("modifier_khsn_combo_arena") then
		self.ability:HassanHunt(self.parent)
	end
end

--

modifier_khsn_combo_execute_anim = class({})

function modifier_khsn_combo_execute_anim:IsHidden() return true end
function modifier_khsn_combo_execute_anim:IsDebuff() return true end

function modifier_khsn_combo_execute_anim:CheckState()
    local state = { [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
                    [MODIFIER_STATE_STUNNED] = true,
                    [MODIFIER_STATE_COMMAND_RESTRICTED] = true}
    return state
end

function modifier_khsn_combo_execute_anim:OnCreated()
	self.caster = self:GetCaster()
	self.ability = self.caster:FindAbilityByName("khsn_combo_arena")
	self.parent = self:GetParent()

	local light_index = ParticleManager:CreateParticle("particles/kinghassan/khsn_domus_ray.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControl( light_index, 0, self.parent:GetAbsOrigin())
	ParticleManager:SetParticleControl( light_index, 7, self.parent:GetAbsOrigin())
end

function modifier_khsn_combo_execute_anim:OnDestroy()
	if not IsServer() then return end

	local damage = self.ability:GetSpecialValueFor("damage")

	local slashFx = ParticleManager:CreateParticle("particles/kinghassan/khsn_feathers.vpcf", PATTACH_ABSORIGIN, self.parent )
    ParticleManager:SetParticleControl( slashFx, 0, self.parent:GetAbsOrigin() + Vector(0,0,300))

    Timers:CreateTimer( 2.0, function()
		ParticleManager:DestroyParticle( slashFx, false )
		ParticleManager:ReleaseParticleIndex( slashFx )
	end)
			
	EmitGlobalSound("azrael_bell")
	
	Timers:CreateTimer(2.0, function()
		EmitGlobalSound("azrael_bell")
	end)
	
	Timers:CreateTimer(4.0, function()
		EmitGlobalSound("azrael_bell")
	end)

    DoDamage(self.caster, self.parent, damage, DAMAGE_TYPE_MAGICAL, DOTA_DAMAGE_FLAG_NONE, self.ability, false)
end

--[[function modifier_khsn_combo_execute_anim:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_DISABLE_HEALING}
    return func
end

function modifier_khsn_combo_execute_anim:GetDisableHealing()
    if IsServer() then
        return 1
    end
end]]