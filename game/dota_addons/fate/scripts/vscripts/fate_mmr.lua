-- ============================================================================
-- MMR: рейтинг игроков, автобалансировка команд и начисление за матч.
--
-- Хранилище — общая база (Cloudflare Worker + D1, тот же сервер, что у биндов и
-- статистики). Здесь только игровая часть:
--   1. на входе в CUSTOM_GAME_SETUP (движок пускает туда, КОГДА ВСЕ ПРОГРУЗИЛИСЬ)
--      тянем рейтинги всех подключённых, кладём их в нет-таблицу "mmr" для UI
--      и раскидываем команды так, чтобы средние сравнялись;
--   2. хост может перекинуть команды заново кнопкой на экране выбора команд
--      (событие "mmr_shuffle_request") — например, если кто-то перебежал;
--   3. на старте игры запоминаем состав, а в конце матча просим сервер начислить.
--
-- Считает изменение рейтинга СЕРВЕР (воркер): у него текущие значения всех
-- игроков и одна транзакция. Здесь только гейты и один POST.
--
-- ⚠️ Гейты матча (порог «10 живых») проверяются ДО отправки: в матчах меньше
-- 5+5 на старте / 8 не ушедших к концу запрос вообще не уходит.
-- ============================================================================

if FateMMR == nil then
    FateMMR = {}
end

-- ⚠️⚠️ ЭТОТ ФАЙЛ ТРЕБУЕТСЯ НА 47-Й СТРОКЕ addon_game_mode.lua, а нужные ему
-- глобалы объявлены НИЖЕ: FATE_BINDS_HOST/FATE_API_KEY на 1394, FateServerDisabled
-- на 1408, my_http_post на 5940. Окружение файла в этой сборке движка берётся на
-- момент загрузки, поэтому напрямую они отсюда НЕ ВИДНЫ — в игре это дало
-- «attempt to call global 'FateServerDisabled' (a nil value)», а запрос ушёл бы
-- на nil-адрес с пустым ключом. Обратное направление работает: addon_game_mode
-- видит FateMMR, потому что мы объявляем его при загрузке.
-- Поэтому ВСЁ, что объявлено в addon_game_mode.lua, читаем через _G в МОМЕНТ
-- вызова, а не по имени напрямую.
local function ServerDisabled()
    local f = _G.FateServerDisabled
    if type(f) == "function" then return f() end
    -- запасной вариант — та же логика, что в addon_game_mode.lua
    if _G.FATE_ALLOW_TOOLS_SEND then return false end
    if IsInToolsMode and IsInToolsMode() then return true end
    if GameRules and GameRules.IsCheatMode and GameRules:IsCheatMode() then return true end
    return false
end

-- Секреты тянем и сами: если этот файл когда-нибудь снова загрузят раньше их
-- объявления, адрес и ключ всё равно будут (fate_secrets.lua выставляет глобалы).
pcall(require, "fate_secrets")

local function BindsHost()
    local h = _G.FATE_BINDS_HOST or FATE_BINDS_HOST
    return (h and h ~= "") and h or "http://localhost:8787"
end

local function ApiKey()
    return _G.FATE_API_KEY or FATE_API_KEY or ""
end

-- Рубильник: false — система молчит целиком (ни запросов, ни шафла, ни
-- начисления), остальной аддон работает как раньше. Быстрый откат, если в
-- боевом лобби что-то пойдёт не так.
FATE_MMR_ENABLED = true

-- В tools/чит-лобби рейтинги ЧИТАЕМ (иначе там не посмотреть ни UI, ни шафл),
-- но НИЧЕГО не пишем: начисление всё так же режется FateServerDisabled().
-- Запрос рейтингов read-only, испортить им боевые данные нельзя.
-- ⚠️ Именно поэтому гарды не «закомментированы»: сними их целиком — и тестовый
-- матч из тулсов начислит живым людям настоящий MMR.
FATE_MMR_TOOLS_READ = true

-- Подробные сообщения в чат («запрашиваю рейтинги», «запрос ушёл», «рейтинги
-- загружены»). Нужны на первых боевых матчах, чтобы причина любого сбоя была
-- видна на месте. ⚠️ Когда убедимся, что всё работает — поставить false:
-- ОШИБКИ и результат шафла показываются в любом случае, замолчат только
-- служебные строки.
FATE_MMR_VERBOSE = true

FATE_MMR_DEFAULT = 1000          -- рейтинг игрока, которого сервер ещё не знает
FATE_MMR_MIN_PER_TEAM = 5        -- матч зачитывается от 5 живых в КАЖДОЙ команде
FATE_MMR_MIN_ALIVE_END = 8       -- ...и не меньше 8 не покинувших игру к концу
FATE_MMR_LEAVER_SECONDS = 300    -- ушёл раньше чем за столько до конца — штраф
FATE_MMR_LEAVER_MULT = 2         -- и снимают с него вдвое (см. воркер)
FATE_MMR_LONG_MATCH_SCORE = 20   -- сумма счёта по раундам, после которой матч
                                 -- засчитывается, даже если не доигран
