-- Модификаторы командных баффов от бафф-зон.
-- Недиспелябельны, живут до конца раунда или перезахвата зоны
-- (снимает ControlZones, в таблицы диспелов util.lua не входят).
local CONFIG = require("modules/control_zones/config")
local BUFFS = CONFIG.BUFF_ZONES.BUFFS

--------------------------------------------------------------------
modifier_zone_buff_damage = class({})

function modifier_zone_buff_damage:IsHidden() return false end
function modifier_zone_buff_damage:IsDebuff() return false end
function modifier_zone_buff_damage:IsPurgable() return false end
function modifier_zone_buff_damage:RemoveOnDeath() return false end
function modifier_zone_buff_damage:GetTexture() return "bloodseeker_bloodrage" end

function modifier_zone_buff_damage:DeclareFunctions()
    return { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE }
end

function modifier_zone_buff_damage:GetModifierTotalDamageOutgoing_Percentage()
    return BUFFS.damage.value
end

--------------------------------------------------------------------
modifier_zone_buff_armor = class({})

function modifier_zone_buff_armor:IsHidden() return false end
function modifier_zone_buff_armor:IsDebuff() return false end
function modifier_zone_buff_armor:IsPurgable() return false end
function modifier_zone_buff_armor:RemoveOnDeath() return false end
function modifier_zone_buff_armor:GetTexture() return "abaddon_aphotic_shield" end

function modifier_zone_buff_armor:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    }
end

function modifier_zone_buff_armor:GetModifierPhysicalArmorBonus()
    return BUFFS.armor.armor
end

function modifier_zone_buff_armor:GetModifierMagicalResistanceBonus()
    return BUFFS.armor.mr
end

--------------------------------------------------------------------
modifier_zone_buff_ms = class({})

function modifier_zone_buff_ms:IsHidden() return false end
function modifier_zone_buff_ms:IsDebuff() return false end
function modifier_zone_buff_ms:IsPurgable() return false end
function modifier_zone_buff_ms:RemoveOnDeath() return false end
function modifier_zone_buff_ms:GetTexture() return "dark_seer_surge" end

function modifier_zone_buff_ms:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_zone_buff_ms:GetModifierMoveSpeedBonus_Percentage()
    return BUFFS.ms.value
end
