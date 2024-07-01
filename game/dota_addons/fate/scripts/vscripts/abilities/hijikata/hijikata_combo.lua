LinkLuaModifier("modifier_hijikata_combo_ticker","abilities/hijikata/hijikata_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_combo_buff","abilities/hijikata/hijikata_combo", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hijikata_madness_active", "abilities/hijikata/hijikata_madness", LUA_MODIFIER_MOTION_NONE)
hijikata_combo = class({})


 
 
function hijikata_combo:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local masterCombo = caster.MasterUnit2:FindAbilityByName(self:GetAbilityName())
    masterCombo:EndCooldown()
    masterCombo:StartCooldown(self:GetCooldown(1))
	--caster:AddNewModifier(caster, self, "modifier_merlin_combo_cd", {duration = self:GetCooldown(1)})

	---sound
	self.sound = "garden_of_avalon_"..math.random(1,2)
	EmitGlobalSound(self.sound)

	---Particle and effect calculation
	local casterPositionOnCast = caster:GetAbsOrigin()
	local forwardToPointVectorNorm = (casterPositionOnCast - self:GetCursorPosition()):Normalized()
    local width = 400	 --
	local lenght = 2500  --
	local end_point = casterPositionOnCast + forwardToPointVectorNorm * -lenght

	---Adding combo modifier
	caster:AddNewModifier(caster, self, "modifier_hijikata_combo_ticker", { Duration = 10, start_point_x = casterPositionOnCast.x,
																			start_point_y = casterPositionOnCast.y, start_point_z = casterPositionOnCast.z,
																			end_point_x = end_point.x, end_point_y = end_point.y, end_point_z = end_point.z,
																			width = 500 })
	caster:AddNewModifier(caster, self, "modifier_hijikata_madness_active", { Duration = 10 })
	local nBarragePFX = ParticleManager:CreateParticle( "particles/hijikata/hijikata_combo_onground.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleShouldCheckFoW(nBarragePFX, false)
	ParticleManager:SetParticleControlTransformForward( nBarragePFX, 0, casterPositionOnCast, -forwardToPointVectorNorm  )
	ParticleManager:SetParticleControl( nBarragePFX, 1, end_point)
	ParticleManager:SetParticleControl( nBarragePFX, 2, Vector(width, 0, 0) )
end





modifier_hijikata_combo_ticker = class({})

function modifier_hijikata_combo_ticker:OnCreated(args)
	self.width = args.width
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.counter = 0
	self.speed = 700
	self.start_point = Vector(args.start_point_x, args.start_point_y, args.start_point_z)
	self.end_point = Vector(args.end_point_x, args.end_point_y, args.end_point_z)
	self:StartIntervalThink(0.1)

	--self.flag = 0
end
function modifier_hijikata_combo_ticker:OnIntervalThink()
	self.counter = self.counter + 1 
	self.speed = 700 + self.counter * 5
	if IsServer() then
		local targets = FindUnitsInLine(  		 self.caster:GetTeamNumber(),
												self.start_point,
												self.end_point,
												nil,
												self.width,
												DOTA_UNIT_TARGET_TEAM_FRIENDLY,
												DOTA_UNIT_TARGET_ALL,
												DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
												)
	end
	for k,v in pairs(targets) do       
		v:AddNewModifier(self.caster, self.ability, "modifier_hijikata_combo_buff", { Duration = 0.13, counter = self.counter })
	end		

end

function modifier_hijikata_combo_ticker:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
					MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
				 }
		return func
end
function modifier_hijikata_combo_ticker:GetActivityTranslationModifiers(keys)
    return "combo"
end

function modifier_hijikata_combo_ticker:GetModifierMoveSpeed_Absolute()
    return self.speed
end
 

function modifier_hijikata_combo_ticker:IsHidden() return false end
function modifier_hijikata_combo_ticker:IsDebuff() return false end
function modifier_hijikata_combo_ticker:RemoveOnDeath() return false end
function modifier_hijikata_combo_ticker:GetPriority()                                                                    return MODIFIER_PRIORITY_HIGH end
-- function modifier_hijikata_combo_ticker:GetEffectName()
-- 	return "particles/hijikata/hijikata_run_test.vpcf"
-- end

-- function modifier_hijikata_combo_ticker:GetEffectAttachType()
-- 	return PATTACH_ABSORIGIN_FOLLOW
-- end


 

function modifier_hijikata_combo_ticker:GetTexture()
    return "custom/merlin/merlin_garden_of_avalon"
end




modifier_hijikata_combo_buff = class ({})

function modifier_hijikata_combo_buff:OnCreated(args)
	self.counter = args.counter
end

function modifier_hijikata_combo_buff:IsHidden() return false end
function modifier_hijikata_combo_buff:IsDebuff() return false end

function modifier_hijikata_combo_buff:DeclareFunctions()
    local func = {  MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
		}
		return func
end


function modifier_hijikata_combo_buff:GetModifierMoveSpeed_Absolute()
    return (550 + self.counter * 4)
end