FATE_MMR_WATCH_INTERVAL = 10     -- как часто сторож смотрит на отключения
-- Насколько разбиение может быть хуже идеального, чтобы всё ещё считаться
-- равноценным. Из всех таких выбирается СЛУЧАЙНОЕ (см. ComputeBalance) — иначе
-- составы повторяются из матча в матч. 5 очков расхождения средних меняют
-- начисление меньше чем на очко, то есть честность не страдает.
FATE_MMR_BALANCE_TOLERANCE = 5

FATE_MMR_APPLY_RETRIES = 4       -- сервер отвечает 409, пока меты нет — повторяем
                                 -- (повтор идёт сразу из колбэка: таймеров в
                                 --  POST_GAME уже нет, см. ApplyMatch)

-- Рейтинг работает только на основных двухкомандных картах. FFA и 3v3v3v3 вне
-- системы: там нет двух команд, а значит и «среднего рейтинга противника».
local RATED_MAPS = {
    ["7vs7_common"] = true,
    ["7vs7_draft"] = true,
    ["7vs7_test"] = true,
    ["fate_elim_7v7"] = true,
    ["fate_elim_7v7_test"] = true,
    ["fate_elim_6v6"] = true,
    ["anime_fate_7vs7_beta"] = true,
}

FateMMR.values = FateMMR.values or {}        -- steamid (строка) -> рейтинг
FateMMR.games = FateMMR.games or {}          -- steamid (строка) -> сыграно матчей
FateMMR.ready = false                        -- рейтинги доехали с сервера
FateMMR.autoShuffled = false                 -- автошафл уже сработал
FateMMR.startRoster = nil                    -- состав на старте матча: playerID -> команда
FateMMR.applied = false                      -- начисление за матч уже отправлено
FateMMR.applyOk = false                      -- ...и сервер подтвердил его 200-м
FateMMR.pendingSend = nil                    -- функция повторной отправки

function FateMMR:IsRatedMap()
    if not FATE_MMR_ENABLED then return false end
    return RATED_MAPS[_G.GameMap] == true
end

-- Все валидные игроки, которых можно расставлять по командам (боты тоже —
-- иначе перекос по размеру команд). ⚠️ Зрители ИСКЛЮЧЕНЫ: иначе шафл затащил бы
-- их в игру. Возвращает список {playerID, steamid, mmr, team}.
-- Команда игрока. На экране выбора команд её знает только custom-assignment,
-- а после старта игры — сам игрок; берём то, что есть (порядок важен: в сетапе
-- GetTeam может ещё не догнать перестановку, которую мы только что применили).
function FateMMR:TeamOf(playerID)
    local team = PlayerResource:GetCustomTeamAssignment(playerID)
    if team ~= DOTA_TEAM_GOODGUYS and team ~= DOTA_TEAM_BADGUYS then
        team = PlayerResource:GetTeam(playerID)
    end
    return team
end

function FateMMR:CollectPlayers()
    local out = {}
    for playerID = 0, 23 do
        if PlayerResource:IsValidPlayerID(playerID) then
            local team = self:TeamOf(playerID)
            if team == DOTA_TEAM_GOODGUYS or team == DOTA_TEAM_BADGUYS
               or team == DOTA_TEAM_NOTEAM then
                local steamid = tostring(PlayerResource:GetSteamAccountID(playerID))
                local mmr = self.values[steamid] or FATE_MMR_DEFAULT
                -- В tools у ботов steamid = 0 и рейтинг у всех одинаковый, а
                -- значит балансировать нечего и шафл выглядит как «не работает».
                -- Даём им разброс (детерминированный, чтобы результат повторялся)
                -- — ТОЛЬКО в tools, в настоящем лобби ботов не бывает.
                if steamid == "0" and IsInToolsMode and IsInToolsMode() then
                    mmr = 700 + ((playerID * 137) % 9) * 75
                end
                out[#out + 1] = {
                    playerID = playerID,
                    steamid = steamid,
                    mmr = mmr,
                    team = team,
                }
            end
        end
    end
    return out
end

-- Запрашивает рейтинги у сервера и раскладывает их по нет-таблице.
-- Ответ — плоский текст "id:mmr:игр;id:mmr:игр" (json на стороне Lua нет).
-- Диагностика в чат. На дедике консоли не видно, а понять «почему нет рейтингов»
-- надо на месте: сообщение видят все, оно короткое и только на фазе сетапа.
function FateMMR:Notify(msg)
    print("[FateMMR] " .. msg)
    pcall(function()
        GameRules:SendCustomMessage("<font color='#d7b46a'>[MMR]</font> " .. msg, 0, 0)
    end)
end

-- Служебная строка: в консоль всегда, в чат — только при FATE_MMR_VERBOSE.
-- Всё, что говорит о СБОЕ, идёт через Notify и молчать не должно никогда.
function FateMMR:Debug(msg)
    if FATE_MMR_VERBOSE then
        self:Notify(msg)
    else
        print("[FateMMR] " .. msg)
    end
