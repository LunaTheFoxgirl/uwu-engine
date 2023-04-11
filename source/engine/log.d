module engine.log;
import colorize;
import std.format;

enum LogLevel {
    NONE,
    Error,
    Warning,
    Info,
    Debug
}

LogLevel uwuLogLevel = LogLevel.Info;

void uwuLogError(T...)(string message, T data) {
    if (uwuLogLevel < LogLevel.Error) return;
    cwriteln(("[ERROR] "~(message.format(data))).color(fg.red));
}

void uwuLogWarn(T...)(string message, T data) {
    if (uwuLogLevel < LogLevel.Warning) return;
    cwriteln(("[WARN ] "~(message.format(data))).color(fg.yellow));
}

void uwuLogInfo(T...)(string message, T data) {
    if (uwuLogLevel < LogLevel.Info) return;
    cwriteln("[INFO ] "~message.format(data));
}

void uwuLogDebug(T...)(string message, T data) {
    if (uwuLogLevel < LogLevel.Debug) return;
    cwriteln(("[DEBUG] "~(message.format(data))).color(fg.light_blue));
}