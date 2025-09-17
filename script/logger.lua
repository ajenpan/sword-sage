LogLevelEnum = {
  Debug = 1,
  Info = 2,
  Warn = 3,
  Error = 4,
}

SwordSageDebugMod = false
LogLevel = LogLevelEnum.Info

function DoLog(level, msg, ...)
  if LogLevel and level >= LogLevel then
    local content = msg .. serpent.line({ ... })
    if SwordSageDebugMod then
      game.print(content)
    end
    return log(content)
  end
end

function LogD(msg, ...)
  DoLog(LogLevelEnum.Debug, msg, ...)
end

function LogI(msg, ...)
  DoLog(LogLevelEnum.Info, msg, ...)
end

function LogW(msg, ...)
  DoLog(LogLevelEnum.Warn, msg, ...)
end

function LogE(msg, ...)
  DoLog(LogLevelEnum.Warn, msg, ...)
end
