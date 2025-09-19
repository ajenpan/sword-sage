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
    local args = { ... }
    if #args > 0 then
      msg = msg .. serpent.line(args)
    end
    if SwordSageDebugMod then
      game.print(msg)
    end
    return log(msg)
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
