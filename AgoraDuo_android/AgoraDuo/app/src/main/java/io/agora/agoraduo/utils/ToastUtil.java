package io.agora.agoraduo.utils;

import android.content.Context;
import android.widget.Toast;

/**
 * Created by admin on 2016/10/9.
 */

public class ToastUtil {
    public static void toastLong(Context context, String tip) {
        Toast.makeText(context, tip, Toast.LENGTH_LONG).show();
    }

    public static void toastShort(Context context, String tip) {
        Toast.makeText(context, tip, Toast.LENGTH_SHORT).show();
    }
}
