demon_king_combo = class({})

LinkLuaModifier("modifier_demon_king_combo_burn", "abilities/demon_king_nobunaga/demon_king_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kb_immune", "abilities/zlodemon_nasral/modifier_kb_immune", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cc_immune", "modifiers/modifier_cc_immune", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_demon_king_combo_counter", "abilities/demon_king_nobunaga/demon_king_combo", LUA_MODIFIER_MOTION_NONE)
function demon_king_combo:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function demon_king_combo:CastFilterResultLocation(vLocation)
    local hCaster = self:GetCaster()
    if vLocation
        and hCaster and not hCaster:IsNull() then
        if   not ( IsServer() and not IsInSameRealm(hCaster:GetAbsOrigin(), vLocation) ) then
            return UF_SUCCESS
        end
    end
    return UF_FAIL_CUSTOM
end

function demon_king_combo:GetCustomCastErrorLocation(vLocation)
    return "Wrong_Target_Location"
end


function demon_king_combo:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    self.point = self:GetCursorPosition()

    self:PlayStartEffects()
     caster:FindAbilityByName("demon_king_materialization"):IncreaseStackCount(100)
    self.comboEnd = 0
    giveUnitDataDrivenModifier(caster, caster, "pause_sealenabled", duration)  
    caster:AddNewModifier(caster,self, "modifier_kb_immune", {Duration = duration})
    --caster:AddNewModifier(caster,self, "modifier_cc_immune", {Duration = duration})


    ---- Passive burn aura around hero
    caster:AddNewModifier(caster, self, "modifier_demon_king_combo_burn", {duration = duration, Radius = self:GetSpecialValueFor("passive_damage_area"),BurnDamage = self:GetSpecialValueFor("aoe_damage_passive")  })
    ----


end

function demon_king_combo:PlayEndEffects()
    if self.comboEnd == 1 then return end
    local caster = self:GetCaster()
    self.comboEnd = 1
    local descendCount = 0
    StartAnimation(self.KostyaDummy, {duration=1, activity=ACT_DOTA_CAST_FORGE_SPIRIT, rate=1})
    Timers:CreateTimer('maou_descend', {
		endTime = 0,
		callback = function()
	   	if descendCount == 20 then 	  
            FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true) 	 
            EndAnimation(caster)

            caster:RemoveModifierByNameAndCaster("modifier_kb_immune", caster)
            caster:RemoveModifierByNameAndCaster("modifier_demon_king_combo_burn", caster)
            caster:RemoveModifierByNameAndCaster("modifier_demon_king_combo_counter", caster)
            caster:RemoveModifierByNameAndCaster("pause_sealenabled", caster)
            if caster:GetAbilityByIndex(4):GetName() ~= "demon_king_materialization" then
                 if caster:GetAbilityByIndex(4):GetName() == "demon_king_combo" then
                    caster:SwapAbilities("demon_king_materialization", "demon_king_combo", true, false)
                 end
            end
		   	return 
		end
		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z-13))
         self.KostyaDummy:SetAbsOrigin(Vector(self.KostyaDummy:GetAbsOrigin().x,self.KostyaDummy:GetAbsOrigin().y,self.KostyaDummy:GetAbsOrigin().z-45))
		descendCount = descendCount + 1;
		return 0.05
	end
	})
    
    Timers:CreateTimer(1, function()
        if self.castfx ~= nil then
            ParticleManager:DestroyParticle(self.castfx, true)
            ParticleManager:ReleaseParticleIndex(self.castfx)
            self.castfx = nil
        end
        if self.shrapnelFx ~= nil then
            ParticleManager:DestroyParticle(self.shrapnelFx, false)
            ParticleManager:ReleaseParticleIndex(self.shrapnelFx)
            self.shrapnelFx = nil
            Timers:RemoveTimer("maou_combo_shrapnel")
            self.KostyaDummy:RemoveSelf()
        end
    end)
    --caster:RemoveModifierByNameAndCaster("modifier_cc_immune", caster)

end