end

function FateMMR:Fetch(callback)
    if not FATE_MMR_ENABLED then
        if callback then callback(false) end
        return
    end
    if ServerDisabled() then
        if not FATE_MMR_TOOLS_READ then
            self:Notify("лобби с читами или tools-режим — рейтинг отключён")
            if callback then callback(false) end
            return
        end
        -- читаем, но не пишем: начисление всё равно не пройдёт (см. ApplyMatch)
        self:Debug("tools/читы: рейтинги показываем, начисление отключено")
    end
    local players = self:CollectPlayers()
    local ids = {}
    for _, p in ipairs(players) do
        if p.steamid ~= "0" and not PlayerResource:IsFakeClient(p.playerID) then
            ids[#ids + 1] = p.steamid
        end
    end
    -- ⚠️ Раньше эта ветка молчала — и «ничего не происходит» выглядело как
    -- поломка сети. Спрашивать сервер не о ком: в лобби одни боты или tools не
    -- отдаёт SteamAccountID. Рейтинги тогда стартовые, но показать их надо,
    -- иначе на экране команд пусто и непонятно почему.
    if #ids == 0 then
        self.ready = true
        self:Notify("аккаунтов Steam в лобби нет (" .. #players
                    .. " игроков) — показываю стартовые рейтинги")
        self:PublishToUI()
        if callback then callback(true) end
        return
    end

    local req = CreateHTTPRequestScriptVM("GET", BindsHost() .. "/mmr?ids=" .. table.concat(ids, ","))
    req:SetHTTPRequestHeaderValue("X-Fate-Key", ApiKey())
    self:Debug("запрос ушёл (" .. #ids .. " аккаунтов)")
    req:Send(function(res)
        -- Ошибка в этом колбэке иначе нигде не видна (движок её глотает).
        local okCb, errCb = pcall(function()
            if res.StatusCode ~= 200 then
                FateMMR:Notify("сервер рейтингов ответил " .. tostring(res.StatusCode)
                               .. " — рейтинги не загружены")
                if callback then callback(false) end
                return
            end
            local count = 0
            for steamid, mmr, games in string.gmatch(tostring(res.Body), "(%d+):(%-?%d+):(%d+)") do
                FateMMR.values[steamid] = tonumber(mmr)
                FateMMR.games[steamid] = tonumber(games)
                count = count + 1
            end
            FateMMR.ready = true
            FateMMR:Debug("рейтинги загружены: " .. count .. " игроков")
            FateMMR:PublishToUI()
            if callback then callback(true) end
        end)
        if not okCb then
            FateMMR:Notify("ошибка разбора ответа: " .. tostring(errCb))
        end
    end)
end

-- Данные для UI уходят ДВУМЯ путями:
--   * нет-таблица "mmr" — для внутриигрового скорборда (там она точно работает);
--   * событие "mmr_data" — для экрана выбора команд. ⚠️ Доезжает ли нет-таблица
--     до контекста GameSetup, не проверено, а события с того экрана точно ходят
--     (им шлются vote_finished/zones_vote_finished). Дублируем, чтобы показ
--     рейтинга не зависел от недоказанного предположения.
function FateMMR:BuildUIPayload()
    local payload = {}
    local toolsBots = IsInToolsMode and IsInToolsMode()
    for _, p in ipairs(self:CollectPlayers()) do
        if p.steamid ~= "0" or toolsBots then
            payload["p" .. tostring(p.playerID)] = p.mmr
        end
    end
    local sums = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }
    local counts = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }
    for _, p in ipairs(self:CollectPlayers()) do
        if sums[p.team] and (p.steamid ~= "0" or toolsBots) then
            sums[p.team] = sums[p.team] + p.mmr
            counts[p.team] = counts[p.team] + 1
        end
    end
    payload.ready = self.ready and 1 or 0
    payload.rated = self:IsRatedMap() and 1 or 0
    payload.radiant_avg = counts[DOTA_TEAM_GOODGUYS] > 0
        and math.floor(sums[DOTA_TEAM_GOODGUYS] / counts[DOTA_TEAM_GOODGUYS] + 0.5) or 0
    payload.dire_avg = counts[DOTA_TEAM_BADGUYS] > 0
        and math.floor(sums[DOTA_TEAM_BADGUYS] / counts[DOTA_TEAM_BADGUYS] + 0.5) or 0
    return payload
end

-- Клиент экрана выбора команд просит данные сам: он мог создаться позже, чем
-- сервер их разослал.
function OnMMRRequest(eventSourceIndex, args)
    local playerID = args and args.PlayerID
    local player = playerID and PlayerResource:GetPlayer(playerID)
    if player == nil then return end
    CustomGameEventManager:Send_ServerToPlayer(player, "mmr_data", FateMMR:BuildUIPayload())
end

