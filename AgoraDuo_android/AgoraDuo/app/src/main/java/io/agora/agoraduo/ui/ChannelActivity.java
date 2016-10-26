package io.agora.agoraduo.ui;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.support.annotation.Nullable;
import android.text.TextUtils;
import android.util.TypedValue;
import android.view.LayoutInflater;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import java.util.Date;
import java.util.Random;
import java.util.Timer;
import java.util.TimerTask;

import io.agora.AgoraAPIOnlySignal;
import io.agora.agoraduo.R;
import io.agora.agoraduo.agroabase.BaseEngineEventHandlerActivity;
import io.agora.agoraduo.core.AgoraApplication;
import io.agora.agoraduo.model.Global;
import io.agora.agoraduo.tools.MediaPlayerManager;
import io.agora.agoraduo.utils.DynamicKey4;
import io.agora.agoraduo.utils.NetworkConnectivityUtils;
import io.agora.agoraduo.utils.ToastUtil;
import io.agora.rtc.IRtcEngineEventHandler;
import io.agora.rtc.RtcEngine;
import io.agora.rtc.video.VideoCanvas;

/**
 * Created by admin on 2016/9/29.
 */

public class ChannelActivity extends BaseEngineEventHandlerActivity implements View.OnClickListener {
    private TextView mTipTv;
    private EditText mChannelEdit;

    private ImageView mCallBtn;
    private ImageView mAcceptCallBtn;
    private ImageView mEndCallBtn;
    private SurfaceView mLocalView;
    private SurfaceView mRemotView;

    private boolean mVideoSwitchState = true;//video 切换状态 true为大屏自己视频图像，false为大屏远程视频图像
    private LinearLayout mCallOutLayout;
    private LinearLayout mCallInLayout;
    private LinearLayout mRemoteUserContainer;

    private CheckBox mMuter;
    private CheckBox mSwitcher;

    RtcEngine mRtcEngine;
    AgoraAPIOnlySignal mSignalEngine;
    private MediaPlayerManager mMediaPlayerManager;

    private String mChannelId;
    private String mRemoteChannelId;
    private String mRemoteAccount;
    private String mAccount;
    private int mRemoteUId;


    private AlertDialog mAlertDialog;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_channel);

