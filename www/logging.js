/*global cordova, module*/

module.exports = {
    logInfo: function (successCallback, errorCallback, message, destination) {
        cordova.exec(successCallback, errorCallback, "Logging", "logInfo", [message, destination]);
    },
    logDebug: function (successCallback, errorCallback, message, destination) {
        cordova.exec(successCallback, errorCallback, "Logging", "logDebug", [message, destination]);
    },
    logWarn: function (successCallback, errorCallback, message, destination) {
        cordova.exec(successCallback, errorCallback, "Logging", "logWarn", [message, destination]);
    },
    logError: function (successCallback, errorCallback, message, destination) {
        cordova.exec(successCallback, errorCallback, "Logging", "logError", [message, destination]);
    },
    logMessages: function (successCallback, errorCallback, messages) {
        cordova.exec(successCallback, errorCallback, "Logging", "logMessages", [messages]);
    },
    setRootLogLevel: function (successCallback, errorCallback, level, destination) {
        cordova.exec(successCallback, errorCallback, "Logging", "setRootLogLevel", [level, destination]);
    },
    getLogFilePaths: function (successCallback, errorCallback, excludeEmptyFiles) {
        cordova.exec(successCallback, errorCallback, "Logging", "getLogFilePaths", [excludeEmptyFiles]);
    },
    getArchivedLogFilePaths: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "Logging", "getArchivedLogFilePaths", []);
    },
    makeFilesPublic: function (successCallback, errorCallback, paths) {
        cordova.exec(successCallback, errorCallback, "Logging", "makeFilesPublic", [paths]);
    },
    removePublicFiles: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "Logging", "removePublicFiles", []);
    },
    configure: function (successCallback, errorCallback, settings, destination) {
        cordova.exec(successCallback, errorCallback, "Logging", "configure", [settings, destination]);
    },
    enableLogging: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "Logging", "enableLogging", []);
    },
    disableLogging: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "Logging", "disableLogging", []);
    },
    enableDestination: function (successCallback, errorCallback, destination) {
        cordova.exec(successCallback, errorCallback, "Logging", "enableDestination", [destination]);
    },
    disableDestination: function (successCallback, errorCallback, destination) {
        cordova.exec(successCallback, errorCallback, "Logging", "disableDestination", [destination]);
    }, 
    isLoggingEnabled: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "Logging", "isLoggingEnabled", []);
    },
    isDestinationEnabled: function (successCallback, errorCallback, destination) {
        cordova.exec(successCallback, errorCallback, "Logging", "isDestinationEnabled", [destination]);
    },
    zipLogFiles: function (successCallback, errorCallback, includeArchivedLogs) {
        cordova.exec(successCallback, errorCallback, "Logging", "zipLogFiles", [includeArchivedLogs]);
    }
};