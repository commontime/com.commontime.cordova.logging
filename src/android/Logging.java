package com.commontime.plugin;

import org.json.JSONObject;
import org.slf4j.LoggerFactory;
import ch.qos.logback.classic.Level;
import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.LoggerContext;
import ch.qos.logback.classic.encoder.PatternLayoutEncoder;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.rolling.FixedWindowRollingPolicy;
import ch.qos.logback.core.rolling.RollingFileAppender;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.channels.FileChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

import android.Manifest;
import android.app.ProgressDialog;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Environment;
import android.preference.PreferenceManager;
import android.text.TextUtils;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;

public class Logging extends CordovaPlugin {

    static final String LOGGING_DISABLED = "Logging is disabled";

    static final String CLIENT_LOG_FILE_NAME = "client.log";
    static final String DEVELOPER_LOG_FILE_NAME = "developer.log";
    static final String NATIVE_LOG_FILE_NAME = "native.log";
    static final String LOGS_ZIP_FOLDER_NAME = "logs.zip";

    static final String CLIENT_DESTINATION = "client";
    static final String DEVELOPER_DESTINATION = "developer";
    static final String NATIVE_DESTINATION = "native";

    static final String LOG_LEVEL_OFF = "off";
    static final String LOG_LEVEL_INFO = "info";
    static final String LOG_LEVEL_DEBUG = "debug";
    static final String LOG_LEVEL_WARNING = "warn";
    static final String LOG_LEVEL_ERROR = "error";

    static final String LOGGING_ENABLED_KEY = "loggingEnabled";
    static final String CLIENT_LOGGING_ENABLED_KEY = "clientLoggingEnabled";
    static final String DEVELOPER_LOGGING_ENABLED_KEY = "developerLoggingEnabled";
    static final String NATIVE_LOGGING_ENABLED_KEY = "nativeLoggingEnabled";
    static final String CLIENT_ROOT_LOG_LEVEL_KEY = "clientRootLogLevel";
    static final String DEVELOPER_ROOT_LOG_LEVEL_KEY = "developerRootLogLevel";
    static final String NATIVE_ROOT_LOG_LEVEL_KEY = "nativeRootLogLevel";
    static final String CLIENT_MAX_FILE_SIZE_KEY = "clientMaxFileSize";
    static final String CLIENT_MAX_NUMBER_OF_LOG_FILES_KEY = "clientMaxNumberOfLogFiles";
    static final String DEVELOPER_MAX_FILE_SIZE_KEY = "developerMaxFileSize";
    static final String DEVELOPER_MAX_NUMBER_OF_LOG_FILES_KEY = "developerMaxNumberOfLogFiles";
    static final String NATIVE_MAX_FILE_SIZE_KEY = "nativeMaxFileSize";
    static final String NATIVE_MAX_NUMBER_OF_LOG_FILES_KEY = "nativeMaxNumberOfLogFiles";

    public final int WRITE_EXTERNAL_STORAGE_PERMISSION_REQUEST = 657;

    private String logFileStorageLocation;
    private String publicFolderPath;
    private String clientLogFileStoragePath;
    private String developerLogFileStoragePath;
    private String nativeLogFileStoragePath;

    private boolean loggingEnabled = false;
    private boolean developerLoggingEnabled = false;
    private boolean clientLoggingEnabled = false;
    private boolean nativeLoggingEnabled = false;

    private HashMap<String, Logger> loggers;

    private CallbackContext mCallbackContext;

