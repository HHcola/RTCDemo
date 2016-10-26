package io.agora.faceu;

import android.annotation.TargetApi;
import android.app.ActivityManager;
import android.content.Context;
import android.os.Build;

import com.lemon.faceu.sdk.platform.ApiLevel;
import com.lemon.faceu.sdk.utils.Log;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileFilter;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.util.regex.Pattern;

/**
 * @author kevinhuang
 *         CPU通用信息方法
 * @since 2015-03-30
 */
public class CpuUtils {
    private static final String TAG = "CpuUtils";

    /**
     * 判读机器是不是高端机，比较暴力
     * 1. cpu数目 * 主频 > 4 * 1300000
     * 2. 内存大于1.5G
     *
     * @return 如果是高端机则返回true，否则返回false
     */
    public static boolean isHighEndPhone(Context context) {
        long cpuScore = getNumCores() * getMaxCpuFreq();
        return (cpuScore > 4000000 && getTotalMem(context) > 1.5 * 1024 * 1024 * 1024);
    }

    /**
     * Gets the number of cores available in this device, across all processors.
     * Requires: Ability to peruse the filesystem at "/sys/devices/system/cpu"
     *
     * @return The number of cores, or 1 if failed to get result
     */
    public static int getNumCores() {
        //Private Class to display only CPU devices in the directory listing
        class CpuFilter implements FileFilter {
            @Override
            public boolean accept(File pathname) {
                //Check if filename is "cpu", followed by a single digit number
                if (Pattern.matches("cpu[0-9]+", pathname.getName())) {
                    return true;
                }
                return false;
            }
        }

        try {
            //Get directory containing CPU info
            File dir = new File("/sys/devices/system/cpu/");
            //Filter to only list the devices we care about
            File[] files = dir.listFiles(new CpuFilter());
            //Return the number of cores (virtual CPU devices)
            return files.length;
        } catch (Exception e) {
            //Default to return 1 core
            return 1;
        }
    }

    /**
     * 只获取第一个的主频，因为其他cpu没用的时候，有可能会被offline掉，导致获取不到
     */
    public static long getMaxCpuFreq() {
        long longRet = 0;
        String result = "0";
        ProcessBuilder cmd;
        try {
            String[] args = {"/system/bin/cat", "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq"};
            cmd = new ProcessBuilder(args);
            Process process = cmd.start();
            InputStream in = process.getInputStream();
            byte[] re = new byte[24];
            result = "";
            while (in.read(re) != -1) {
                result = result + new String(re);
            }
            in.close();
        } catch (IOException ex) {
            ex.printStackTrace();
            result = "0";
        }

        if (result.length() != 0) {
            try {
                longRet = Long.valueOf(result.trim());
            } catch (Exception e) {
                android.util.Log.e(TAG, "");
            }
        }
        return longRet;
    }

    @TargetApi(Build.VERSION_CODES.JELLY_BEAN)
    public static long getTotalMemAbove16(Context context) {
        ActivityManager.MemoryInfo memoryInfo = new ActivityManager.MemoryInfo();
        ActivityManager am = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        am.getMemoryInfo(memoryInfo);
        return memoryInfo.totalMem;
    }

    public static long getTotalMemBelow16() {
        String str1 = "/proc/meminfo";
        String str2;
        String[] arrayOfString;
        long initial_memory = 0;
        try {
            FileReader localFileReader = new FileReader(str1);
            BufferedReader localBufferedReader = new BufferedReader(localFileReader, 8192);
            str2 = localBufferedReader.readLine();// meminfo
            arrayOfString = str2.split("\\s+");
            for (String num : arrayOfString) {
                Log.i(str2, num + "\t");
            }
            // total Memory
            initial_memory = Integer.parseInt(arrayOfString[1]) * 1024;
            localBufferedReader.close();
            return initial_memory;
        } catch (IOException e) {
            return 0;
        }
    }

    public static long getTotalMem(Context context) {
        if (Build.VERSION.SDK_INT < ApiLevel.API16_JELLY_BEAN_41) {
            return getTotalMemBelow16();
        } else {
            return getTotalMemAbove16(context);
        }
    }
}
