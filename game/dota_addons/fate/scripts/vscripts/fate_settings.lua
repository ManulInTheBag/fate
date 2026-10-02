-- Настройки игрока на сервере статистики (fate-binds-server, таблица settings):
-- сейчас там только фильтры значков эффектов (panorama effect_bars.js и вкладка
-- Effects в настройках). Профиль - непрозрачная JSON-строка от клиента, сервер
-- её не разбирает, как и бинды (OnPlayerSaveBinds в addon_game_mode.lua).
--
-- Отдельно от биндов намеренно: бинды сохраняются только кнопкой целиком, и
-- общий профиль затирал бы раскладку, которую игрок в этом матче не загружал.
--
-- Клиент сам просит загрузку в начале матча (player_load_settings) и сохраняет
-- после правки (player_save_settings, с задержкой на клиенте). Ответы -
-- fate_settings_loaded / fate_settings_save_result.
--
-- FATE_BINDS_HOST / FATE_API_KEY / FateCreateHTTPRequest читаются через _G в
-- момент вызова: файл грузится из addon_game_mode.lua (см. require рядом с
-- fate_mmr), и объявленное там ниже точки require отсюда иначе не видно.

FateSettings = FateSettings or {}
FateSettings.reqlog = FateSettings.reqlog or {}

-- Профиль - десяток полей; потолок заодно держит ответ реле в пределах
-- заголовка страницы (fate_http.lua: тело > 3800 символов не доезжает).
local MAX_PROFILE = 2048

-- Пер-игрок гейт, как у биндов, но щедрее: сохранение идёт само после
-- каждой правки (клиент копит правки 3 с), загрузка - раз в начале матча.
local REQ_MAX = 12
local REQ_WINDOW = 300


local function AllowRequest(playerID)
    local now = Time()
    local kept = {}
    for _, t in ipairs(FateSettings.reqlog[playerID] or {}) do
        if (now - t) < REQ_WINDOW then kept[#kept + 1] = t end
    end
    FateSettings.reqlog[playerID] = kept
    if #kept >= REQ_MAX then return false end
    kept[#kept + 1] = now
    return true
end


-- steamid живого игрока или nil (боты, зрители без аккаунта).
local function SteamID(playerID)
    if playerID == nil or not PlayerResource:IsValidPlayerID(playerID) then return nil end
    if PlayerResource:IsFakeClient(playerID) then return nil end
    local steamid = tostring(PlayerResource:GetSteamAccountID(playerID))
    if steamid == "0" then return nil end
    return steamid
end


-- Адрес сервера; nil, если fate_secrets.lua в сборке нет (свежий клон).
local function Host()
    local host = _G.FATE_BINDS_HOST
    if type(host) ~= "string" or host == "" then return nil end
    return host
end


local function Reply(playerID, event, data)
    local ply = PlayerResource:GetPlayer(playerID)
    if ply then
        CustomGameEventManager:Send_ServerToPlayer(ply, event, data)
    end
end


function FateSettings:OnSave(args)
    if _G.FateServerDisabled and _G.FateServerDisabled() then return end
    local playerID = args.PlayerID
    local steamid = SteamID(playerID)
    if not steamid then return end

    local profile = args.data
    if type(profile) ~= "string" or profile == "" or #profile > MAX_PROFILE then return end

    if not AllowRequest(playerID) then
        Reply(playerID, "fate_settings_save_result", { ok = 0, status = 429 })
        return
    end

    local host = Host()
    if not host then
        Reply(playerID, "fate_settings_save_result", { ok = 0, status = 0 })
        return
    end

    local req = _G.FateCreateHTTPRequest("POST", host .. "/settings")
    req:SetHTTPRequestHeaderValue("X-Fate-Key", _G.FATE_API_KEY)
    req:SetHTTPRequestGetOrPostParameter("steamid", steamid)
    req:SetHTTPRequestGetOrPostParameter("profile", profile)
    req:Send(function(res)
        Reply(playerID, "fate_settings_save_result",
            { ok = (res.StatusCode == 200) and 1 or 0, status = res.StatusCode or 0 })
    end)
end


function FateSettings:OnLoad(args)
    if _G.FateServerDisabled and _G.FateServerDisabled() then return end
    local playerID = args.PlayerID
    local steamid = SteamID(playerID)
    if not steamid then return end

    if not AllowRequest(playerID) then
        Reply(playerID, "fate_settings_loaded", { ok = 0, status = 429 })
        return
    end

    local host = Host()
    if not host then
        Reply(playerID, "fate_settings_loaded", { ok = 0, status = 0 })
        return
    end

    local req = _G.FateCreateHTTPRequest("GET", host .. "/settings?steamid=" .. steamid)
    req:SetHTTPRequestHeaderValue("X-Fate-Key", _G.FATE_API_KEY)
    req:Send(function(res)
        if res.StatusCode == 200 and res.Body and res.Body ~= "" then
            Reply(playerID, "fate_settings_loaded", { ok = 1, data = res.Body })
        else
            Reply(playerID, "fate_settings_loaded", { ok = 0, status = res.StatusCode or 0 })
        end
    end)
end


function FateSettings:Init()
    if self.initialized then return end
    self.initialized = true

    CustomGameEventManager:RegisterListener("player_save_settings", function(_, args)
        FateSettings:OnSave(args)
    end)
    CustomGameEventManager:RegisterListener("player_load_settings", function(_, args)
        FateSettings:OnLoad(args)
    end)
end
