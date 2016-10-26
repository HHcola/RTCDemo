package io.agora.agoraduo.agroabase;

import io.agora.IAgoraAPI;
import io.agora.agoraduo.core.BaseActivity;
import io.agora.rtc.IRtcEngineEventHandler;

/**
 *
 * A handler activity act as a bridge to take callbacks from @MessageHandler.
 * Subclasses should override these key methods.
 *
 * Created by on 9/13/15.
 */
public class BaseEngineEventHandlerActivity extends BaseActivity {


    public void onJoinChannelSuccess(String channel, int uid, int elapsed) {
    }

    public void onRejoinChannelSuccess(String channel, int uid, int elapsed) {
    }

    public void onError(int err) {
    }

    public void onCameraReady() {
    }

    public void onAudioQuality(int uid, int quality, short delay, short lost) {
    }

    public void onAudioTransportQuality(int uid, short delay, short lost) {
    }

    public void onVideoTransportQuality(int uid, short delay, short lost) {
    }

    public void onLeaveChannel(IRtcEngineEventHandler.RtcStats stats) {
    }

    public void onUpdateSessionStats(IRtcEngineEventHandler.RtcStats stats) {
    }

    public void onRecap(byte[] recap) {
    }

    public void onAudioVolumeIndication(IRtcEngineEventHandler.AudioVolumeInfo[] speakers, int totalVolume) {
    }

    public void onNetworkQuality(int quality) {
    }

    public void onUserJoined(int uid, int elapsed) {
    }

    public void onUserOffline(int uid) {
    }

    public void onUserMuteAudio(int uid, boolean muted) {
    }

    public void onUserMuteVideo(int uid, boolean muted) {
    }

    public void onAudioRecorderException(int nLastTimeStamp) {
    }

    public void onRemoteVideoStat(int uid, int frameCount, int delay, int receivedBytes) {
    }

    public void onLocalVideoStat(int sentBytes, int sentFrames) {
    }

    public void onFirstRemoteVideoFrame(int uid, int width, int height, int elapsed) {
    }

    public void onFirstLocalVideoFrame(int width, int height, int elapsed) {
    }

    public void onFirstRemoteVideoDecoded(int uid, int width, int height, int elapsed) {
    }

    public void onConnectionLost() {
    }

    public void onMediaEngineEvent(int code) {
    }

    public void setCB(IAgoraAPI.ICallBack CB) {
    }

    public void getCB() {

    }

    public void onReconnectiong(int nretry) {

    }

    public void onReconnected(int fd) {

    }

    public void onLoginSuccess(int uid, int fd) {

    }

    public void onLogout(int ecode) {

    }

    public void onLoginFailed(int ecode) {

    }

    public void onChannelJoined(String channelID) {

    }

    public void onChannelJoinFailed(String channelID, int ecode) {

    }

    public void onChannelLeaved(String channelID, int ecode) {

    }

    public void onChannelUserJoined(String account, int uid) {

    }

    public void onChannelUserLeaved(String account, int uid) {

    }

    public void onChannelUserList(String[] accounts, int[] uids) {

    }

    public void onChannelQueryUserNumResult(String channelID, int ecode, int num) {

    }

    public void onChannelAttrUpdated(String channelID, String name, String value, String type) {

    }

    public void onInviteReceived(String channelID, String account, int uid) {

    }

    public void onInviteReceivedByPeer(String channelID, String account, int uid) {

    }

    public void onInviteAcceptedByPeer(String channelID, String account, int uid) {

    }

    public void onInviteRefusedByPeer(String channelID, String account, int uid) {

    }

    public void onInvitedFailed(String channelID, String account, int uid, int ecode) {

    }

    public void onInviteEndByPeer(String channelID, String account, int uid) {

    }

    public void onInviteEndByMyself(String channelID, String account, int uid) {

    }

    public void onInviteMsg(String channelID, String account, int uid, String msgType, String msgData, String extra) {

    }

    public void onMessageSendError(String messageID, int ecode) {

    }

    public void onMessageSendSuccess(String messageID) {

    }

    public void onMessageAppReceived(String msg) {

    }

    public void onMessageInstantReceive(String account, int uid, String msg) {

    }

    public void onMessageChannelReceive(String channelID, String account, int uid, String msg) {

    }

    public void onLog(String txt) {

    }

    public void onInvokeRet(String name, int ofu, String reason, String resp) {

    }

    public void onMsg(String from, String t, String msg) {

    }

    public void onUserAttrResult(String account, String name, String value) {

    }

    public void onUserAttrAllResult(String account, String value) {

    }

    public void onLoginEngineError(String name, int ecode, String desc) {

    }
}
