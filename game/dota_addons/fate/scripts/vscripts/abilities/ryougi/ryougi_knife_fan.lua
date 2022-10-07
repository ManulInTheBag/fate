LinkLuaModifier("modifier_ryougi_knife_fan_slow", "abilities/ryougi/ryougi_knife_fan", LUA_MODIFIER_MOTION_NONE)

ryougi_knife_fan = class({})

function ryougi_knife_fan:OnUpgrade()
    local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("ryougi_knife_throw"):GetLevel() ~= self:GetLevel() then
      hCaster:FindAbilityByName("ryougi_knife_throw"):SetLevel(self:GetLevel())
    end
end

function ryougi_knife_fan:OnSpellStart()
	  local caster = self:GetCaster()
	  local range = self:GetSpecialValueFor("range")

    local calc_angle = caster:GetLocalAngles()

    EmitSoundOn("ryougi_knife_"..math.random(3,4), caster)

    local init_angle = QAngle(0, caster:GetLocalAngles().y, 0)
    caster:SetAbsAngles(0, init_angle.y, 0)

    for i = 0, 5 do
      local curr_angle = QAngle(0, calc_angle.y + 20 - i*10, 0)
      caster:SetAbsAngles(0, curr_angle.y, 0)

      local target = caster:GetForwardVector()

      Timers:CreateTimer(FrameTime()*i, function()
        local tProjectile = {
        EffectName = "particles/ryougi/ryougi_dagger_blue.vpcf",
        Ability = self,
        vSpawnOrigin = caster:GetAttachmentOrigin(2),
        vVelocity = target * 2500,
        fDistance = range,
        fStartRadius = 75,
        fEndRadius = 75,
        Source = caster,
        bHasFrontalCone = false,
        bReplaceExisting = false,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        --bProvidesVision = true,
        bDeleteOnHit = true,
        --iVisionRadius = 500,
        --bFlyingVision = true,
        --iVisionTeamNumber = caster:GetTeamNumber(),
        ExtraData = {fDamage = fDamage}
        }
   	    local iProjectile = ProjectileManager:CreateLinearProjectile(tProjectile)
      end)
    end
    caster:SetAbsAngles(0, init_angle.y, 0)
end

function ryougi_knife_fan:OnProjectileHit_ExtraData(hTarget, vLocation, tData)
	  if hTarget == nil then
       return
    end
  	local hCaster = self:GetCaster()
    local eyes = hCaster:FindAbilityByName("ryougi_mystic_eyes")
  	
  	DoDamage(hCaster, hTarget, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_PHYSICAL, 0, self, false)
    if hCaster.BlackMoonAcquired then
      hTarget:AddNewModifier(hCaster, self, "modifier_ryougi_knife_fan_slow", {duration = self:GetSpecialValueFor("attribute_slow_duration")})
    end
    --giveUnitDataDrivenModifier(hCaster, hTarget, "locked", self:GetSpecialValueFor("attribute_slow_duration"))
    EmitSoundOn("ryougi_hit", hTarget)
    eyes:CutLine(hTarget, "knife_fan", true)
end

function ryougi_knife_fan:OnProjectileThink(location)
    local caster = self:GetCaster()
    local radius = 100
    local duration = 0.5

    AddFOWViewer(caster:GetTeamNumber(), location, radius, duration, false)
end

modifier_ryougi_knife_fan_slow = class({})

function modifier_ryougi_knife_fan_slow:IsHidden() return false end
function modifier_ryougi_knife_fan_slow:IsDebuff() return true end
function modifier_ryougi_knife_fan_slow:RemoveOnDeath() return true end
function modifier_ryougi_knife_fan_slow:DeclareFunctions()
  return {  MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE  }
end
function modifier_ryougi_knife_fan_slow:GetModifierMoveSpeedBonus_Percentage()
  return -1*self:GetAbility():GetSpecialValueFor("attribute_slow_percent")
end