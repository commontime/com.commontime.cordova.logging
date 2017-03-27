package com.commontime.plugin;

/**
 * Created by richardlewin on 02/12/2016.
 */

import java.io.File;

import ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy;
import ch.qos.logback.core.util.FileSize;

public class CustomSizeBasedTriggeringPolicy<E> extends SizeBasedTriggeringPolicy<E>
{
    @Override
    public boolean isTriggeringEvent(File activeFile, E event)
    {
        return activeFile.length() >= FileSize.valueOf(getMaxFileSize()).getSize();
    }
}
