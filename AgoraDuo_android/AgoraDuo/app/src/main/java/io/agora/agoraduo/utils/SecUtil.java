package io.agora.agoraduo.utils;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * Created by admin on 2016/10/9.
 */

public class SecUtil {

    public static String hexlify(byte[] data){
        char[] DIGITS_LOWER = {'0', '1', '2', '3', '4', '5',
                '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'};

        /**
         * 用于建立十六进制字符的输出的大写字符数组
         */
        char[] DIGITS_UPPER = {'0', '1', '2', '3', '4', '5',
                '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

        char[] toDigits = DIGITS_LOWER;
        int l = data.length;
        char[] out = new char[l << 1];
        // two characters form the hex value.
        for (int i = 0, j = 0; i < l; i++) {
            out[j++] = toDigits[(0xF0 & data[i]) >>> 4];
            out[j++] = toDigits[0x0F & data[i]];
        }
        return String.valueOf(out);

    }

    public static String md5hex(byte[] s){
        MessageDigest messageDigest = null;
        try {
            messageDigest = MessageDigest.getInstance("MD5");
            messageDigest.update(s);
            return hexlify(messageDigest.digest());
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
            return "";
        }
    }


    public static String calcToken(String vendorKey, String signKey, String account, long expiredTime){
        // Token = 1:vendorKey:expiredTime:sign
        // Token = 1:vendorKey:expiredTime:md5(account + vendorID + signKey + expiredTime)

        String sign = md5hex((account + vendorKey + signKey + expiredTime).getBytes());
        return "1:" + vendorKey + ":" + expiredTime + ":" + sign;

    }
}
