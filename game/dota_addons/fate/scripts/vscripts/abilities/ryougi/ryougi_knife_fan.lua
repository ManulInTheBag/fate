ryougi_knife_fan = class({})

--[[function ryougi_knife_fan:OnUpgrade()
    local hCaster = self:GetCaster()
    
    if hCaster:FindAbilityByName("ryougi_knife_throw"):GetLevel() ~= self:GetLevel() then
      hCaster:FindAbilityByName("ryougi_knife_throw"):SetLevel(self:GetLevel())
    end
end]]

function ryougi_knife_fan:OnSpellStart()
	  local caster = self:GetCaster()
	  local range = self:GetSpecialValueFor("range")
    local tpoint = self:GetCursorPosition()
    local dir = tpoint - caster:GetAbsOrigin()
    dir.z = 0
    caster:SetForwardVector(dir:Normalized())

    local calc_angle = caster:GetLocalAngles()

    EmitSoundOn("ryougi_knife_"..math.random(1,4), caster)

    local init_angle = QAngle(0, caster:GetLocalAngles().y, 0)
    caster:SetAbsAngles(0, init_angle.y, 0)

    if caster.KiyohimePassingAcquired then
      HardCleanse(caster)
    end

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
        iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        iUnitTargetType = DOTA_UNIT_TARGET_ALL,
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
    if (hTarget:GetName() == "npc_dota_ward_base") then
      return
    end
  	local hCaster = self:GetCaster()
    local eyes = hCaster:FindAbilityByName("ryougi_mystic_eyes")
  	
  	DoDamage(hCaster, hTarget, self:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, 0, self, false)
    if hCaster.BlackMoonAcquired and not (hTarget:IsMagicImmune()) then
      giveUnitDataDrivenModifier(hCaster, hTarget, "silenced", self:GetSpecialValueFor("attribute_silence_duration"))
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