    private JSONArray tmpFilePathsToMakePublic;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView)
    {
        super.initialize(cordova, webView);

        publicFolderPath = Environment.getExternalStorageDirectory().getAbsolutePath() + "/Infinity Logs";
        logFileStorageLocation = cordova.getActivity().getFilesDir() + "/logs/";
        clientLogFileStoragePath = logFileStorageLocation + "client/";
        developerLogFileStoragePath = logFileStorageLocation + "developer/";
        nativeLogFileStoragePath = logFileStorageLocation + "native/";

        createLoggerMap();

        String clientRootLogLevel;
        String developerRootLogLevel;
        String nativeRootLogLevel;
        long clientMaxFileSize;
        int clientMaxNumberOfLogFiles;
        long developerMaxFileSize;
        int developerMaxNumberOfLogFiles;
        long nativeMaxFileSize;
        int nativeMaxNumberOfLogFiles;

        if(isFirstRun())
        {
            loggingEnabled = preferences.getBoolean(LOGGING_ENABLED_KEY, false);

            clientRootLogLevel = preferences.getString(CLIENT_ROOT_LOG_LEVEL_KEY, null);
            developerRootLogLevel = preferences.getString(DEVELOPER_ROOT_LOG_LEVEL_KEY, null);
            nativeRootLogLevel = preferences.getString(NATIVE_ROOT_LOG_LEVEL_KEY, null);

            clientMaxFileSize = preferences.getInteger(CLIENT_MAX_FILE_SIZE_KEY, 0);
            clientMaxNumberOfLogFiles = preferences.getInteger(CLIENT_MAX_NUMBER_OF_LOG_FILES_KEY, 0);

            developerMaxFileSize = preferences.getInteger(DEVELOPER_MAX_FILE_SIZE_KEY, 0);
            developerMaxNumberOfLogFiles = preferences.getInteger(DEVELOPER_MAX_NUMBER_OF_LOG_FILES_KEY, 0);

            nativeMaxFileSize = preferences.getInteger(NATIVE_MAX_FILE_SIZE_KEY, 0);
            nativeMaxNumberOfLogFiles = preferences.getInteger(NATIVE_MAX_NUMBER_OF_LOG_FILES_KEY, 0);
        }
        else
        {
            loggingEnabled = getBooleanFromPrefs(LOGGING_ENABLED_KEY);
            developerLoggingEnabled = getBooleanFromPrefs(DEVELOPER_LOGGING_ENABLED_KEY);
            clientLoggingEnabled = getBooleanFromPrefs(CLIENT_LOGGING_ENABLED_KEY);
            nativeLoggingEnabled = getBooleanFromPrefs(NATIVE_LOGGING_ENABLED_KEY);

            clientRootLogLevel = getStringFromPrefs(CLIENT_ROOT_LOG_LEVEL_KEY);
            developerRootLogLevel = getStringFromPrefs(DEVELOPER_ROOT_LOG_LEVEL_KEY);
            nativeRootLogLevel = getStringFromPrefs(NATIVE_ROOT_LOG_LEVEL_KEY);

            clientMaxFileSize = getLongFromPrefs(CLIENT_MAX_FILE_SIZE_KEY);
            clientMaxNumberOfLogFiles = getIntFromPrefs(CLIENT_MAX_NUMBER_OF_LOG_FILES_KEY);

            developerMaxFileSize = getLongFromPrefs(DEVELOPER_MAX_FILE_SIZE_KEY);
            developerMaxNumberOfLogFiles = getIntFromPrefs(DEVELOPER_MAX_NUMBER_OF_LOG_FILES_KEY);

            nativeMaxFileSize = getLongFromPrefs(NATIVE_MAX_FILE_SIZE_KEY);
            nativeMaxNumberOfLogFiles = getIntFromPrefs(NATIVE_MAX_NUMBER_OF_LOG_FILES_KEY);
        }

        if(clientRootLogLevel != null)
        {
            try {
                setRootLogLevel(clientRootLogLevel, CLIENT_DESTINATION);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        if(developerRootLogLevel != null)
        {
            try {
                setRootLogLevel(developerRootLogLevel, DEVELOPER_DESTINATION);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        if(nativeRootLogLevel != null)
        {
            try {
                setRootLogLevel(nativeRootLogLevel, NATIVE_DESTINATION);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        if(clientMaxFileSize > 0 || clientMaxNumberOfLogFiles > 0)
        {
            try
            {
                JSONObject clientSettings = new JSONObject();
                if(clientMaxFileSize > 0)
                {
                    clientSettings.put("maxFileSize", clientMaxFileSize);
                }
                if(clientMaxNumberOfLogFiles > 0)
                {
                    clientSettings.put("maxNumberOfFiles", clientMaxNumberOfLogFiles);
                }
                configure(clientSettings, CLIENT_DESTINATION);
            }
            catch (JSONException e){}
        }

        if(developerMaxFileSize > 0 || developerMaxNumberOfLogFiles > 0)
        {
            try
            {
                JSONObject developerSettings = new JSONObject();
                if(developerMaxFileSize > 0)
                {
                    developerSettings.put("maxFileSize", developerMaxFileSize);
                }
                if(developerMaxNumberOfLogFiles > 0)
                {
                    developerSettings.put("maxNumberOfFiles", developerMaxNumberOfLogFiles);
                }
                configure(developerSettings, DEVELOPER_DESTINATION);
            }
            catch (JSONException e){}
        }

        if(nativeMaxFileSize > 0 || nativeMaxNumberOfLogFiles > 0)
        {
            try
            {
                JSONObject nativeSettings = new JSONObject();
                if(nativeMaxFileSize > 0)
                {
                    nativeSettings.put("maxFileSize", nativeMaxFileSize);
                }
                if(nativeMaxNumberOfLogFiles > 0)
                {
                    nativeSettings.put("maxNumberOfFiles", nativeMaxNumberOfLogFiles);
                }
                configure(nativeSettings, NATIVE_DESTINATION);
            }
            catch (JSONException e){}
        }
    }

    @Override
    public boolean execute(final String action, final JSONArray data, final CallbackContext callbackContext) throws JSONException
    {
        mCallbackContext = callbackContext;

        if(action.equals("logInfo") || action.equals("logDebug") || action.equals("logWarn") || action.equals("logError"))
        {
            if(!loggingEnabled)
            {
                callbackContext.error(LOGGING_DISABLED);
                return true;
            }

            final String msg = data.getString(0);

            if(TextUtils.isEmpty(msg))
            {
                callbackContext.error("No message provided");
                return true;
            }

            final List<String> loggerArray = createLoggerArrayFromArgument(data.get(1));

            if(loggerArray == null)
            {
                callbackContext.error("No logger or loggers specified");
                return true;
            }

            cordova.getThreadPool().execute(new Runnable()
            {
                @Override
                public void run()
                {
                    try {
                        if (action.equals("logInfo")) {
                            logInfo(msg, loggerArray);
                        } else if (action.equals("logDebug")) {
                            logDebug(msg, loggerArray);
                        } else if (action.equals("logWarn")) {
                            logWarn(msg, loggerArray);
                        } else if (action.equals("logError")) {
                            logError(msg, loggerArray);
                        }
                    } catch(JSONException e) {
                    }
                }
            });

        }
        else if(action.equals("logMessages"))
        {
            if(!loggingEnabled)
            {
                callbackContext.error(LOGGING_DISABLED);
                return true;
            }

            cordova.getThreadPool().execute(new Runnable() {
                @Override
                public void run()
                {
                    try {
                        JSONArray messages = data.getJSONArray(0);
                        for(int msgIndex = 0 ; msgIndex < messages.length() ; msgIndex++)
                        {
                            JSONObject message = messages.getJSONObject(msgIndex);
                            String logLevel = message.getString("logLevel");

                            List<String> loggerArray = createLoggerArrayFromArgument(message.get("destination"));

                            if(logLevel.equalsIgnoreCase(LOG_LEVEL_INFO))
                            {
                                logInfo(message.getString("message"), loggerArray);
                            }
                            else if(logLevel.equalsIgnoreCase(LOG_LEVEL_DEBUG))
                            {
                                logDebug(message.getString("message"), loggerArray);
                            }
                            else if(logLevel.equalsIgnoreCase(LOG_LEVEL_WARNING))
                            {
                                logWarn(message.getString("message"), loggerArray);
                            }
                            else if(logLevel.equalsIgnoreCase(LOG_LEVEL_ERROR))
                            {
                                logError(message.getString("message"), loggerArray);
                            }
                        }
                        callbackContext.success();
                    } catch(JSONException e) {
                        callbackContext.error("");
                    }
                }
            });
        }
        else if(action.equals("setRootLogLevel"))
        {
            String desiredLevel = data.getString(0);
            String destination = data.getString(1);

            if(TextUtils.isEmpty(desiredLevel))
            {
                callbackContext.error("No log level specified");
                return true;
            }

            if(destination == null)
            {
                callbackContext.error("No destination specified");
                return true;
            }

            boolean set = setRootLogLevel(desiredLevel, destination);

            if(set)
            {
                callbackContext.success();
            }
            else
            {
                callbackContext.error("Unable to set root level");
            }
        }
        else if(action.equals("getRootLogLevel"))
        {
            String destination = data.getString(0);

            if(destination == null)
            {
                callbackContext.error("No destination specified");
                return true;
            }

            Logger l = loggers.get(destination);

            if(l != null)
            {
                callbackContext.success(l.getLevel().levelStr.toLowerCase());
            }
            else
            {
                callbackContext.error("Destination not found");
            }
        }
        else if(action.equals("getLogFilePaths"))
        {
            JSONObject filePaths = getLogFilePaths();
            callbackContext.success(filePaths);
        }
        else if(action.equals("getArchivedLogFilePaths"))
        {
            JSONObject filePaths = getArchivedLogFilePaths();
            callbackContext.success(filePaths);
        }
        else if(action.equals("makeFilesPublic"))
        {
            JSONArray filePaths = null;

            if(data instanceof JSONArray)
            {
                filePaths = data;
            }

            if(filePaths == null)
            {
                return true;
            }

            if(Build.VERSION.SDK_INT >= 23)
            {
                if (!cordova.hasPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE))
                {
                    tmpFilePathsToMakePublic = filePaths;
                    cordova.requestPermissions(this, WRITE_EXTERNAL_STORAGE_PERMISSION_REQUEST, new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE});
                }
                else
                {
                    copyFilesToPublicDirectoryAndReturnPaths(filePaths);
                }
            }
            else
            {
                copyFilesToPublicDirectoryAndReturnPaths(filePaths);
            }
        }
        else if(action.equals("removePublicFiles"))
        {
            deleteDirectory(new File(publicFolderPath));
            callbackContext.success();
        }
        else if(action.equals("zipLogFiles"))
        {
            Boolean includeArchivedFiles = false;

            if(data.get(0) instanceof Boolean)
            {
                includeArchivedFiles = data.getBoolean(0);
            }

            new AsyncTask<Boolean, Void, String>()
            {
                ProgressDialog progress;

                @Override
                protected void onPreExecute()
                {
                    super.onPreExecute();
                    progress = new ProgressDialog(cordova.getActivity());
                    progress.setMessage("Please wait");
                    progress.setCancelable(false);
                    progress.show();
                }

                @Override
                protected String doInBackground(Boolean... params)
                {
                    try
                    {
                        List<String> filePathsToZip = new ArrayList<String>();

                        JSONObject pathInfo = getLogFilePaths();

                        Iterator<String> iter = pathInfo.keys();
                        while (iter.hasNext())
                        {
                            String key = iter.next();
                            try
                            {
                                String filePath = pathInfo.getString(key);
                                filePathsToZip.add(filePath);
                            }
                            catch (JSONException e) {
                                e.printStackTrace();
                            }
                        }

                        if(params[0])
                        {
                            JSONObject archivedPathInfo = getArchivedLogFilePaths();

                            Iterator<String> iter2 = archivedPathInfo.keys();
                            while (iter2.hasNext())
                            {
                                String key = iter2.next();
                                try
                                {
                                    List<String> archivedLogFilePaths = (List) archivedPathInfo.get(key);
                                    if(archivedLogFilePaths != null)
                                    {
                                        filePathsToZip.addAll(archivedLogFilePaths);
                                    }
                                }
                                catch (JSONException e) {
                                    e.printStackTrace();
                                }
                            }
                        }

                        File tmpToZipFolder = new File(cordova.getActivity().getFilesDir(), "tmpToZipFolder");

                        tmpToZipFolder.mkdir();

                        File zipFile = new File(logFileStorageLocation, LOGS_ZIP_FOLDER_NAME);

                        if(zipFile.exists())
                            zipFile.delete();

                        for(String filePath : filePathsToZip)
                        {
                            String fileName = filePath.substring(filePath.lastIndexOf("/")+1);

                            fileName = fileName.replace("%20", " ");

                            File inputFile = new File(filePath);
                            File outputFile = new File(tmpToZipFolder, fileName);

                            copy(inputFile, outputFile);
                        }

                        ZipUtility.zipDirectory(tmpToZipFolder, zipFile);

                        deleteDirectory(tmpToZipFolder);

                        return zipFile.getAbsolutePath();
                    }
                    catch (Exception e)
                    {
                        return null;
                    }
                }

                @Override
                protected void onPostExecute(String zipPath)
                {
                    super.onPostExecute(zipPath);

                    progress.dismiss();

                    if(zipPath != null)
                    {
                        mCallbackContext.success(zipPath);
                    }
                    else
                    {
                        mCallbackContext.error("Error zipping up logs");
                    }
                }
            }.execute(includeArchivedFiles);
        }
        else if(action.equals("configure"))
        {
            JSONObject settings = data.getJSONObject(0);
            Object destination = data.get(1);
            configure(settings, destination);
        }
        else if(action.equals("enableLogging"))
        {
            loggingEnabled = true;
            putBooleanInPrefs(LOGGING_ENABLED_KEY, false);
            callbackContext.success();
        }
        else if(action.equals("disableLogging"))
        {
            loggingEnabled = false;
            putBooleanInPrefs(LOGGING_ENABLED_KEY, true);
            callbackContext.success();
        }
        else if(action.equals("enableDestination"))
        {
            String destination = data.getString(0);

            if(TextUtils.isEmpty(destination))
            {
                callbackContext.error("no destination specified");
                return true;
            }

            enableDestination(destination);

            callbackContext.success();
        }
        else if(action.equals("disableDestination"))
        {
            String destination = data.getString(0);

            if(TextUtils.isEmpty(destination))
            {
                callbackContext.error("no destination specified");
                return true;
            }

            disableDestination(destination);

            callbackContext.success();
        }
        else if(action.equals("isLoggingEnabled"))
        {
            PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, loggingEnabled);
            callbackContext.sendPluginResult(pluginResult);
        }
        else if(action.equals("isDestinationEnabled"))
        {
            String destination = data.getString(0);

            if(TextUtils.isEmpty(destination))
            {
                callbackContext.error("no destination specified");
                return true;
            }

            PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, isDestinationEnabled(destination));
            callbackContext.sendPluginResult(pluginResult);
        }

        return true;
    }

    private JSONObject getLogFilePaths() throws JSONException
    {
        JSONObject paths = new JSONObject();

        File developerFileStorageDir = new File(developerLogFileStoragePath);
        for(File file : developerFileStorageDir.listFiles())
        {
            if(file.getName().equals(DEVELOPER_LOG_FILE_NAME))
            {
                if (file.length() > 0)
                {
                    paths.put(DEVELOPER_DESTINATION, file.getAbsolutePath());
                }
            }
        }

        File clientFileStorageDir = new File(clientLogFileStoragePath);
        for(File file : clientFileStorageDir.listFiles())
        {
            if(file.getName().equals(CLIENT_LOG_FILE_NAME))
            {
                if (file.length() > 0)
                {
                    paths.put(CLIENT_DESTINATION, file.getAbsolutePath());
                }
            }
        }

        File nativeFileStorageDir = new File(nativeLogFileStoragePath);
        for(File file : nativeFileStorageDir.listFiles())
        {
            if(file.getName().equals(NATIVE_LOG_FILE_NAME))
            {
                if (file.length() > 0)
                {
                    paths.put(NATIVE_DESTINATION, file.getAbsolutePath());
                }
            }
        }

        return paths;
    }

    private JSONObject getArchivedLogFilePaths() throws JSONException
    {
        JSONObject paths = new JSONObject();

        File developerFileStorageDir = new File(developerLogFileStoragePath);
        List<String> developerPaths = new ArrayList<String>();
        for(File file : developerFileStorageDir.listFiles())
        {
            if(!file.getName().equals(DEVELOPER_LOG_FILE_NAME))
            {
                developerPaths.add(file.getAbsolutePath());
            }
        }
        if(developerPaths.size() > 0)
        {
            paths.put(DEVELOPER_DESTINATION, developerPaths);
        }

        File clientFileStorageDir = new File(clientLogFileStoragePath);
        List<String> clientPaths = new ArrayList<String>();
        for(File file : clientFileStorageDir.listFiles())
        {
            if(!file.getName().equals(CLIENT_LOG_FILE_NAME))
            {
                clientPaths.add(file.getAbsolutePath());
            }
        }
        if(clientPaths.size() > 0)
        {
            paths.put(DEVELOPER_DESTINATION, clientPaths);
        }

        File nativeFileStorageDir = new File(nativeLogFileStoragePath);
        List<String> nativePaths = new ArrayList<String>();
        for(File file : nativeFileStorageDir.listFiles())
        {
            if(!file.getName().equals(NATIVE_LOG_FILE_NAME))
            {
                nativePaths.add(file.getAbsolutePath());
            }
        }
        if(nativePaths.size() > 0)
        {
            paths.put(NATIVE_DESTINATION, nativePaths);
        }

        return paths;
    }

    private void copyFilesToPublicDirectoryAndReturnPaths(final JSONArray filePaths)
    {
        new AsyncTask<Void, Void, Boolean>()
        {
            ProgressDialog progress;

            @Override
            protected void onPreExecute()
            {
                super.onPreExecute();
                progress = new ProgressDialog(cordova.getActivity());
                progress.setMessage("Please wait");
                progress.setCancelable(false);
                progress.show();
            }

            @Override
            protected Boolean doInBackground(Void... params)
            {
                try
                {
                    for(int index = 0 ; index < filePaths.length() ; index++)
                    {
                        String filePath = filePaths.getString(index);
                        File srcFile = new File(filePath);
                        File publicFolder = new File(publicFolderPath);
                        if(!publicFolder.exists())
                        {
                            publicFolder.mkdir();
                        }
                        copy(new File(filePath), new File(publicFolder, srcFile.getName()));
                    }

                    return true;
                }
                catch (Exception e)
                {
                    return false;
                }
            }

            @Override
            protected void onPostExecute(Boolean success)
            {
                super.onPostExecute(success);

                progress.dismiss();

                if(success)
                {
                    JSONArray filePathsToReturn = new JSONArray();

                    File publicFolderDir = new File(publicFolderPath);
                    if(publicFolderDir.listFiles() != null)
                    {
                        for (File file : publicFolderDir.listFiles())
                        {
                            if (file.length() > 0)
                            {
                                filePathsToReturn.put("file://" + file.getAbsolutePath());
                            }
                        }
                    }

                    mCallbackContext.success(filePathsToReturn);
                }
                else
                {
                    mCallbackContext.error("Error making files public");
                }
            }
        }.execute();
    }

    private void configure(JSONObject settings, Object destination) throws JSONException
    {
        List<String> loggerArray;

        if(destination instanceof String || destination instanceof JSONArray)
        {
            loggerArray = createLoggerArrayFromArgument(destination);
        }
        else
        {
            loggerArray = new ArrayList<String>();
            loggerArray.add(CLIENT_DESTINATION);
            loggerArray.add(DEVELOPER_DESTINATION);
            loggerArray.add(NATIVE_DESTINATION);
        }

        long maxFileSize = settings.getLong("maxFileSize");
        int maxNumberOfFiles = settings.getInt("maxNumberOfFiles");

        for(String loggerName : loggerArray)
        {
            Logger logger = loggers.get(loggerName);
            RollingFileAppender fileAppender = (RollingFileAppender) logger.getAppender(loggerName + "-file");
            if(fileAppender == null)
                continue;
            FixedWindowRollingPolicy rollingPolicy = (FixedWindowRollingPolicy) fileAppender.getRollingPolicy();
            if(rollingPolicy != null)
            {
                if(maxNumberOfFiles > 0)
                {
                    if(maxNumberOfFiles < rollingPolicy.getMaxIndex()+1)
                    {
                        File loggerFolder = null;

                        if(loggerName.equals(CLIENT_DESTINATION))
                        {
                            loggerFolder = new File(clientLogFileStoragePath);
                        }
                        else if(loggerName.equals(DEVELOPER_DESTINATION))
                        {
                            loggerFolder = new File(developerLogFileStoragePath);
                        }
                        else if(loggerName.equals(NATIVE_DESTINATION))
                        {
                            loggerFolder = new File(nativeLogFileStoragePath);
                        }
                        if(loggerFolder != null)
                        {
                            File[] logFiles = loggerFolder.listFiles();
                            if (logFiles.length > maxNumberOfFiles)
                            {
                                for (int index2 = maxNumberOfFiles; index2 < logFiles.length; index2++)
                                {
                                    logFiles[index2].delete();
                                }
                            }
                        }
                    }

                    rollingPolicy.setMinIndex(1);
                    rollingPolicy.setMaxIndex(maxNumberOfFiles - 1);
                    if(loggerName.equals(CLIENT_DESTINATION))
                    {
                        putIntInPrefs(CLIENT_MAX_NUMBER_OF_LOG_FILES_KEY, maxNumberOfFiles);
                    }
                    else if(loggerName.equals(DEVELOPER_DESTINATION))
                    {
                        putIntInPrefs(DEVELOPER_MAX_NUMBER_OF_LOG_FILES_KEY, maxNumberOfFiles);
                    }
                    else if(loggerName.equals(NATIVE_DESTINATION))
                    {
                        putIntInPrefs(NATIVE_MAX_NUMBER_OF_LOG_FILES_KEY, maxNumberOfFiles);
                    }
                }
            }
            CustomSizeBasedTriggeringPolicy triggerPolicy = (CustomSizeBasedTriggeringPolicy) fileAppender.getTriggeringPolicy();
            if(triggerPolicy != null)
            {
                if (maxFileSize > 0)
                {
                    triggerPolicy.setMaxFileSize(String.valueOf(maxFileSize));
                    if(loggerName.equals(CLIENT_DESTINATION))
                    {
                        putLongInPrefs(CLIENT_MAX_FILE_SIZE_KEY, maxFileSize);
                    }
                    else if(loggerName.equals(DEVELOPER_DESTINATION))
                    {
                        putLongInPrefs(DEVELOPER_MAX_FILE_SIZE_KEY, maxFileSize);
                    }
                    else if(loggerName.equals(NATIVE_DESTINATION))
                    {
                        putLongInPrefs(NATIVE_MAX_FILE_SIZE_KEY, maxFileSize);
                    }
                }
            }

        }
    }

    private boolean setRootLogLevel(String desiredLevel, String destination) throws JSONException
    {
        Level level = null;
        if(desiredLevel.equalsIgnoreCase(LOG_LEVEL_OFF))
        {
            disableDestination(destination);
            return true;
        }
        else
        {
            enableDestination(destination);
        }
        if(desiredLevel.equalsIgnoreCase(LOG_LEVEL_INFO))
        {
            level = Level.INFO;
        }
        else if(desiredLevel.equalsIgnoreCase(LOG_LEVEL_DEBUG))
        {
            level = Level.DEBUG;
        }
        else if(desiredLevel.equalsIgnoreCase(LOG_LEVEL_WARNING))
        {
            level = Level.WARN;
        }
        else if(desiredLevel.equalsIgnoreCase(LOG_LEVEL_ERROR))
        {
            level = Level.ERROR;
        }
        if(level != null)
        {
            List<String> loggerArray = createLoggerArrayFromArgument(destination);

            if (loggers != null)
            {
                for (String loggerName : loggerArray)
                {
                    Logger l = loggers.get(loggerName);
                    if (l == null)
                    {
                        continue;
                    }
                    l.setLevel(level);
                    if(loggerName.equals(CLIENT_DESTINATION))
                    {
                        putStringInPrefs(CLIENT_ROOT_LOG_LEVEL_KEY, desiredLevel);
                    }
                    else if(loggerName.equals(DEVELOPER_DESTINATION))
                    {
                        putStringInPrefs(DEVELOPER_ROOT_LOG_LEVEL_KEY, desiredLevel);
                    }
                    else if(loggerName.equals(NATIVE_DESTINATION))
                    {
                        putStringInPrefs(NATIVE_ROOT_LOG_LEVEL_KEY, desiredLevel);
                    }
                }
            }

            return true;
        }
        else
        {
            return false;
        }
    }

    private void enableDestination(String destination)
    {
        if (destination.equalsIgnoreCase(DEVELOPER_DESTINATION))
        {
            developerLoggingEnabled = true;
            putBooleanInPrefs(DEVELOPER_LOGGING_ENABLED_KEY, true);
        }
        else if (destination.equalsIgnoreCase(CLIENT_DESTINATION))
        {
            clientLoggingEnabled = true;
            putBooleanInPrefs(CLIENT_LOGGING_ENABLED_KEY, true);
        }
        else if (destination.equalsIgnoreCase(NATIVE_DESTINATION))
        {
            nativeLoggingEnabled = true;
            putBooleanInPrefs(NATIVE_LOGGING_ENABLED_KEY, true);
        }
    }

    private void disableDestination(String destination)
    {
        if (destination.equalsIgnoreCase(DEVELOPER_DESTINATION))
        {
            developerLoggingEnabled = false;
            putBooleanInPrefs(DEVELOPER_LOGGING_ENABLED_KEY, false);
        }
        else if (destination.equalsIgnoreCase(CLIENT_DESTINATION))
        {
            clientLoggingEnabled = false;
            putBooleanInPrefs(CLIENT_LOGGING_ENABLED_KEY, false);
        }
        else if (destination.equalsIgnoreCase(NATIVE_DESTINATION))
        {
            nativeLoggingEnabled = false;
            putBooleanInPrefs(NATIVE_LOGGING_ENABLED_KEY, false);
        }
    }

    private boolean isDestinationEnabled(String destination)
    {
        if (destination.equalsIgnoreCase(DEVELOPER_DESTINATION))
        {
            return developerLoggingEnabled;
        }
        else if (destination.equalsIgnoreCase(CLIENT_DESTINATION))
        {
            return clientLoggingEnabled;
        }
        else if (destination.equalsIgnoreCase(NATIVE_DESTINATION))
        {
            return nativeLoggingEnabled;
        }
        return false;
    }

    private void createLoggerMap()
    {
        if(loggers != null)
            return;
        loggers = new HashMap<String, Logger>();

        LoggerContext lc = (LoggerContext)LoggerFactory.getILoggerFactory();
        lc.reset();

        // Developer logger

        RollingFileAppender<ILoggingEvent> developerFileAppender = new RollingFileAppender<ILoggingEvent>();
        developerFileAppender.setName("developer-file");
        developerFileAppender.setContext(lc);
        developerFileAppender.setFile(developerLogFileStoragePath + DEVELOPER_LOG_FILE_NAME);
        developerFileAppender.setAppend(true);

        PatternLayoutEncoder developerEncoder = new PatternLayoutEncoder();
        developerEncoder.setContext(lc);
        developerEncoder.setPattern("%msg%n");
        developerEncoder.start();

        FixedWindowRollingPolicy developerRollingPolicy = new FixedWindowRollingPolicy();
        developerRollingPolicy.setContext(lc);
        developerRollingPolicy.setFileNamePattern(developerLogFileStoragePath + "developer %i.log");
        developerRollingPolicy.setMinIndex(1);
        developerRollingPolicy.setMaxIndex(4);
        developerRollingPolicy.setParent(developerFileAppender);
        developerRollingPolicy.start();

        CustomSizeBasedTriggeringPolicy developerTriggeringPolicy = new CustomSizeBasedTriggeringPolicy();
        developerTriggeringPolicy.setContext(lc);
        developerTriggeringPolicy.setMaxFileSize("1MB");
        developerTriggeringPolicy.start();

        developerFileAppender.setEncoder(developerEncoder);
        developerFileAppender.setRollingPolicy(developerRollingPolicy);
        developerFileAppender.setTriggeringPolicy(developerTriggeringPolicy);
        developerFileAppender.start();

        Logger developerLogger = (Logger) LoggerFactory.getLogger("developer");
        developerLogger.addAppender(developerFileAppender);
        developerLogger.setLevel(Level.ERROR);
        developerLogger.setAdditive(false);

        loggers.put(DEVELOPER_DESTINATION, developerLogger);

        // Developer logger

        // Client logger

        RollingFileAppender<ILoggingEvent> clientFileAppender = new RollingFileAppender<ILoggingEvent>();
        clientFileAppender.setName("client-file");
        clientFileAppender.setContext(lc);
        clientFileAppender.setFile(clientLogFileStoragePath + CLIENT_LOG_FILE_NAME);
        clientFileAppender.setAppend(true);

        PatternLayoutEncoder clientEncoder = new PatternLayoutEncoder();
        clientEncoder.setContext(lc);
        clientEncoder.setPattern("%msg%n");
        clientEncoder.start();

        FixedWindowRollingPolicy clientRollingPolicy = new FixedWindowRollingPolicy();
        clientRollingPolicy.setContext(lc);
        clientRollingPolicy.setFileNamePattern(clientLogFileStoragePath + "client %i.log");
        clientRollingPolicy.setMinIndex(1);
        clientRollingPolicy.setMaxIndex(4);
        clientRollingPolicy.setParent(clientFileAppender);
        clientRollingPolicy.start();

        CustomSizeBasedTriggeringPolicy clientTriggeringPolicy = new CustomSizeBasedTriggeringPolicy();
        clientTriggeringPolicy.setContext(lc);
        clientTriggeringPolicy.setMaxFileSize("1MB");
        clientTriggeringPolicy.start();

        clientFileAppender.setEncoder(clientEncoder);
        clientFileAppender.setRollingPolicy(clientRollingPolicy);
        clientFileAppender.setTriggeringPolicy(clientTriggeringPolicy);
        clientFileAppender.start();

        Logger clientLogger = (Logger) LoggerFactory.getLogger("client");
        clientLogger.addAppender(clientFileAppender);
        clientLogger.setLevel(Level.ERROR);
        clientLogger.setAdditive(false);

        loggers.put(CLIENT_DESTINATION, clientLogger);

        // Client logger

        // Native logger

        RollingFileAppender<ILoggingEvent> nativeFileAppender = new RollingFileAppender<ILoggingEvent>();
        nativeFileAppender.setName("native-file");
        nativeFileAppender.setContext(lc);
        nativeFileAppender.setFile(nativeLogFileStoragePath + NATIVE_LOG_FILE_NAME);
        nativeFileAppender.setAppend(true);

        PatternLayoutEncoder nativeEncoder = new PatternLayoutEncoder();
        nativeEncoder.setContext(lc);
        nativeEncoder.setPattern("[%date{d-M-yyyy HH:mm:ss.SSS}] [%level] %msg%n");
        nativeEncoder.start();

        FixedWindowRollingPolicy nativeRollingPolicy = new FixedWindowRollingPolicy();
        nativeRollingPolicy.setContext(lc);
        nativeRollingPolicy.setFileNamePattern(nativeLogFileStoragePath + "native %i.log");
        nativeRollingPolicy.setMinIndex(1);
        nativeRollingPolicy.setMaxIndex(4);
        nativeRollingPolicy.setParent(nativeFileAppender);
        nativeRollingPolicy.start();

        CustomSizeBasedTriggeringPolicy nativeTriggeringPolicy = new CustomSizeBasedTriggeringPolicy();
        nativeTriggeringPolicy.setContext(lc);
        nativeTriggeringPolicy.setMaxFileSize("1MB");
        nativeTriggeringPolicy.start();

        nativeFileAppender.setEncoder(nativeEncoder);
        nativeFileAppender.setRollingPolicy(nativeRollingPolicy);
        nativeFileAppender.setTriggeringPolicy(nativeTriggeringPolicy);

        nativeFileAppender.start();

        Logger nativeLogger = (Logger) LoggerFactory.getLogger("native");
        nativeLogger.addAppender(nativeFileAppender);
        nativeLogger.setLevel(Level.ERROR);
        nativeLogger.setAdditive(false);

        loggers.put(NATIVE_DESTINATION, nativeLogger);

        // Native logger
    }

    private void logInfo(String msg, List<String> loggerArray) throws JSONException
    {
        if(!loggingEnabled)
            return;

        if(loggers != null)
        {
            for (String loggerName : loggerArray)
            {
                if(isDestinationEnabled(loggerName))
                {
                    Logger l = loggers.get(loggerName);
                    if (l != null)
                        l.info(msg);
                }
            }
        }
    }

    private void logDebug(String msg, List<String> loggerArray) throws JSONException
    {
        if(!loggingEnabled)
            return;

        if(loggers != null)
        {
            for (String loggerName : loggerArray)
            {
                if(isDestinationEnabled(loggerName))
                {
                    Logger l = loggers.get(loggerName);
                    if (l != null)
                        l.debug(msg);
                }
            }
        }
    }

    private void logWarn(String msg, List<String> loggerArray) throws JSONException
    {
        if(!loggingEnabled)
            return;

        if(loggers != null)
        {
            for (String loggerName : loggerArray)
            {
                if(isDestinationEnabled(loggerName))
                {
                    Logger l = loggers.get(loggerName);
                    if (l != null)
                        l.warn(msg);
                }
            }
        }
    }

    private void logError(String msg, List<String> loggerArray) throws JSONException
    {
        if(!loggingEnabled)
            return;

        if(loggers != null)
        {
            for (String loggerName : loggerArray)
            {
                if(isDestinationEnabled(loggerName))
                {
                    Logger l = loggers.get(loggerName);
                    if (l != null)
                        l.error(msg);
                }
            }
        }
    }

    public void logNativeInfo(String msg) throws JSONException
    {
        List<String> loggerArray = createLoggerArrayFromArgument("native");
        logInfo(msg, loggerArray);
    }

    public void logNativeDebug(String msg) throws JSONException
    {
        List<String> loggerArray = createLoggerArrayFromArgument("native");
        logDebug(msg, loggerArray);
    }

    public void logNativeWarn(String msg) throws JSONException
    {
        List<String> loggerArray = createLoggerArrayFromArgument("native");
        logWarn(msg, loggerArray);
    }

    public void logNativeError(String msg) throws JSONException
    {
        List<String> loggerArray = createLoggerArrayFromArgument("native");
        logError(msg, loggerArray);
    }

    private List<String> createLoggerArrayFromArgument(Object obj) throws JSONException
    {
        List<String> destinations = null;
        if(obj instanceof JSONArray)
        {
            destinations = new ArrayList<String>();
            for (int i = 0 ; i < ((JSONArray) obj).length() ; i++)
            {
                destinations.add(((JSONArray) obj).getString(i));
            }
        }
        else if(obj instanceof String)
        {
            destinations = new ArrayList<String>();
            destinations.add((String)obj);
        }
        return destinations;
    }

    private boolean isFirstRun()
    {
        String prefsKey = "hasRun";
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(cordova.getActivity());
        if(!prefs.contains(prefsKey))
        {
            prefs.edit().putBoolean(prefsKey, true).commit();
            return true;
        }
        else
        {
            return false;
        }
    }

    private void putStringInPrefs(String key, String value)
    {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(cordova.getActivity());
        prefs.edit().putString(key, value).commit();
    }

    private String getStringFromPrefs(String key)
    {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(cordova.getActivity());
        return prefs.getString(key, null);
    }

    private void putBooleanInPrefs(String key, boolean value)
    {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(cordova.getActivity());
        prefs.edit().putBoolean(key, value).commit();
    }

    private boolean getBooleanFromPrefs(String key)
    {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(cordova.getActivity());
        return prefs.getBoolean(key, false);
    }

    private void putIntInPrefs(String key, int value)
    {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(cordova.getActivity());
        prefs.edit().putInt(key, value).commit();
    }

    private int getIntFromPrefs(String key)
    {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(cordova.getActivity());
        return prefs.getInt(key, 0);
    }

    private void putLongInPrefs(String key, long value)
    {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(cordova.getActivity());
        prefs.edit().putLong(key, value).commit();
    }

    private long getLongFromPrefs(String key)
    {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(cordova.getActivity());
        return prefs.getLong(key, 0);
    }

    private void deleteDirectory(File dir)
    {
        for(File file : dir.listFiles())
        {
            file.delete();
        }
        dir.delete();
    }

    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException
    {
        switch (requestCode)
        {
            case WRITE_EXTERNAL_STORAGE_PERMISSION_REQUEST:
            {
                // If request is cancelled, the result arrays are empty.
                if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED)
                {
                    copyFilesToPublicDirectoryAndReturnPaths(tmpFilePathsToMakePublic);
                }
                return;
            }
        }
    }

    public void copy(File src, File dst) throws IOException
    {
        FileInputStream inStream = new FileInputStream(src);
        FileOutputStream outStream = new FileOutputStream(dst);
        FileChannel inChannel = inStream.getChannel();
        FileChannel outChannel = outStream.getChannel();
        inChannel.transferTo(0, inChannel.size(), outChannel);
        inStream.close();
        outStream.close();
    }
}