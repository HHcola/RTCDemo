package io.agora.faceu;

import android.content.Context;
import android.support.v8.renderscript.RenderScript;

import com.lemon.faceu.sdk.utils.Log;

import junit.framework.Assert;

public class FuCore {
    private static final String TAG = "FuCore";
    static FuCore theCore = null;

    public static void initialize(Context context) {
        if (null != theCore) {
            return;
        }

        theCore = new FuCore();
        theCore.init(context);
    }

    public static FuCore getCore() {
        Assert.assertNotNull("FuCore not initialize!", theCore);
        return theCore;
    }

    Context mContext;
    RenderScript mRenderScript;
    boolean mCanUseRs;

    public void init(Context context) {
        mContext = context;

        try {
            mRenderScript = RenderScript.create(FuCore.getCore().getContext());
            mCanUseRs = true;
            Log.i(TAG, "can use renderscript");
        } catch (Exception e) {
            mCanUseRs = false;
            Log.i(TAG, "can't use renderscript");
        }
    }

    public Context getContext() {
        return mContext;
    }

    public RenderScript getGlobalRs() {
        return mRenderScript;
    }

    public boolean canUseRs() {
        return mCanUseRs;
    }
}
