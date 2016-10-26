package io.agora.agoraduo.agroabase;

import android.util.Log;

import java.util.ArrayList;
import java.util.Iterator;

import io.agora.AgoraAPI;
import io.agora.IAgoraAPI;

/**
 * Created by admin on 2016/10/9.
 */

public class SignalEngineEventHandler extends AgoraAPI.CallBack {
    public static final String TAG = SignalEngineEventHandler.class.getSimpleName();

    private ArrayList<BaseEngineEventHandlerActivity> mHandlerActivity = new ArrayList<>();

    public SignalEngineEventHandler() {

    }

    public void addActivity(BaseEngineEventHandlerActivity activity) {

        this.mHandlerActivity.add(activity);
    }

    @Override
    public void onReconnecting(int nretry) {
        Log.d(TAG, "onReconnecting: " + nretry);

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onReconnectiong(nretry);
        }
    }

    @Override
    public void onReconnected(int fd) {
        Log.d(TAG, "onReconnected: " + fd);

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onReconnected(fd);
        }
    }

    @Override
    public void onLoginSuccess(int uid, int fd) {
        Log.d(TAG, "onLoginSuccess: " + uid + " " + fd);

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onLoginSuccess(uid,fd);
        }
    }

    @Override
    public void onLogout(int ecode) {
        Log.d(TAG, "onLogout: " + ecode);

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onLogout(ecode);
        }
    }

    @Override
    public void onLoginFailed(int ecode) {
        Log.d(TAG, "onLoginFailed: " + ecode);

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onLoginFailed(ecode);
        }
    }

    @Override
    public void onChannelJoined(String channelID) {
        Log.d(TAG, "onChannelJoined: " + channelID);

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onChannelJoined(channelID);
        }
    }

    @Override
    public void onChannelJoinFailed(String channelID, int ecode) {
        Log.d(TAG, "onChannelJoinFailed: " + channelID + " " + ecode);

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onChannelJoinFailed(channelID,ecode);
        }
    }

    @Override
    public void onChannelLeaved(String channelID, int ecode) {
        Log.d(TAG, "onChannelLeaved: " + channelID + " " + ecode);

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onChannelLeaved(channelID,ecode);
        }
    }

    @Override
    public void onChannelUserJoined(String account, int uid) {
        Log.d(TAG, "onChannelUserJoined: " + account + " " + uid);

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onChannelUserJoined(account,uid);
        }
    }

    @Override
    public void onChannelUserLeaved(String account, int uid) {
        Log.d(TAG, "onChannelUserLeaved: " + account + " " + uid);

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onChannelUserLeaved(account,uid);
        }
    }

    @Override
    public void onChannelUserList(String[] accounts, int[] uids) {
        Log.d(TAG, "onChannelUserList: ");

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onChannelUserList(accounts,uids);
        }
    }

    @Override
    public void onChannelQueryUserNumResult(String channelID, int ecode, int num) {
        Log.d(TAG, "onChannelQueryUserNumResult: " + channelID);

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onChannelQueryUserNumResult(channelID,ecode,num);
        }
    }

    @Override
    public void onChannelAttrUpdated(String channelID, String name, String value, String type) {
        Log.d(TAG, "onChannelAttrUpdated: ");

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onChannelAttrUpdated(channelID,name,value,type);
        }
    }

    @Override
    public void onInviteReceived(String channelID, String account, int uid) {
        Log.d(TAG, "onInviteReceived: ");

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onInviteReceived(channelID,account,uid);
        }
    }

    @Override
    public void onInviteReceivedByPeer(String channelID, String account, int uid) {
        Log.d(TAG, "onInviteReceivedByPeer: ");

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onInviteReceivedByPeer(channelID,account,uid);
        }
    }

    @Override
    public void onInviteAcceptedByPeer(String channelID, String account, int uid) {
        Log.d(TAG, "onInviteAcceptedByPeer: ");

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onInviteAcceptedByPeer(channelID,account,uid);
        }
    }

    @Override
    public void onInviteRefusedByPeer(String channelID, String account, int uid) {
        Log.d(TAG, "onInviteRefusedByPeer: ");

        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onInviteRefusedByPeer(channelID,account,uid);
        }
    }

    @Override
    public void onInviteFailed(String channelID, String account, int uid, int ecode) {
        Log.d(TAG, "onInviteFailed: ");
        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onInvitedFailed(channelID,account,uid,ecode);
        }
    }

    @Override
    public void onInviteEndByPeer(String channelID, String account, int uid) {
        Log.d(TAG, "onInviteEndByPeer: ");
        Iterator<BaseEngineEventHandlerActivity> it = mHandlerActivity.iterator();
        while (it.hasNext()) {
            BaseEngineEventHandlerActivity activity = it.next();
            activity.onInviteEndByPeer(channelID,account,uid);
        }
    }
/*
    @Override
    public void onInviteEndByMyself(String channelID, String account, int uid) {
        Log.d(TAG, "onInviteEndByMyself: ");
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onInviteEndByMyself(channelID,account,uid);
        }    }

    @Override
    public void onInviteMsg(String channelID, String account, int uid, String msgType, String msgData, String extra) {
        Log.d(TAG, "onInviteMsg: ");
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onInviteMsg(channelID,account,uid,msgType,msgData,extra);
        }    }

    @Override
    public void onMessageSendError(String messageID, int ecode) {
        Log.d(TAG, "onMessageSendError: ");
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onMessageSendError(messageID,ecode);
        }    }

    @Override
    public void onMessageSendSuccess(String messageID) {
        Log.d(TAG, "onMessageSendSuccess: ");
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onMessageSendSuccess(messageID);
        }    }

    @Override
    public void onMessageAppReceived(String msg) {
        Log.d(TAG, "onMessageAppReceived: ");
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onMessageAppReceived(msg);
        }    }

    @Override
    public void onMessageInstantReceive(String account, int uid, String msg) {
        Log.d(TAG, "onMessageInstantReceive: ");
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onMessageInstantReceive(account,uid,msg);
        }    }

    @Override
    public void onMessageChannelReceive(String channelID, String account, int uid, String msg) {
        Log.d(TAG, "onMessageChannelReceive: ");
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onMessageChannelReceive(channelID,account,uid,msg);
        }    }

    @Override
    public void onLog(String txt) {
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onLog(txt);
        }
    }

    @Override
    public void onInvokeRet(String name, int ofu, String reason, String resp) {
        Log.d(TAG, "onInvokeRet: ");
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onInvokeRet(name,ofu,reason,resp);
        }    }

    @Override
    public void onMsg(String from, String t, String msg) {
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onMsg(from,t,msg);
        }
    }

    @Override
    public void onUserAttrResult(String account, String name, String value) {
        Log.d(TAG, "onUserAttrResult: ");
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onUserAttrResult(account,name,value);
        }    }

    @Override
    public void onUserAttrAllResult(String account, String value) {
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onUserAttrAllResult(account,value);
        }    }

    @Override
    public void onError(String name, int ecode, String desc) {
        BaseEngineEventHandlerActivity activity = getActivity();

        if (activity != null) {
            activity.onLoginEngineError(name,ecode,desc);
        }
    }*/
}