-- Нет-таблица "mmr": строки по playerID для экрана команд и скорборда,
-- плюс строка "teams" со средними и прогнозом изменения.
function FateMMR:PublishToUI()
    local toolsBots = IsInToolsMode and IsInToolsMode()
    for _, p in ipairs(self:CollectPlayers()) do
        CustomNetTables:SetTableValue("mmr", tostring(p.playerID), {
            mmr = p.mmr,
            games = self.games[p.steamid] or 0,
            -- в tools показываем и ботов: иначе на тестовой карте видна одна метка
            rated = (p.steamid ~= "0" or toolsBots) and 1 or 0,
        })
    end
    local sums, counts = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 },
                         { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }
    for _, p in ipairs(self:CollectPlayers()) do
        if sums[p.team] then
            sums[p.team] = sums[p.team] + p.mmr
            counts[p.team] = counts[p.team] + 1
        end
    end
    local radiantAvg = counts[DOTA_TEAM_GOODGUYS] > 0 and sums[DOTA_TEAM_GOODGUYS] / counts[DOTA_TEAM_GOODGUYS] or FATE_MMR_DEFAULT
    local direAvg = counts[DOTA_TEAM_BADGUYS] > 0 and sums[DOTA_TEAM_BADGUYS] / counts[DOTA_TEAM_BADGUYS] or FATE_MMR_DEFAULT

    CustomNetTables:SetTableValue("mmr", "teams", {
        ready = self.ready and 1 or 0,
        rated = self:IsRatedMap() and 1 or 0,
        radiant_avg = math.floor(radiantAvg + 0.5),
        dire_avg = math.floor(direAvg + 0.5),
        -- прогноз для экрана команд: сколько получит победитель (столько же теряет
        -- проигравший). Формула та же, что на сервере, — Elo с K=50.
        radiant_win = self:PredictDelta(radiantAvg, direAvg),
        dire_win = self:PredictDelta(direAvg, radiantAvg),
        radiant_count = counts[DOTA_TEAM_GOODGUYS],
        dire_count = counts[DOTA_TEAM_BADGUYS],
    })

    -- ...и то же самое событием (см. комментарий выше)
    CustomGameEventManager:Send_ServerToAllClients("mmr_data", self:BuildUIPayload())
end

-- Elo, K=50: сколько получит победитель со средним avgWinner против avgLoser.
-- Дублирует формулу воркера — здесь это только предпросмотр для UI, начисляет сервер.
function FateMMR:PredictDelta(avgWinner, avgLoser)
    local expected = 1 / (1 + 10 ^ ((avgLoser - avgWinner) / 400))
    local delta = math.floor(50 * (1 - expected) + 0.5)
    if delta < 10 then delta = 10 end
    if delta > 50 then delta = 50 end
    return delta
end

