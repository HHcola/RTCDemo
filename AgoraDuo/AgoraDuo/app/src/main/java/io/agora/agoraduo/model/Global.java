package io.agora.agoraduo.model;

/**
 * Created by admin on 2016/9/29.
 */

public class Global {
    public static long MY_UID = 0;
    public static final String APP_ID = "82e27d05f57a4673818306c37cfcb447";
    public static final String APP_CERTIFICATE = "79780a0d05a540a999ed9081b717779e";

    public static class Tag{
        public static final String USER_ID = "user_id";
        public static final String ACCOUNT = "account";
        public static final String CALL_TYPE = "call_type";
    }

    public static class CallType{
        public static final int TYPE_CALL_IN = 1;
        public static final int TYPE_CALL_OUT = 2;
    }

}
