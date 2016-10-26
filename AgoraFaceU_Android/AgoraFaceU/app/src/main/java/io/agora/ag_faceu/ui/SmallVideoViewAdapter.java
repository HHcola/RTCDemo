package io.agora.ag_faceu.ui;

import android.content.Context;
import android.util.DisplayMetrics;
import android.view.SurfaceView;
import android.view.WindowManager;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;

import io.agora.propeller.UserStatusData;

public class SmallVideoViewAdapter extends VideoViewAdapter {
    private final static Logger log = LoggerFactory.getLogger(SmallVideoViewAdapter.class);

    private int mExceptedUid;

    public SmallVideoViewAdapter(Context context, int localUid, int exceptedUid, HashMap<Integer, VideoViewDecorator> uids, VideoViewEventListener listener) {
        super(context, localUid, uids, listener);
        mExceptedUid = exceptedUid;
        log.debug("SmallVideoViewAdapter " + (mLocalUid & 0xFFFFFFFFL) + " " + (mExceptedUid & 0xFFFFFFFFL));
    }

    @Override
    protected void customizedInit(HashMap<Integer, VideoViewDecorator> uids, boolean force) {
        VideoViewAdapterUtil.composeDataItem(mUsers, uids, mLocalUid, null, null, mVideoInfo, mExceptedUid);

        for (UserStatusData user : mUsers) {
            SurfaceView surfaceV = user.mView.mSurfaceView;
            surfaceV.setZOrderOnTop(true);
            surfaceV.setZOrderMediaOverlay(true);
        }

        if (force || mItemWidth == 0 || mItemHeight == 0) {
            WindowManager windowManager = (WindowManager) mContext.getSystemService(Context.WINDOW_SERVICE);
            DisplayMetrics outMetrics = new DisplayMetrics();
            windowManager.getDefaultDisplay().getMetrics(outMetrics);
            mItemWidth = outMetrics.widthPixels / 4;
            mItemHeight = outMetrics.heightPixels / 4;
        }
    }

    @Override
    public void notifyUiChanged(HashMap<Integer, VideoViewDecorator> uids, int uidExcepted, HashMap<Integer, Integer> status, HashMap<Integer, Integer> volume) {
        mUsers.clear();

        mExceptedUid = uidExcepted;
        log.debug("notifyUiChanged " + (mLocalUid & 0xFFFFFFFFL) + " " + (uidExcepted & 0xFFFFFFFFL) + " " + uids + " " + status + " " + volume);
        VideoViewAdapterUtil.composeDataItem(mUsers, uids, mLocalUid, status, volume, mVideoInfo, uidExcepted);

        for (UserStatusData user : mUsers) {
            SurfaceView surfaceV = user.mView.mSurfaceView;
            surfaceV.setZOrderOnTop(true);
            surfaceV.setZOrderMediaOverlay(true);
        }

        notifyDataSetChanged();
    }

    public int getExceptedUid() {
        return mExceptedUid;
    }
}