-- Разбивает игроков на две команды так, чтобы средние рейтинги были максимально
-- близки. Игроков максимум 14, поэтому перебираем ВСЕ разбиения (C(14,7)=3432).
-- Из разбиений, чей баланс не хуже идеального больше чем на
-- FATE_MMR_BALANCE_TOLERANCE, берётся СЛУЧАЙНОЕ — иначе составы повторяются из
-- матча в матч (разбор в комментарии перед вторым проходом ниже).
-- Возвращает playerID -> команда, счёт выбранного разбиения, счёт идеального и
-- число равноценных вариантов. Или nil, если балансировать нечего.
function FateMMR:ComputeBalance()
    local players = self:CollectPlayers()
    if #players < 2 then return nil end

    -- Размеры команд. Сохраняем текущие ТОЛЬКО если они уже ровные (разница не
    -- больше одного): иначе балансировщик увековечил бы перекос вроде 7 на 5,
    -- в котором никакой расстановкой средние не сойдутся.
    local sizeRadiant, sizeDire, unassigned = 0, 0, 0
    for _, p in ipairs(players) do
        if p.team == DOTA_TEAM_GOODGUYS then
            sizeRadiant = sizeRadiant + 1
        elseif p.team == DOTA_TEAM_BADGUYS then
            sizeDire = sizeDire + 1
        else
            unassigned = unassigned + 1
        end
    end
    if unassigned > 0 or math.abs(sizeRadiant - sizeDire) > 1
       or sizeRadiant <= 0 or sizeRadiant >= #players then
        sizeRadiant = math.ceil(#players / 2)
    end

    -- Вместимость команд задана картой (7 на 7vs7). Просить движок посадить
    -- восьмого он всё равно откажется — значит и считать такой вариант нельзя.
    local maxRadiant = GameRules:GetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS) or #players
    local maxDire = GameRules:GetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS) or #players
    if maxRadiant <= 0 then maxRadiant = #players end
    if maxDire <= 0 then maxDire = #players end
    if sizeRadiant > maxRadiant then sizeRadiant = maxRadiant end
    if (#players - sizeRadiant) > maxDire then sizeRadiant = #players - maxDire end
    -- ⚠️ Проверять надо ОБА ограничения после обеих правок: одна поправка может
    -- выбить другую. Если народу больше, чем мест в двух командах (13 человек на
    -- карте 6v6), лучше отказаться и оставить расстановку как есть, чем сажать
    -- лишнего — движок всё равно откажет, и человек останется без команды.
    if sizeRadiant <= 0 or sizeRadiant >= #players
       or sizeRadiant > maxRadiant or (#players - sizeRadiant) > maxDire then
        print("[FateMMR] игроков больше, чем мест в командах — шафл пропущен")
        return nil
    end

    local total = 0
    for _, p in ipairs(players) do total = total + p.mmr end

    -- Досчитываем размер второй команды ПОСЛЕ всех поправок sizeRadiant выше.
    -- Присваиваем в уже объявленную переменную, а не заводим новую с тем же
    -- именем: затенение здесь читалось бы как ошибка.
    sizeDire = #players - sizeRadiant
    local pick = {}

    -- Насколько разъезжаются средние рейтинги команд при данном разбиении.
    local function scoreOf(sum)
        return math.abs(sum / sizeRadiant - (total - sum) / sizeDire)
    end

    -- Полный перебор разбиений (C(14,7)=3432). Проходов ДВА, поэтому что делать
    -- с готовым кандидатом решает переданный visit: первый раз мы только ищем
    -- лучший счёт, второй — выбираем из равноценных.
    local function search(visit, index, chosen, sum)
        if chosen == sizeRadiant then
            visit(scoreOf(sum))
            return
        end
        if index > #players then return end
        -- не хватит оставшихся, чтобы добрать команду
        if (#players - index + 1) < (sizeRadiant - chosen) then return end
        pick[chosen + 1] = index
        search(visit, index + 1, chosen + 1, sum + players[index].mmr)
        search(visit, index + 1, chosen, sum)
    end

    local bestScore = nil
    search(function(score)
        if bestScore == nil or score < bestScore then bestScore = score end
    end, 1, 0, 0)
    if bestScore == nil then return nil end

    -- ⚠️⚠️ ЗДЕСЬ БЫЛ ТАЙ-БРЕЙК «меньше перестановок», и именно он оказался
    -- причиной вечно одинаковых составов. Он выбирал из равноценных разбиений
    -- то, которое трогает меньше людей, — то есть УТВЕРЖДАЛ уже имевшуюся
    -- рассадку (её делал валвовский автоассайн, а тот держит пати вместе).
    -- Хуже того, пары с ОДИНАКОВЫМ рейтингом заводятся сами собой: одинаковый
    -- старт + всегда одна команда = всегда одна дельта = рейтинги не разъезжаются
    -- никогда. Разнести таких двоих не улучшает счёт ни на копейку, значит решал
    -- всегда тай-брейк, а он голосовал «не трогать». В базе таких пар было две,
    -- и обе не разлучались 5 матчей подряд.
    --
    -- Теперь выбираем СЛУЧАЙНОЕ разбиение среди тех, что не хуже оптимума больше
    -- чем на FATE_MMR_BALANCE_TOLERANCE. Выбор — резервуарная выборка (n-й
    -- подходящий кандидат берётся с вероятностью 1/n): даёт равномерный выбор за
    -- один проход и не требует держать в памяти тысячи разбиений.
    -- ⚠️ Побочный эффект намеренный: перестановок теперь больше, экран команд
    -- «шевелится» сильнее. Это цена за то, что составы перестают залипать.
    local limit = bestScore + FATE_MMR_BALANCE_TOLERANCE
    local chosenSet, chosenScore, variants = nil, nil, 0
    search(function(score)
        if score > limit then return end
        variants = variants + 1
        -- RandomInt(1, variants) == 1 — вероятность ровно 1/variants
        if RandomInt(1, variants) == 1 then
            chosenScore = score
            chosenSet = {}
            for i = 1, sizeRadiant do chosenSet[pick[i]] = true end
        end
    end, 1, 0, 0)
    if chosenSet == nil then return nil end

    local best = {}
    for i = 1, #players do
        best[players[i].playerID] = chosenSet[i] and DOTA_TEAM_GOODGUYS or DOTA_TEAM_BADGUYS
    end
    return best, chosenScore, bestScore, variants
end

-- Применяет расстановку. Работает только в CUSTOM_GAME_SETUP: позже движок
-- команды уже не отдаёт.
function FateMMR:Shuffle(reason)
    if not self:IsRatedMap() then
        self:Notify("карта " .. tostring(_G.GameMap) .. " вне рейтинга — шафл пропущен")
        return false
    end
    if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
        self:Notify("шафл возможен только на экране выбора команд")
        return false
    end
    local assignment, score, bestScore, variants = self:ComputeBalance()
    -- ⚠️ Молчаливый выход отсюда выглядел как «кнопка не работает»: жать её
    -- будут именно тогда, когда переставлять нечего (один игрок, пустое лобби).
    if not assignment then
        self:Notify("переставлять некого: игроков в лобби "
                    .. #self:CollectPlayers())
        return false
    end

    -- ⚠️ Применяем В ДВА ПРОХОДА. Команда ограничена по вместимости (7 на 7vs7):
    -- если сажать людей по одному, первый же переход в ещё не освободившуюся
    -- команду движок отклонит, и расстановка выйдет не та, что посчитали.
    -- Поэтому сначала снимаем всех переезжающих в «без команды», потом сажаем.
    local moving = {}
    for playerID, team in pairs(assignment) do
        if PlayerResource:IsValidPlayerID(playerID)
           and PlayerResource:GetCustomTeamAssignment(playerID) ~= team then
            moving[playerID] = team
        end
    end
    local moved = 0
    for playerID, _ in pairs(moving) do
        PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_NOTEAM)
        moved = moved + 1
    end
    for playerID, team in pairs(moving) do
        PlayerResource:SetCustomTeamAssignment(playerID, team)
    end
    -- ⚠️ Эти строки идут через SendCustomMessage, а на экране выбора команд чат
    -- НЕ ВИДЕН — то есть в игре их не прочитать, только в логах дедика. Это не
    -- мелочь: по разбору матчей 02–03.08.2026 шафл отрабатывает не всегда (в 2 из
    -- 3 проверяемых матчей итоговые команды не совпали ни с одним оптимумом), а
    -- отличить «не отработал» от «отработал» на месте сейчас нечем. Пока не
    -- выведем исход на сам экран команд, проверять — по логам.
    -- «вариантов» = сколько равноценных разбиений было на выбор: 1 означает,
    -- что состав жёстко задан рейтингами и повторов не избежать.
    if moved == 0 then
        self:Notify(string.format("команды уже сбалансированы (расхождение средних %.0f)", score or 0))
    else
        self:Notify(string.format(
            "команды пересобраны: переставлено %d, расхождение средних %.0f (идеал %.0f, вариантов %d)",
            moved, score or 0, bestScore or 0, variants or 0))
    end
    -- команды поменялись -> пересчитываем средние и прогноз для UI
    self:PublishToUI()
    return true
end

-- Вход в CUSTOM_GAME_SETUP = все игроки прогрузились. Тянем рейтинги и
-- раскидываем команды один раз; дальше только по кнопке хоста.
function FateMMR:OnCustomGameSetup()
    if not FATE_MMR_ENABLED then return end
    if not self:IsRatedMap() then
        -- Явно говорим, почему рейтинга не будет: иначе «просто ничего не
        -- показывается» и непонятно, дело в карте или в сервере.
        self:Debug("карта " .. tostring(_G.GameMap) .. " вне рейтинга")
        self:PublishToUI()
        return
    end
    self:Debug("запрашиваю рейтинги (" .. tostring(_G.GameMap) .. ")")
    local function afterFetch(ok)
        if not ok then
            -- Без рейтингов балансировать нечем: расстановку не трогаем, чтобы
            -- не выдать случайный шафл за «по MMR».
            FateMMR:Notify("рейтинги не получены — автошафл пропущен")
            FateMMR:PublishToUI()
            return
        end
        if not FateMMR.autoShuffled then
            FateMMR.autoShuffled = true
            FateMMR:Shuffle("auto")
        end
    end
    -- Одна повторная попытка: на входе в сетап игроки ещё доподключаются, да и
    -- HTTP на этой фазе не самый предсказуемый. Второй заход заодно подхватит
    -- тех, кто подключился на пару секунд позже.
    -- ⚠️ Ошибку внутри Fetch наружу не видно: вызов идёт из обработчика смены
    -- состояния, обёрнутого в pcall, а консоли на дедике нет. Поэтому ловим её
    -- здесь и пишем текст прямо в чат — иначе «просто ничего не происходит».
    local ok, err = pcall(function()
        FateMMR:Fetch(function(fetched)
            if fetched then
                afterFetch(true)
                return
            end
            Timers:CreateTimer(3, function()
                if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then return end
                FateMMR:Fetch(afterFetch)
            end)
        end)
    end)
    if not ok then
        self:Notify("ошибка запроса рейтингов: " .. tostring(err))
    end
end

-- Кнопка «Шафл по MMR» на экране выбора команд. Только хост: иначе перед стартом
-- начнётся война кнопок.
function OnMMRShuffleRequest(eventSourceIndex, args)
    local playerID = args.PlayerID
    if playerID == nil then return end
    local player = PlayerResource:GetPlayer(playerID)
    if player == nil then return end
    if not GameRules:PlayerHasCustomGameHostPrivileges(player) then
        FateMMR:Notify("перемешать команды по MMR может только хост")
        return
    end
    if not FateMMR.ready then
        -- рейтинги ещё не доехали (или запрос провалился) — пробуем ещё раз
        FateMMR:Fetch(function(ok)
            if ok then FateMMR:Shuffle("host") end
        end)
        return
    end
    FateMMR:Shuffle("host")
end

-- Состав на старте матча: именно по нему считается порог «5+5», и именно он
-- уезжает на сервер (ливеры остаются в ростере — изменение им засчитывается).
function FateMMR:CaptureStartRoster()
    if not self:IsRatedMap() then return end
    local roster = {}
    local count = 0
    for playerID = 0, 23 do
        if PlayerResource:IsValidPlayerID(playerID) and not PlayerResource:IsFakeClient(playerID) then
            local steamid = tostring(PlayerResource:GetSteamAccountID(playerID))
            local team = PlayerResource:GetTeam(playerID)
            if steamid ~= "0" and (team == DOTA_TEAM_GOODGUYS or team == DOTA_TEAM_BADGUYS) then
                roster[playerID] = { steamid = steamid, team = team }
                count = count + 1
            end
        end
    end
    self.startRoster = roster
    self.leftAt = {}
    print("[FateMMR] состав на старте матча: " .. count .. " игроков")
    self:PublishToUI()
    self:StartWatchdog()
end

-- Текущий счёт по раундам. winnerEventData обновляется в FinishRound на каждом
-- круге, это самый доступный источник вне класса режима.
function FateMMR:RoundScores()
    local r, d = 0, 0
    local wed = _G.winnerEventData          -- объявлен в addon_game_mode, читаем через _G
    if wed then
        r = wed.radiantScore or 0
        d = wed.direScore or 0
    end
    return r, d
end

-- Сторож матча. Делает две вещи:
--   1. запоминает, КОГДА игрок отвалился (и забывает, если он вернулся) — по
--      этому времени считается штраф за ранний выход;
--   2. дотягивает недоигранный матч: если счёт по раундам уже большой, а одна
--      команда разбежалась целиком, матч всё равно засчитывается победой
--      оставшейся команды (иначе «выйти всей толпой» отменяло бы игру).
function FateMMR:StartWatchdog()
    if not self:IsRatedMap() then return end
    local emptyTeamTicks = 0
    Timers:CreateTimer(FATE_MMR_WATCH_INTERVAL, function()
        if not FateMMR.startRoster then return nil end
        local now = Time()
        local connected = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }
        for playerID, info in pairs(FateMMR.startRoster) do
            if PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
                connected[info.team] = connected[info.team] + 1
                FateMMR.leftAt[playerID] = nil          -- вернулся
            elseif FateMMR.leftAt[playerID] == nil then
                FateMMR.leftAt[playerID] = now
            end
        end

        -- матч уже выгружен — сторожить нечего (список ушедших уже собран
        -- синхронно внутри ApplyMatch), таймер выключаем
        if FATE_MATCH_UPLOADED then return nil end
        -- матч ещё не идёт (сетап/пре-гейм) — продолжаем следить
        if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
            return FATE_MMR_WATCH_INTERVAL
        end

        local r, d = FateMMR:RoundScores()
        local teamGone = (connected[DOTA_TEAM_GOODGUYS] == 0 and connected[DOTA_TEAM_BADGUYS] > 0)
                      or (connected[DOTA_TEAM_BADGUYS] == 0 and connected[DOTA_TEAM_GOODGUYS] > 0)
        if teamGone and (r + d) > FATE_MMR_LONG_MATCH_SCORE then
            -- ждём два тика подряд: одиночный может поймать момент переподключения
            emptyTeamTicks = emptyTeamTicks + 1
            if emptyTeamTicks >= 2 then
                local winner = connected[DOTA_TEAM_GOODGUYS] > 0 and DOTA_TEAM_GOODGUYS or DOTA_TEAM_BADGUYS
                print(string.format("[FateMMR] матч не доигран (%d:%d), команда разбежалась — "
                      .. "засчитываем победу %d", r, d, winner))
                local post = _G.my_http_post      -- объявлен ниже по addon_game_mode
                if type(post) == "function" then post(winner) end
                return nil
            end
        else
            emptyTeamTicks = 0
        end
        return FATE_MMR_WATCH_INTERVAL
    end)
end

-- Кто ушёл достаточно давно, чтобы получить штраф. Возвращает список steamid.
function FateMMR:CollectLeavers()
    local out = {}
    if not self.startRoster or not self.leftAt then return out end
    local now = Time()
    for playerID, info in pairs(self.startRoster) do
        local left = self.leftAt[playerID]
        if left ~= nil and (now - left) >= FATE_MMR_LEAVER_SECONDS
           and PlayerResource:GetConnectionState(playerID) ~= DOTA_CONNECTION_STATE_CONNECTED then
            out[#out + 1] = info.steamid
        end
    end
    return out
end

-- Сколько игроков стартового состава ещё в игре (не отключились и не бросили).
function FateMMR:CountAliveFromRoster()
    if not self.startRoster then return 0 end
    local alive = 0
    for playerID, _ in pairs(self.startRoster) do
        local state = PlayerResource:GetConnectionState(playerID)
        if state == DOTA_CONNECTION_STATE_CONNECTED then
            alive = alive + 1
        end
    end
    return alive
end

-- Начисление за матч. Зовётся из my_http_post (конец матча). Все проверки
-- порога — ЗДЕСЬ, до отправки: в неполных матчах запрос не уходит вовсе.
function FateMMR:ApplyMatch(matchId, winnerTeam)
    if self.applied then return end
    if ServerDisabled() then return end
    if not self:IsRatedMap() then
        self:Debug("карта вне рейтинга — начисление пропущено")
        return
    end
    if winnerTeam ~= DOTA_TEAM_GOODGUYS and winnerTeam ~= DOTA_TEAM_BADGUYS then return end
    if not self.startRoster then
        self:Notify("нет стартового состава — начисление пропущено")
        return
    end

    local parts = {}
    local perTeam = { [DOTA_TEAM_GOODGUYS] = 0, [DOTA_TEAM_BADGUYS] = 0 }
    for _, info in pairs(self.startRoster) do
        parts[#parts + 1] = info.steamid .. ":" .. tostring(info.team)
        perTeam[info.team] = perTeam[info.team] + 1
    end
    if perTeam[DOTA_TEAM_GOODGUYS] < FATE_MMR_MIN_PER_TEAM
       or perTeam[DOTA_TEAM_BADGUYS] < FATE_MMR_MIN_PER_TEAM then
        self:Notify(string.format("матч не засчитан: составы %d на %d (нужно %d+%d)",
              perTeam[DOTA_TEAM_GOODGUYS], perTeam[DOTA_TEAM_BADGUYS],
              FATE_MMR_MIN_PER_TEAM, FATE_MMR_MIN_PER_TEAM))
        return
    end
    -- Порог «к концу осталось ≥8» отменяется, если матч был длинным: иначе
    -- команда, разбежавшаяся на 11:10, отменяла бы игру целиком — ровно то, от
    -- чего штраф за ранний выход и придуман.
    local alive = self:CountAliveFromRoster()
    local r, d = self:RoundScores()
    local longMatch = (r + d) > FATE_MMR_LONG_MATCH_SCORE
    if alive < FATE_MMR_MIN_ALIVE_END and not longMatch then
        self:Notify(string.format("матч не засчитан: к концу осталось %d игроков "
              .. "при счёте %d:%d", alive, r, d))
        return
    end

    local leavers = self:CollectLeavers()
    if #leavers > 0 then
        self:Notify("вышедших задолго до конца: " .. #leavers
                    .. " — им снимут вдвое")
    end

    self.applied = true
    local roster = table.concat(parts, ",")
    local leaverList = table.concat(leavers, ",")
    local attempt = 0
    local function send()
        attempt = attempt + 1
        local req = CreateHTTPRequestScriptVM("POST", BindsHost() .. "/mmr/apply")
        req:SetHTTPRequestHeaderValue("X-Fate-Key", ApiKey())
        req:SetHTTPRequestGetOrPostParameter("match_id", matchId)
        req:SetHTTPRequestGetOrPostParameter("winner_team", tostring(winnerTeam))
        req:SetHTTPRequestGetOrPostParameter("roster", roster)
        req:SetHTTPRequestGetOrPostParameter("alive_end", tostring(alive))
        req:SetHTTPRequestGetOrPostParameter("leavers", leaverList)
        req:SetHTTPRequestGetOrPostParameter("score_sum", tostring(r + d))
        req:Send(function(res)
            if res.StatusCode == 200 then
                FateMMR.applyOk = true
                FateMMR:Debug("начисление: " .. tostring(res.Body))
            elseif res.StatusCode ~= 409 then
                FateMMR:Notify("начисление не прошло: " .. tostring(res.StatusCode)
                               .. " " .. tostring(res.Body))
            end
            print("[FateMMR] начисление (" .. matchId .. ") -> " .. tostring(res.StatusCode)
                  .. " " .. tostring(res.Body))
            -- 409 = мета матча ещё не долетела до базы; повторяем СРАЗУ из
            -- колбэка. Пауза между попытками — сам сетевой круг (см. ниже,
            -- почему здесь нельзя Timers).
            if res.StatusCode == 409 and attempt < FATE_MMR_APPLY_RETRIES then
                send()
            end
        end)
    end
    -- ⚠️⚠️ БЕЗ Timers. Начисление уходит в конце матча, а `Timers:Think()`
    -- выходит НИЧЕГО не сделав, как только состояние >= POST_GAME
    -- (libraries/timers.lua). my_http_post зовётся прямо перед SetGameWinner,
    -- поэтому отложенный на 3 секунды запрос не уходил ВООБЩЕ — статистика
    -- матча улетала, а рейтинг молча не начислялся (матчи 01.08.2026).
    --
    -- Отправляем СРАЗУ, в том же кадре, что и мету матча. Гонку «мета ещё не в
    -- базе» держит сам воркер: он ждёт её появления несколько секунд и только
    -- потом отвечает 409. Плюс два запасных пути, оба идемпотентные (повторный
    -- запрос получает «already applied»): RetryApply из колбэка POST /matches и
    -- повтор на 409 из колбэка этого запроса.
    self.pendingSend = send
    send()
end

-- Повторная отправка, если первая не подтвердилась. Зовётся из колбэка
-- POST /matches (мета точно в базе) — на случай, если первый запрос ушёл
-- раньше меты и воркер не дождался её.
function FateMMR:RetryApply()
    if self.applyOk or type(self.pendingSend) ~= "function" then return end
    self.pendingSend()
end
