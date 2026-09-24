-- ВРЕМЕННАЯ отрисовка зон попадания (скилл fate-ingame-test). Ставится и
-- убирается скриптом zone_debug.py — руками в аддоне не держать.
--
-- Настройки приходят глобалами из строки подключения:
--   ZT_FILTER  — подстрока пути файла, чьи поиски рисовать ("barghest")
--   ZT_SKIP    — список подстрок, которые НЕ рисовать ({"barghest_shared", "barghest_f"}):
--                общие хелперы (их рисует адаптер) и пассивки, что ищут каждый тик
--   ZT_MIN     — не рисовать поиски меньше этого радиуса (захваты, остановки рывка), 150
--   ZT_TIME    — сколько держится картинка, 3 c
--
-- Цвета: зелёный — FindUnitsInRadius, жёлтый — FindUnitsInLine (движковые),
--        красный — дуги/секторы, синий — полосы (адаптеры хелперов Слуги).
-- В консоль идут строки [ZT] с точными числами и файл:строка вызова.
if not IsServer() then return end
local T      = _G.ZT_TIME or 3.0
local FILTER = _G.ZT_FILTER or ""
local SKIP   = _G.ZT_SKIP or {}
local MIN    = _G.ZT_MIN or 150

_G.ZT_ORIG = _G.ZT_ORIG or {}
local O = _G.ZT_ORIG
-- Оригиналы движковых функций запоминаем ОДИН раз: после script_reload файл
-- выполняется заново, и без гарда мы обернули бы уже обёрнутое.
O.fur = O.fur or FindUnitsInRadius
O.ful = O.ful or FindUnitsInLine

local function Ground(v) return GetGroundPosition(v, nil) + Vector(0, 0, 10) end
local function Seg(a, b, c) DebugDrawLine(a, b, c.x, c.y, c.z, true, T) end

-- Откуда позвали (уровень 3: наша обёртка → вызывающий).
local function Caller()
    if not (debug and debug.getinfo) then return nil end
    local t = debug.getinfo(3, "Sl")
    if not t then return nil end
    local s = t.source or ""
    if FILTER == "" or not s:find(FILTER, 1, true) then return nil end
    for _, sk in ipairs(SKIP) do
        if s:find(sk, 1, true) then return nil end
    end
    return (s:match("[^/\\]+$") or s) .. ":" .. (t.currentline or 0)
end

FindUnitsInRadius = function(nTeam, vPos, hCache, nRadius, ...)
    if nRadius >= MIN then
        local sAt = Caller()
        if sAt then
            DebugDrawCircle(Ground(vPos), Vector(60, 255, 60), 0, nRadius, true, T)
            print(string.format("[ZT] circle %s R=%.0f", sAt, nRadius))
        end
    end
    return O.fur(nTeam, vPos, hCache, nRadius, ...)
end

FindUnitsInLine = function(nTeam, vStart, vEnd, hCache, nWidth, ...)
    local sAt = Caller()
    if sAt then
        local a, b = Ground(vStart), Ground(vEnd)
        local vF = b - a; vF.z = 0
        if vF:Length2D() > 1 then
            local vR = Vector(-vF.y, vF.x, 0):Normalized() * nWidth
            local c = Vector(255, 230, 40)
            Seg(a + vR, b + vR, c) Seg(b + vR, b - vR, c) Seg(b - vR, a - vR, c) Seg(a - vR, a + vR, c)
        else
            DebugDrawCircle(a, Vector(255, 230, 40), 0, nWidth, true, T)
        end
        print(string.format("[ZT] line %s L=%.0f W=%.0f", sAt, (vEnd - vStart):Length2D(), nWidth))
    end
    return O.ful(nTeam, vStart, vEnd, hCache, nWidth, ...)
end

--------------------------------------------------------------------------------
-- Адаптеры хелперов конкретных Слуг: свои поиски с углом/полосой, которые
-- движковые обёртки не видят (или видят как круг большего радиуса).
-- Новый Слуга со своими хелперами — дописать блок по образцу.
--------------------------------------------------------------------------------
local function DrawArc(vOrigin, vDir, nRadius, nAngle, sLabel)
    local vO, c = Ground(vOrigin), Vector(255, 40, 40)
    local fBase, fHalf, vPrev = math.atan2(vDir.y, vDir.x), math.rad(nAngle * 0.5), nil
    for i = 0, 48 do
        local f = fBase - fHalf + 2 * fHalf * i / 48
        local v = vO + Vector(math.cos(f), math.sin(f), 0) * nRadius
        if vPrev then Seg(vPrev, v, c) end
        vPrev = v
    end
    if nAngle < 360 then
        Seg(vO, vO + Vector(math.cos(fBase - fHalf), math.sin(fBase - fHalf), 0) * nRadius, c)
        Seg(vO, vO + Vector(math.cos(fBase + fHalf), math.sin(fBase + fHalf), 0) * nRadius, c)
    end
    DebugDrawText(vO + Vector(0, 0, 60), sLabel, false, T)
end

local function DrawBox(vOrigin, vDir, nLength, nHalfWidth, nBack)
    local vO, c = Ground(vOrigin), Vector(40, 160, 255)
    local vF = Vector(vDir.x, vDir.y, 0):Normalized()
    local vR = Vector(-vF.y, vF.x, 0)
    local p1, p2 = vO - vF * nBack + vR * nHalfWidth, vO + vF * nLength + vR * nHalfWidth
    local p3, p4 = vO + vF * nLength - vR * nHalfWidth, vO - vF * nBack - vR * nHalfWidth
    Seg(p1, p2, c) Seg(p2, p3, c) Seg(p3, p4, c) Seg(p4, p1, c)
end

-- Barghest (barghest_shared): FindInArc(caster, ability, origin, dir, radius, angle),
-- FindInLine(caster, ability, origin, dir, length, HALF-width, back)
if Barghest_FindInArc then
    O.bArc = Barghest_FindInArc
    Barghest_FindInArc = function(hC, hA, vO, vD, nR, nAng)
        DrawArc(vO, vD, nR, nAng, string.format("%s R=%d A=%d", hA:GetAbilityName(), nR, nAng))
        print(string.format("[ZT] arc %s R=%.0f A=%.0f", hA:GetAbilityName(), nR, nAng))
        return O.bArc(hC, hA, vO, vD, nR, nAng)
    end
end
if Barghest_FindInLine then
    O.bLine = Barghest_FindInLine
    Barghest_FindInLine = function(hC, hA, vO, vD, nL, nW, nB)
        DrawBox(vO, vD, nL, nW, nB or 0)
        print(string.format("[ZT] box %s L=%.0f W=%.0f B=%.0f", hA:GetAbilityName(), nL, nW, nB or 0))
        return O.bLine(hC, hA, vO, vD, nL, nW, nB)
    end
end

print("[ZT] zone debug ON, filter=" .. FILTER)