function demon_king_combo:PlayStartEffects()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    self.point = self:GetCursorPosition()
    self.radius = self:GetSpecialValueFor("radius")
    self.shrapnelDamage = self:GetSpecialValueFor("aoe_damage_passive_shrapnel")
    caster:EmitSound("kostya_cracks")
    caster:EmitSound("kostya_fire_ambient")
    --caster:EmitSound("kostya_bgm")
    
    LoopOverPlayers(function(player, playerID, playerHero)
        if playerHero.music == true then
            CustomGameEventManager:Send_ServerToPlayer(player, "emit_horn_sound", {sound="kostya_bgm"})

        end
    end)

    EmitGlobalSound("kostya_appear_laughter")
    ScreenShake(caster:GetOrigin(), 50, 3, 2, 5000, 0, true)

    StartAnimation(caster, {duration=duration, activity=ACT_DOTA_POOF_END, rate=1})
    local kostyaPos = caster:GetAbsOrigin()+caster:GetForwardVector()*-300
	self.KostyaDummy = CreateUnitByName("kostyan", kostyaPos + Vector(0,0,-1200), false, nil, nil, caster:GetTeamNumber())
	self.KostyaDummy:FindAbilityByName("dummy_unit_passive"):SetLevel(1) 
	self.KostyaDummy:SetAbsOrigin( kostyaPos + Vector(0,0,-1200))

    self.KostyaDummy:SetForwardVector((caster:GetForwardVector() ):Normalized())
    StartAnimation(self.KostyaDummy, {duration=1.8, activity=ACT_DOTA_CAST_REFRACTION, rate=1})
    local ascendCount = 0
    Timers:CreateTimer('maou_ascend', {
		endTime = 0,
		callback = function()
	   	if ascendCount == 20 then 	  
            EndAnimation(caster)
            StartAnimation(caster, {duration=7, activity=ACT_DOTA_CAST_BURROW_END, rate=0.4})
		   	return 
		end
		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z+13))
        self.KostyaDummy:SetAbsOrigin(Vector(self.KostyaDummy:GetAbsOrigin().x,self.KostyaDummy:GetAbsOrigin().y,self.KostyaDummy:GetAbsOrigin().z+60))
		ascendCount = ascendCount + 1;
		return 0.05
	end
	})
    local descendCount = 0

    Timers:CreateTimer(2, function()
        EmitGlobalSound("kostya_appear_phrase")

    end)
    self.castfx = ParticleManager:CreateParticle("particles/demon_king_nobunaga/combo_kostya_spawn_ground.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlTransformForward(self.castfx, 0, kostyaPos, caster:GetForwardVector())
    ParticleManager:SetParticleControlTransformForward(self.castfx, 5, kostyaPos, caster:GetForwardVector())
    ParticleManager:SetParticleControl(self.castfx, 1, Vector(133,0,0))
    ParticleManager:SetParticleControl(self.castfx, 8, Vector(0,0,750))

    Timers:CreateTimer(1.5, function()
         ParticleManager:SetParticleControl(self.castfx, 8, Vector(0,0,0))
            if caster.demon_king_attribute_1 then 
                caster:FindAbilityByName("demon_king_materialization"):CreateFireGroundSa(caster:GetAbsOrigin())
            end
            self.shrapnelFx = ParticleManager:CreateParticle("particles/maou_combo/maou_combo_shrapnel.vpcf", PATTACH_WORLDORIGIN, nil)
            ParticleManager:SetParticleControl(self.shrapnelFx, 0, self.point)
            ParticleManager:SetParticleControl(self.shrapnelFx, 1, Vector(self.radius,0,0))
            ParticleManager:SetParticleShouldCheckFoW(self.shrapnelFx, false)
            caster:AddNewModifier(caster, self, "modifier_demon_king_combo_counter", {duration = duration - 1.5})
            caster:SetModifierStackCount("modifier_demon_king_combo_counter", caster, 5)
            local shrapnelCounterMax = (duration - 1.5)*5
            local counter = 0
            Timers:CreateTimer('maou_combo_shrapnel', {endtime = 0, callback = function()
                    if counter >= shrapnelCounterMax then return end
                    local targets = FindUnitsInRadius(caster:GetTeam(), self.point, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
                    for k,v in pairs(targets) do
                        DoDamage(caster, v, self.shrapnelDamage * 0.2, DAMAGE_TYPE_MAGICAL, 0, self, false)
                    end
                    counter = counter + 1
                    return 0.2
                end
            })

    end)

    Timers:CreateTimer(duration, function()
        self:PlayEndEffects()
    end)
end




    modifier_demon_king_combo_burn = class({})
if IsServer() then
	function modifier_demon_king_combo_burn:OnCreated(args)
		self.BurnDamage = args.BurnDamage
	  	self.Radius = args.Radius
		local caster = self:GetCaster()
	  	
	  	self:StartIntervalThink(0.2)

	end

	function modifier_demon_king_combo_burn:OnRefresh(args)
		self:OnCreated(args)
	end
	function modifier_demon_king_combo_burn:OnIntervalThink()	
		local caster = self:GetCaster()

		if caster ~= nil then
			local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, self.Radius , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
			for k,v in pairs(targets) do
		        DoDamage(caster, v, self.BurnDamage * 0.2, DAMAGE_TYPE_PURE, 0, self:GetAbility(), false)
		    end
		end
	end

end


modifier_demon_king_combo_counter = class({})

function modifier_demon_king_combo_counter:IsHidden()
	return false 
end

function modifier_demon_king_combo_counter:RemoveOnDeath()
	return true
end

if IsServer() then
	function modifier_demon_king_combo_counter:OnCreated(args)
		local caster = self:GetParent()
         if caster:GetAbilityByIndex(4):GetName() == "demon_king_combo" then
		     caster:SwapAbilities("demon_king_combo", "demon_king_combo_recast", false, true)
         end
         if caster:GetAbilityByIndex(4):GetName() == "demon_king_materialization" then
		    caster:SwapAbilities("demon_king_materialization", "demon_king_combo_recast", false, true)
         end
	end

	function modifier_demon_king_combo_counter:OnDestroy()	
		local caster = self:GetParent()	

        if caster:GetAbilityByIndex(4):GetName() == "demon_king_combo_recast" then
		     caster:SwapAbilities("demon_king_materialization", "demon_king_combo_recast", true, false)
        end
         if caster:GetAbilityByIndex(4):GetName() == "demon_king_combo_recast" then
		    caster:SwapAbilities("demon_king_materialization", "demon_king_combo_recast", true, false)
         end
        self:GetAbility():PlayEndEffects()
	end
end


function modifier_demon_king_combo_counter:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_DISABLE_TURNING,
	MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	MODIFIER_PROPERTY_PROVIDES_FOW_POSITION   }

	return funcs
end

function modifier_demon_king_combo_counter:GetModifierIncomingDamage_Percentage() 
	return -self:GetAbility():GetSpecialValueFor("combo_damage_reduction_pct")
end