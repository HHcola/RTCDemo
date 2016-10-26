package io.agora.agoraduo.ui;

import android.app.ProgressDialog;
import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.text.TextUtils;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Date;

import io.agora.AgoraAPIOnlySignal;
import io.agora.agoraduo.R;
import io.agora.agoraduo.agroabase.BaseEngineEventHandlerActivity;
import io.agora.agoraduo.core.AgoraApplication;
import io.agora.agoraduo.model.Global;
import io.agora.agoraduo.utils.ToastUtil;

/**
 * Created by admin on 2016/9/28.
 */

public class LoginActivity extends BaseEngineEventHandlerActivity {

    private EditText mUserIdEditText;
    private Button mLoginBtn;
    AgoraAPIOnlySignal mSignalEngine;

    private String mAccount;
    private ProgressDialog mProgressDialog;
    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);

//        setupEngine();
        initView();

        mProgressDialog = new ProgressDialog(this);
        mProgressDialog.setCanceledOnTouchOutside(false);
    }

    @Override
    protected void onStart() {
        log("onstart");
        super.onStart();
        setupEngine();
    }

    private void setupEngine() {
        if (mSignalEngine == null){
            mSignalEngine = ((AgoraApplication) getApplication()).getSignalEngine();
        }
        ((AgoraApplication) getApplication()).addSignalEventHandlerActivity(LoginActivity.this);

        log("mSignalEngine callback : " + mSignalEngine.callbackGet().toString());
    }

    @Override
    protected void onStop() {
        super.onStop();
    }

    private void initView() {
        mUserIdEditText = (EditText) findViewById(R.id.editText);
        mLoginBtn = (Button) findViewById(R.id.button);

        mLoginBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String account = mUserIdEditText.getText().toString();
                if (TextUtils.isEmpty(account)) {
                    Toast.makeText(LoginActivity.this,R.string.empty_tip,Toast.LENGTH_SHORT).show();
                } else {
                    dologin(account);
                }
            }
        });
    }

    private void dologin(String account) {
        this.mAccount = account;
        log("Login : APP ID=" + Global.APP_ID + ", account=" + account);
        long expiredTime = new Date().getTime()/1000 + 3600;
        String token = calcToken(Global.APP_ID, Global.APP_CERTIFICATE, account, expiredTime);
        log("token : " + token);
        mSignalEngine.login(Global.APP_ID, account, token, 0, "");

        mProgressDialog.setMessage("正在登陆中...");
        mProgressDialog.show();
    }

    @Override
    public void onLoginSuccess(int uid, int fd) {
        //todo lll
        Global.MY_UID = uid;
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mProgressDialog.dismiss();
                ToastUtil.toastShort(LoginActivity.this,"login success");
                navToHome();
            }
        });
    }

    @Override
    public void onLoginFailed(final int ecode) {
        //todo lll
        this.mAccount = "";
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mProgressDialog.dismiss();
                ToastUtil.toastShort(LoginActivity.this,"login failed, errorcode: " + ecode);
            }
        });
    }

    @Override
    public void onLoginEngineError(String name, final int ecode, final String desc) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mProgressDialog.dismiss();
                ToastUtil.toastShort(LoginActivity.this,"login failed des: " + desc + "errorcode : " + ecode);
            }
        });
    }


    private void navToHome() {
        Intent intent = new Intent(LoginActivity.this, ChannelActivity.class);
        intent.putExtra(Global.Tag.ACCOUNT, mAccount);
        intent.putExtra(Global.Tag.CALL_TYPE,Global.CallType.TYPE_CALL_OUT);
        startActivity(intent);

//        mSignalEngine.channelJoin("111");
    }

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


    public String calcToken(String appID, String appCertificate, String account, long expiredTime){
        // Token = 1:appID:expiredTime:sign
        // Token = 1:appID:expiredTime:md5(account + appID + appCertificate + expiredTime)

        String sign = md5hex((account + appID + appCertificate + expiredTime).getBytes());
        return "1:" + appID + ":" + expiredTime + ":" + sign;

    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        mSignalEngine.logout();
        mSignalEngine = null;
    }

    @Override
    public void onBackPressed() {
        finish();
    }
}