//        StatusBarCompat.compat(this, Color.TRANSPARENT);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        initMediaPlayer();

        mAccount = getIntent().getStringExtra(Global.Tag.ACCOUNT);

        //STEP 1: 初始化Rtc引擎
        setupRtcEngine();
        //STEP 1: 初始化信令引擎
        setupSignalEngine();

        initView();
        showCallOutUI();

        // check network
        if (!NetworkConnectivityUtils.isConnectedToNetwork(getApplicationContext())) {
            onError(104);
        }
    }

    private void initMediaPlayer() {
        mMediaPlayerManager = new MediaPlayerManager();
        mMediaPlayerManager.init(this, R.raw.video_call);
    }

    private void showCallInUI() {
        mCallOutLayout.setVisibility(View.GONE);
        mCallInLayout.setVisibility(View.VISIBLE);
        mMuter.setVisibility(View.GONE);
        mSwitcher.setVisibility(View.GONE);

        mChannelEdit.setVisibility(View.GONE);
        mTipTv.setText(String.format(getString(R.string.accept_call_tip), mRemoteAccount + ""));

        setRemoteUserViewVisibility(false);
        mAcceptCallBtn.setVisibility(View.VISIBLE);
        mEndCallBtn.setVisibility(View.VISIBLE);

        mMediaPlayerManager.play();
    }

    private void showCallOutUI() {
        FrameLayout localViewContainer = (FrameLayout) findViewById(R.id.user_local_view);
        localViewContainer.removeAllViews();
        localViewContainer.setBackgroundResource(R.drawable.ic_room_bg);

        if (mMediaPlayerManager.isPlaying())
            mMediaPlayerManager.stop();

        mCallOutLayout.setVisibility(View.VISIBLE);
        mCallInLayout.setVisibility(View.GONE);
        clearBtnState();

        mChannelEdit.setVisibility(View.VISIBLE);
        mTipTv.setText(String.format(getString(R.string.call_to), mAccount));

        clearRemote();

        //STEP 2: 初始化本地视频
        mRtcEngine.muteLocalVideoStream(true);
        mRtcEngine.muteLocalAudioStream(true);
        setupLocalView();

        //STEP 2: Face Time
        //mRtcEngine.startPreview();
    }

    void clearBtnState() {
        mMuter.setVisibility(View.GONE);
        mSwitcher.setVisibility(View.GONE);
        mRemoteUserContainer.setVisibility(View.GONE);
    }

    void initBtnState() {
        mMuter.setVisibility(View.VISIBLE);
        mSwitcher.setVisibility(View.VISIBLE);
        mRemoteUserContainer.setVisibility(View.VISIBLE);
    }

    private void initView() {
        mTipTv = (TextView) findViewById(R.id.tip_tv);
        mChannelEdit = (EditText) findViewById(R.id.send_to_edit);

        mTipTv.setText(String.format(getString(R.string.own_num), mAccount + ""));

        mCallInLayout = (LinearLayout) findViewById(R.id.call_in_layout);
        mCallOutLayout = (LinearLayout) findViewById(R.id.call_out_layout);

        mRemoteUserContainer = (LinearLayout) findViewById(R.id.user_remote_views);
        mCallBtn = (ImageView) findViewById(R.id.call_out_btn);
        mAcceptCallBtn = (ImageView) findViewById(R.id.accept_call_btn);
        mEndCallBtn = (ImageView) findViewById(R.id.end_call_btn);

        mMuter = (CheckBox) findViewById(R.id.muter);
        mSwitcher = (CheckBox) findViewById(R.id.camera_switcher);

        mMuter.setBackgroundResource(R.drawable.unmute);
        mSwitcher.setBackgroundResource(R.drawable.rotate);

        mMuter.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton compoundButton, boolean mutes) {
                mRtcEngine.muteLocalAudioStream(mutes);
                compoundButton.setBackgroundResource(mutes ? R.drawable.mute : R.drawable.unmute);
            }
        });

        mSwitcher.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton compoundButton, boolean usesSpeaker) {
                mRtcEngine.switchCamera();
                compoundButton.setBackgroundResource(R.drawable.rotate);
            }
        });

        mMuter.setChecked(false);
        mSwitcher.setChecked(false);

        mCallBtn = (ImageView) findViewById(R.id.call_out_btn);
        mCallBtn.setOnClickListener(this);

        mAcceptCallBtn = (ImageView) findViewById(R.id.accept_call_btn);
        mAcceptCallBtn.setOnClickListener(this);

        mEndCallBtn = (ImageView) findViewById(R.id.end_call_btn);
        mEndCallBtn.setOnClickListener(this);

        mRemoteUserContainer.setOnClickListener(this);
    }

    void joinChannel(String channelId) {
        this.mChannelId = channelId;

        log("joinChannel channelId : " + channelId);

        String key = "";
        int ts = (int)(new Date().getTime()/1000);
        int r = new Random().nextInt();
        long uid = Global.MY_UID;
        int expiredTs = 0;

        try {
            key = DynamicKey4.generateMediaChannelKey(Global.APP_ID, Global.APP_CERTIFICATE, channelId, ts, r, uid, expiredTs);
        } catch (Exception e) {
            e.printStackTrace();
        }

        setupLocalView();

        mSignalEngine.channelJoin(channelId);
        mRtcEngine.joinChannel(
                key,
                channelId,
                "" /*optionalInfo*/,
                (int)Global.MY_UID);
    }

    void leaveChannel() {
        mRemoteUserContainer.removeAllViews();
        setRemoteUserViewVisibility(false);

        mRemoteUId = 0;
        mSignalEngine.channelLeave(mChannelId);
        mRtcEngine.leaveChannel();
    }

    void setupRtcEngine() {
        mRtcEngine = ((AgoraApplication) getApplication()).getRtcEngine();
        ((AgoraApplication) getApplication()).setEngineEventHandlerActivity(ChannelActivity.this);
        mRtcEngine.enableVideo();
        mRtcEngine.setEnableSpeakerphone(true);
    }

    void setupSignalEngine() {
        mSignalEngine = ((AgoraApplication) getApplication()).getSignalEngine();
        ((AgoraApplication) getApplication()).addSignalEventHandlerActivity(ChannelActivity.this);
        log("login callback :" + mSignalEngine.callbackGet().toString());
    }

    void setupLocalView() {
        // local view has not been added before
        FrameLayout localViewContainer = (FrameLayout) findViewById(R.id.user_local_view);
        if (mLocalView == null) {
            SurfaceView localView = mRtcEngine.CreateRendererView(getApplicationContext());
            this.mLocalView = localView;
        }
        localViewContainer.removeAllViews();
        localViewContainer.addView(mLocalView,
                new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));

        mRtcEngine.setupLocalVideo(new VideoCanvas(this.mLocalView));
        mLocalView.invalidate();
    }

    void switchVideo() {

        log("switch video + remoteuid = " + mRemoteUId);

        if (mVideoSwitchState) {
            mVideoSwitchState = false;
            mRtcEngine.setupLocalVideo(new VideoCanvas(this.mRemotView));
            mRemotView.invalidate();

            mRtcEngine.setupRemoteVideo(new VideoCanvas(mLocalView, VideoCanvas.RENDER_MODE_ADAPTIVE, mRemoteUId));
            mLocalView.invalidate();
        } else {
            mVideoSwitchState = true;
            mRtcEngine.setupLocalVideo(new VideoCanvas(this.mLocalView));
            mLocalView.invalidate();

            mRtcEngine.setupRemoteVideo(new VideoCanvas(mRemotView, VideoCanvas.RENDER_MODE_ADAPTIVE, mRemoteUId));
            mRemotView.invalidate();
        }
    }

    void switchVideoDelay(){
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                switchVideo();
            }
        }, 600);
    }

    @Override
    public synchronized void onError(int err) {

        if (isFinishing()) {
            return;
        }

        // incorrect APP ID
        if (101 == err) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (mAlertDialog != null) {
                        return;
                    }
                    mAlertDialog = new AlertDialog.Builder(ChannelActivity.this).setCancelable(false)
                            .setMessage(getString(R.string.error_101))
                            .setPositiveButton(getString(R.string.error_confirm), new DialogInterface.OnClickListener() {
                                @Override
                                public void onClick(DialogInterface dialog, int which) {
                                    // Go to login
                                    leaveChannel();

                                    Intent toLogin = new Intent(ChannelActivity.this, LoginActivity.class);
                                    toLogin.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
                                    startActivity(toLogin);

                                    finish();

                                }
                            }).setOnCancelListener(new DialogInterface.OnCancelListener() {
                                @Override
                                public void onCancel(DialogInterface dialogInterface) {
                                    dialogInterface.dismiss();
                                }
                            })
                            .create();

                    mAlertDialog.show();
                }
            });
        }

        // no network connection
        if (104 == err) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    TextView appNotification = (TextView) findViewById(R.id.app_notification);
                    appNotification.setText(R.string.network_error);
                }
            });
        }
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.call_out_btn:
                String calloutChannelId = mChannelEdit.getText().toString().trim();
                if (TextUtils.isEmpty(calloutChannelId)) {
                    Toast.makeText(ChannelActivity.this, getString(R.string.empty_tip), Toast.LENGTH_SHORT).show();
                } else if (calloutChannelId.equals(mAccount)) {
                    Toast.makeText(ChannelActivity.this, getString(R.string.self_tip), Toast.LENGTH_SHORT).show();
                } else {
                    initBtnState();
                    mCallOutLayout.setVisibility(View.GONE);
                    mCallInLayout.setVisibility(View.VISIBLE);
                    mAcceptCallBtn.setVisibility(View.GONE);

                    mChannelEdit.setVisibility(View.GONE);
                    mTipTv.setText(getString(R.string.calling_tip, calloutChannelId));

                    mChannelId = mAccount;

                    //STEP 3: 主叫方发起视频通话邀请
                    //主叫方: Google Duo: 发送视频流，不发送音频流
                    mRtcEngine.muteLocalVideoStream(true);
                    mRtcEngine.muteLocalAudioStream(true);
                    joinChannel(mAccount);

                    //STEP 3: 信令投递呼叫邀请
                    //初始化远程用户
                    initRemote(mAccount,calloutChannelId);
                    //呼叫远程用户
                    mSignalEngine.channelInviteUser(mAccount,calloutChannelId,0);
                    //响铃
                    mMediaPlayerManager.play();
                }
                break;
            case R.id.accept_call_btn:
                //STEP 4: 被叫方接受呼叫
                mSignalEngine.channelInviteAccept(mRemoteChannelId,mRemoteAccount,0);

                initBtnState();
                mAcceptCallBtn.setVisibility(View.GONE);

                //设置本地视频和远端视频
                setupLocalView();
                initRemoteView(mRemoteUId);

                mVideoSwitchState = true;
                switchVideoDelay();

                setRemoteUserViewVisibility(true);

                mTipTv.setText("");

                mMediaPlayerManager.stop();

                //STEP 4: 被叫方接受呼叫邀请，开始通话
                //Google Duo:发送音频流和视频流
                mRtcEngine.muteLocalVideoStream(false);
                mRtcEngine.muteLocalAudioStream(false);
                break;
            case R.id.end_call_btn:
                //STEP 5: 拒绝或结束通话
                log("end btn remoteAccount = " + mRemoteAccount + "remoteChannelId : " + mRemoteChannelId);
                if (!TextUtils.isEmpty(mRemoteAccount))
                    mSignalEngine.channelInviteRefuse(mRemoteChannelId, mRemoteAccount,0);


                //退出频道
                leaveChannel();
                showCallOutUI();
                mMediaPlayerManager.stop();
                break;
            case R.id.user_remote_views:
                //todo 切换视频
                switchVideo();
                break;
        }
    }

    @Override
    public void onInviteAcceptedByPeer(String channelID, String account, int uid) {
        log("mSignalEngine 对方接受邀请 channelId: " + channelID + "account: " + account);

        //STEP 4: 被叫方接受了邀请
        initRemote(channelID,account);
        //主叫方：被叫方接受了邀请，发送音频流和视频流
        mRtcEngine.muteLocalAudioStream(false);
        mRtcEngine.muteLocalVideoStream(false);
    }

    @Override
    public void onInvitedFailed(String channelID, String account, int uid, final int ecode) {
        log("mSignalEngine 邀请失败");
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mMediaPlayerManager.stop();
                ToastUtil.toastShort(ChannelActivity.this,"呼叫失败，错误码：" + ecode);
                //STEP 8: 呼叫邀请失败，返回到等待呼叫界面
                leaveChannel();
                showCallOutUI();
            }
        });
    }

    @Override
    public void onInviteEndByPeer(String channelID, String account, int uid) {
        log("mSignalEngine 对方拒绝");
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mMediaPlayerManager.stop();
                ToastUtil.toastShort(ChannelActivity.this,"对方拒绝呼叫");
                //STEP 9: 被叫方拒绝通话，返回到等待呼叫界面
                leaveChannel();
                showCallOutUI();
            }
        });
    }

    @Override
    public void onInviteReceived(String channelID, String account, int uid) {
        log("mSignalEngine 收到邀请");
        if (!TextUtils.isEmpty(mRemoteAccount)) return;

        //STEP 3: 被叫方收到呼叫邀请
        initRemote(channelID,account);
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                //被叫方：收到邀请。Google Duo: 不发送音频流和视频流（只看不发），进频道
                mRtcEngine.muteLocalVideoStream(true);
                mRtcEngine.muteLocalAudioStream(true);
                joinChannel(mRemoteChannelId);
                //显示对方视频
                showCallInUI();
                initRemoteView(0);
            }
        });
    }

    void initRemote(String channelId,String account){
        mRemoteChannelId = channelId;
        mRemoteAccount = account;
    }

    void clearRemote(){
        mRemoteChannelId = "";
        mRemoteAccount = "";
    }

    @Override
    public synchronized void onFirstRemoteVideoDecoded(final int uid, int width, int height, int elapsed) {
        log("onFirstRemoteVideoDecoded: uid: " + uid + ", width: " + width + ", height: " + height);

        //只识别第一个进入频道的人
        log("remote uid = " + mRemoteUId + "uid = " + uid);
        if (mRemoteUId != uid) {
            return;
        }

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                initRemoteView(uid);

                // app hints before you join
                TextView appNotification = (TextView) findViewById(R.id.app_notification);
                appNotification.setText("");
                setRemoteUserViewVisibility(true);

                log("set tip and switch");
                //自己房间
                if (mChannelId == mAccount) {
                    mTipTv.setText("");
                }
                mVideoSwitchState = true;
                switchVideo();
            }
        });
    }

    void initRemoteView(final int uid) {
//        View remoteUserView = remoteUserContainer.findViewById(Math.abs(uid));
        View remoteUserView ;

        // ensure container is added
//        if (remoteUserView == null) {

            LayoutInflater layoutInflater = getLayoutInflater();

            View singleRemoteUser = layoutInflater.inflate(R.layout.viewlet_remote_user, null);
            singleRemoteUser.setId(Math.abs(uid));

            mRemoteUserContainer.removeAllViews();
            mRemoteUserContainer.addView(singleRemoteUser,
                    new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

            remoteUserView = singleRemoteUser;
//        }

        FrameLayout remoteVideoUser = (FrameLayout) remoteUserView.findViewById(R.id.viewlet_remote_video_user);
        remoteVideoUser.removeAllViews();
        remoteVideoUser.setTag(uid);

        // ensure remote video view setup
//                final SurfaceView remoteView = RtcEngine.CreateRendererView(getApplicationContext());

        mRemotView = RtcEngine.CreateRendererView(getApplicationContext());
        mRemotView.setZOrderOnTop(true);
        mRemotView.setZOrderMediaOverlay(true);

        int successCode = mRtcEngine.setupRemoteVideo(new VideoCanvas(mRemotView, VideoCanvas.RENDER_MODE_ADAPTIVE, uid));

        if (successCode < 0) {
            new android.os.Handler().postDelayed(new Runnable() {
                @Override
                public void run() {
                    mRtcEngine.setupRemoteVideo(new VideoCanvas(mRemotView, VideoCanvas.RENDER_MODE_ADAPTIVE, uid));
                    mRemotView.invalidate();
                }
            }, 500);
        }

        remoteVideoUser.removeAllViews();
        remoteVideoUser.addView(mRemotView,
                new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT));
    }

    @Override
    public synchronized void onUserJoined(final int uid, int elapsed) {
        log("onUserJoined: uid: " + uid + "remoteAccount: " + mRemoteAccount);

        //只识别第一个进入频道的人
//        View existedUser = remoteUserContainer.findViewById(Math.abs(uid));
//        if (existedUser != null || (remoteUId == uid && remoteUId != 0)) {
        if (mRemoteUId != 0) {
            // user view already added
            // remote user already in
            return;
        }

        mRemoteUId = uid;
    }

    @Override
    public void onChannelUserLeaved(String account, final int uid) {
        log("onChannelUserLeaved account: " + account);


        if (isFinishing()) {
            return;
        }

        if (mRemoteUserContainer == null) {
            return;
        }

        runOnUiThread(new Runnable() {
            @Override
            public void run() {

                View userViewToRemove = mRemoteUserContainer.findViewById(Math.abs(uid));
                if (userViewToRemove != null) {
                    mRemoteUserContainer.removeView(userViewToRemove);
                }

                // no joined users any more
                // 远程用户退出
                if (mRemoteUserContainer.getChildCount() == 0 || mRemoteUId == uid) {
                    mRemoteUId = 0;

                    setRemoteUserViewVisibility(false);
                    leaveChannel();
                    showCallOutUI();
                }
            }
        });
    }


    @Override
    public void onUserMuteAudio(final int uid, final boolean muted) {
        log("onUserMuteAudio" + uid + ", muted: " + muted);
        if (isFinishing()) {
            return;
        }

        if (mRemoteUserContainer == null) {
            return;
        }

        if (mMediaPlayerManager.isPlaying() && !muted) {
            mMediaPlayerManager.stop();
        }
    }

    @Override
    public void onUserMuteVideo(final int uid, final boolean muted) {

        log("onUserMuteVideo uid: " + uid + ", muted: " + muted);

        if (isFinishing()) {
            return;
        }

        if (mRemoteUserContainer == null) {
            return;
        }

        runOnUiThread(new Runnable() {
            @Override
            public void run() {

//                View remoteView = remoteUserContainer.findViewById(Math.abs(uid));
                //显示静音状态
                if (muted) {
                    mRemoteUserContainer.removeAllViews();
                } else {
                    initRemoteView(uid);
                }

                setRemoteUserViewVisibility(!muted);
//                remoteView.invalidate();
            }
        });

    }

    void setRemoteUserViewVisibility(boolean isVisible) {
        log("setRemoteUserViewVisibility + isVisible = " + isVisible);
//        remoteUserContainer.setVisibility(isVisible? View.VISIBLE:View.GONE);
        mRemoteUserContainer.getLayoutParams().height =
                isVisible ? (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 80, getResources().getDisplayMetrics())
                        : 0;
        mRemoteUserContainer.getLayoutParams().width =
                isVisible ? (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, 80, getResources().getDisplayMetrics())
                        : 0;
    }

    @Override
    public void onBackPressed() {
        // keep screen on - turned off
//        leaveChannel();
//        mSignalEngine.logout();
        getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        finish();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        ((AgoraApplication) getApplication()).setEngineEventHandlerActivity(null);
        mMediaPlayerManager.deInit();
        mMediaPlayerManager = null;

        leaveChannel();
        mSignalEngine.logout();
    }
}
