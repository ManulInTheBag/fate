StatsClient.Debug = true and (IsInToolsMode() or GameRules:IsCheatMode())
StatsClient.ServerAddress = StatsClient.Debug and "http://127.0.0.1:6502/" or "https://stats.dota-aabs.com/"
StatsClient.RetryDelay = 10
