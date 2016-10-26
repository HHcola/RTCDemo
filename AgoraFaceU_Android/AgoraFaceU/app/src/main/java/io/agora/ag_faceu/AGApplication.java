package io.agora.ag_faceu;

import android.app.Application;
import android.content.Context;
import android.content.res.AssetManager;
import android.util.Log;

import com.lemon.faceu.openglfilter.common.FilterCore;
import com.lemon.faceu.openglfilter.gpuimage.base.MResFileReaderBase;
import com.lemon.faceu.sdk.utils.MiscUtils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Map;

import io.agora.ag_faceu.model.CurrentUserSettings;
import io.agora.ag_faceu.model.WorkerThread;
import io.agora.faceu.DemoConstants;
import io.agora.faceu.HardCodeData;

public class AGApplication extends Application {

    private final static Logger log = LoggerFactory.getLogger(AGApplication.class);

    @Override
    public void onCreate() {
        super.onCreate();

        mkdirs(DemoConstants.APPDIR);
        makeNoMediaFile(DemoConstants.APPDIR);

        for (HardCodeData.EffectItem item : HardCodeData.sItems) {
            uncompressAsset(this, item.name, item.unzipPath);
        }

        int ret = FilterCore.initialize(this, null);

        /*
        com.lemon.faceu.sdk.utils.Log.setLogImpl(new com.lemon.faceu.sdk.utils.Log.ILog() {

            @Override
            public void logWriter(int i, String s, String s1) {
                android.util.Log.i("ag_faceu" + i, String.format("[%s] %s", s, s1));
            }

            @Override
            public void uninit() {
            }
        });
        com.lemon.faceu.sdk.utils.Log.setLogLevel(com.lemon.faceu.sdk.utils.Log.LEVEL_VERBOSE);
        */

        log.debug("onCreate " + ret);
    }

    private WorkerThread mWorkerThread;

    public synchronized void initWorkerThread() {
        if (mWorkerThread == null) {
            mWorkerThread = new WorkerThread(getApplicationContext());
            mWorkerThread.start();

            mWorkerThread.waitForReady();
        }
    }

    public synchronized WorkerThread getWorkerThread() {
        return mWorkerThread;
    }

    public synchronized void deInitWorkerThread() {
        mWorkerThread.exit();
        try {
            mWorkerThread.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        mWorkerThread = null;
    }

    public static final CurrentUserSettings mVideoSettings = new CurrentUserSettings();


    public static void uncompressAsset(Context context, String assetName, String unzipDirName) {
        AssetManager assManager = context.getAssets();
        InputStream is;
        try {
            is = assManager.open(assetName);
        } catch (IOException e) {
            log.error("open zip failed, " + Log.getStackTraceString(e));
            return;
        }

        if (isFileExist(DemoConstants.APPDIR + "/" + unzipDirName)) {
            log.error("unzipDirName is exists");
            return;
        }

        mkdirs(DemoConstants.APPDIR);

        Map<String, ArrayList<MResFileReaderBase.FileItem>> dirItems = null;
        try {
            dirItems = MResFileReaderBase.getFileListFromZip(is);
        } catch (IOException e) {
            log.error("IOException on get file list from zip, " + assetName + " " + e.getMessage());
        } finally {
            MiscUtils.safeClose(is);
        }

        if (null == dirItems) {
            return;
        }

        try {
            is = assManager.open(assetName);
        } catch (IOException e) {
            log.error("open zip2 failed, " + Log.getStackTraceString(e));
            return;
        }

        try {
            if (null != is) {
                MResFileReaderBase.unzipToAFile(is, new File(DemoConstants.APPDIR), dirItems);
            }
        } catch (IOException e) {
            log.error("IOException on unzip " + assetName + " " + e.getMessage());
        } finally {
            MiscUtils.safeClose(is);
        }
    }

    public static boolean isFileExist(String filePath) {
        return new File(filePath).exists();
    }

    public static boolean mkdirs(String dir) {
        File file = new File(dir);
        if (file.exists()) {
            return file.isDirectory();
        }

        return file.mkdirs();
    }

    public static boolean makeNoMediaFile(String path) {
        File file = createFile(path, ".nomedia");
        try {
            if (null != file && !file.createNewFile()) {
                log.error("create nomedia failed");
            }
            return true;
        } catch (IOException e) {
            log.error("create nomedia failed", e);
            return false;
        }
    }

    public static File createFile(String filedir, String filename) {
        if (filedir == null || filename == null)
            return null;

        if (!MiscUtils.mkdirs(filedir)) {
            log.error("create parent directory failed, " + filedir);
            return null;
        }

        String filepath = filedir + "/" + filename;
        return new File(filepath);
    }
}
