package extension.adjust;

import java.util.Hashtable;
import java.util.Map;

import android.app.Activity;
import android.net.Uri;

import com.adjust.sdk.Adjust;
import com.adjust.sdk.AdjustAttribution;
import com.adjust.sdk.AdjustConfig;
import com.adjust.sdk.AdjustDeeplink;
import com.adjust.sdk.AdjustEvent;
import com.adjust.sdk.AdjustEventFailure;
import com.adjust.sdk.AdjustEventSuccess;
import com.adjust.sdk.AdjustSessionFailure;
import com.adjust.sdk.AdjustSessionSuccess;
import com.adjust.sdk.LogLevel;
import com.adjust.sdk.OnAdidReadListener;
import com.adjust.sdk.OnAmazonAdIdReadListener;
import com.adjust.sdk.OnAttributionChangedListener;
import com.adjust.sdk.OnAttributionReadListener;
import com.adjust.sdk.OnDeferredDeeplinkResponseListener;
import com.adjust.sdk.OnEventTrackingFailedListener;
import com.adjust.sdk.OnEventTrackingSucceededListener;
import com.adjust.sdk.OnGoogleAdIdReadListener;
import com.adjust.sdk.OnSdkVersionReadListener;
import com.adjust.sdk.OnSessionTrackingFailedListener;
import com.adjust.sdk.OnSessionTrackingSucceededListener;

import extension.adjust.Utils.Scheme;
import extension.adjust.Utils.Table;

@SuppressWarnings("unused")
public class Extension
        implements OnAttributionChangedListener, OnDeferredDeeplinkResponseListener, OnEventTrackingFailedListener,
        OnEventTrackingSucceededListener, OnSessionTrackingFailedListener, OnSessionTrackingSucceededListener {
    private Activity activity;
    private boolean is_initialized = false;
    private LuaScriptListener script_listener = new LuaScriptListener();
    private static final String ADJUST = "adjust";
    private static final String EVENT_PHASE = "phase";
    private static final String EVENT_INIT = "init";
    private static final String EVENT_IS_ERROR = "is_error";
    private static final String EVENT_ERROR_MESSAGE = "error_message";

    @SuppressWarnings("unused")
    public Extension(android.app.Activity main_activity) {
        activity = main_activity;
        Utils.set_tag(ADJUST);
    }

    // Called from extension_android.cpp each frame.
    @SuppressWarnings("unused")
    public void update(long L) {
        Utils.execute_tasks(L);
    }

    @SuppressWarnings("unused")
    public void app_activate(long L) {
        Adjust.onResume();
    }

    @SuppressWarnings("unused")
    public void app_deactivate(long L) {
        Adjust.onPause();
    }

    @SuppressWarnings("unused")
    public void extension_finalize(long L) {
    }

    @SuppressWarnings("BooleanMethodIsAlwaysInverted")
    private boolean check_is_initialized() {
        if (is_initialized) {
            return true;
        } else {
            Utils.log("The extension is not initialized.");
            return false;
        }
    }

    // region Lua functions

    // adjust.init(params)
    private int init(long L) {
        Utils.check_arg_count(L, 1);
        if (check_is_initialized()) {
            Utils.log("The extension is already initialized.");
            return 0;
        }

        Scheme scheme = new Scheme()
                .string("app_token")
                .bool("is_sandbox")
                .table("app_secret")
                .string("default_tracker")
                .string("log_level")
                .string("process_name")
                .string("sdk_prefix")
                .string("fb_app_id")
                .bool("preinstall_tracking")
                .bool("coppa_compliance")
                .bool("play_store_kids_compliance")
                .number("event_deduplication_ids_max_size")
                .string("external_device_id")
                .function("listener");

        Table params = new Table(L, 1).parse(scheme);
        String app_token = params.get_string_not_null("app_token");
        boolean is_sandbox = params.get_boolean("is_sandbox", false);
        String default_tracker = params.get_string("default_tracker");
        String log_level = params.get_string("log_level");
        String process_name = params.get_string("process_name");
        String sdk_prefix = params.get_string("sdk_prefix");
        String fb_app_id = params.get_string("fb_app_id");
        boolean preinstall_tracking = params.get_boolean("preinstall_tracking", false);
        boolean coppa_compliance = params.get_boolean("coppa_compliance", false);
        boolean play_store_kids_compliance = params.get_boolean("play_store_kids_compliance", false);
        int event_deduplication_ids_max_size = params.get_integer("event_deduplication_ids_max_size", 10);
        String external_device_id = params.get_string("external_device_id");

        Utils.delete_ref_if_not_nil(L, script_listener.listener);
        Utils.delete_ref_if_not_nil(L, script_listener.script_instance);
        script_listener.listener = params.get_function("listener", Lua.REFNIL);
        Lua.dmscript_getinstance(L);
        script_listener.script_instance = Utils.new_ref(L);

        AdjustConfig config = new AdjustConfig(activity, app_token,
                is_sandbox ? AdjustConfig.ENVIRONMENT_SANDBOX : AdjustConfig.ENVIRONMENT_PRODUCTION, true);

        if (default_tracker != null) {
            config.setDefaultTracker(default_tracker);
        }

        if (log_level != null) {
            LogLevel l;
            if (log_level.equals("assert")) {
                l = LogLevel.ASSERT;
            } else if (log_level.equals("debug")) {
                l = LogLevel.DEBUG;
            } else if (log_level.equals("error")) {
                l = LogLevel.ERROR;
            } else if (log_level.equals("suppress")) {
                l = LogLevel.SUPPRESS;
            } else if (log_level.equals("verbose")) {
                l = LogLevel.VERBOSE;
            } else if (log_level.equals("warn")) {
                l = LogLevel.WARN;
            } else {
                l = LogLevel.INFO;
            }
            config.setLogLevel(l);
        }

        if (process_name != null) {
            config.setProcessName(process_name);
        }

        if (sdk_prefix != null) {
            config.setSdkPrefix(sdk_prefix);
        }

        if (fb_app_id != null) {
            config.setFbAppId(fb_app_id);
        }

        if (preinstall_tracking) {
            config.enablePreinstallTracking();
        }

        if (coppa_compliance) {
            config.enableCoppaCompliance();
        }

        if (play_store_kids_compliance) {
            config.enablePlayStoreKidsCompliance();
        }

        if (external_device_id != null) {
            config.externalDeviceId(external_device_id);
        }

        config.setEventDeduplicationIdsMaxSize(event_deduplication_ids_max_size);

        config.setOnAttributionChangedListener(this);
        config.setOnDeferredDeeplinkResponseListener(this);
        config.setOnEventTrackingFailedListener(this);
        config.setOnEventTrackingSucceededListener(this);
        config.setOnSessionTrackingFailedListener(this);
        config.setOnSessionTrackingSucceededListener(this);

        Adjust.initSdk(config);
        Adjust.onResume();

        is_initialized = true;
        Hashtable<Object, Object> event = Utils.new_event(ADJUST);
        Utils.put(event, EVENT_PHASE, EVENT_INIT);
        Utils.put(event, EVENT_IS_ERROR, false);
        Utils.dispatch_event(script_listener, event);

        return 0;
    }

    // adjust.track_event(params)
    private int track_event(long L) {
        Utils.check_arg_count(L, 1);
        if (!check_is_initialized()) {
            return 0;
        }

        Scheme scheme = new Scheme()
                .string("token")
                .number("revenue")
                .string("currency")
                .string("transaction_id")
                .string("callback_id")
                .table("callback_parameters")
                .string("callback_parameters.#")
                .table("partner_parameters")
                .string("partner_parameters.#");

        Table params = new Table(L, 1).parse(scheme);
        String token = params.get_string_not_null("token");
        Double revenue = params.get_double("revenue");
        String currency = params.get_string("currency");
        String transaction_id = params.get_string("transaction_id");
        String callback_id = params.get_string("callback_id");
        Hashtable<Object, Object> callback_parameters = params.get_table("callback_parameters");
        Hashtable<Object, Object> partner_parameters = params.get_table("partner_parameters");

        AdjustEvent event = new AdjustEvent(token);

        if (revenue != null && currency != null) {
            event.setRevenue(revenue, currency);
            if (transaction_id != null) {
                // event.setOrderId(transaction_id);
                event.setDeduplicationId(transaction_id);
            }
        }

        if (callback_id != null) {
            event.setCallbackId(callback_id);
        }

        if (callback_parameters != null) {
            for (Object o : callback_parameters.entrySet()) {
                Map.Entry entry = (Map.Entry) o;
                event.addCallbackParameter((String) entry.getKey(), (String) entry.getValue());
            }
        }

        if (partner_parameters != null) {
            for (Object o : partner_parameters.entrySet()) {
                Map.Entry entry = (Map.Entry) o;
                event.addPartnerParameter((String) entry.getKey(), (String) entry.getValue());
            }
        }

        Adjust.trackEvent(event);

        return 0;
    }

    // adjust.set_session_parameters(params)
    private int set_session_parameters(long L) {
        Utils.check_arg_count(L, 1);
        if (!check_is_initialized()) {
            return 0;
        }
        Scheme scheme = new Scheme()
                .table("callback_parameters")
                .string("callback_parameters.#")
                .table("partner_parameters")
                .string("partner_parameters.#");

        Table params = new Table(L, 1).parse(scheme);
        Hashtable<Object, Object> callback_parameters = params.get_table("callback_parameters");
        Hashtable<Object, Object> partner_parameters = params.get_table("partner_parameters");

        if (callback_parameters != null) {
            Adjust.removeGlobalCallbackParameters();
            for (Object o : callback_parameters.entrySet()) {
                Map.Entry entry = (Map.Entry) o;
                Adjust.addGlobalCallbackParameter((String) entry.getKey(), (String) entry.getValue());
            }
        }

        if (partner_parameters != null) {
            Adjust.removeGlobalPartnerParameters();
            for (Object o : partner_parameters.entrySet()) {
                Map.Entry entry = (Map.Entry) o;
                Adjust.addGlobalPartnerParameter((String) entry.getKey(), (String) entry.getValue());
            }
        }
        return 0;
    }

    // adjust.enable()
    private int enable(long L) {
        if (!check_is_initialized()) {
            return 0;
        }

        Adjust.enable();
        return 0;
    }

    // adjust.disable()
    private int disable(long L) {
        if (!check_is_initialized()) {
            return 0;
        }

        Adjust.disable();
        return 0;
    }

    // adjust.set_pushtoken(token)
    private int set_pushtoken(long L) {
        Utils.check_arg_count(L, 1);
        if (!check_is_initialized()) {
            return 0;
        }
        if (Lua.type(L, 1) == Lua.Type.STRING) {
            Adjust.setPushToken(Lua.tostring(L, 1), activity);
        }
        return 0;
    }

    // adjust.switch_to_offline_mode()
    private int switch_to_offline_mode(long L) {
        if (!check_is_initialized()) {
            return 0;
        }

        Adjust.switchToOfflineMode();
        return 0;
    }

    // adjust.switch_back_to_online_mode()
    private int switch_back_to_online_mode(long L) {
        if (!check_is_initialized()) {
            return 0;
        }

        Adjust.switchBackToOnlineMode();
        return 0;
    }

    // adjust.processDeeplink(url)
    private int process_deeplink(long L) {
        Utils.check_arg_count(L, 1);
        if (!check_is_initialized()) {
            return 0;
        }
        if (Lua.type(L, 1) == Lua.Type.STRING) {
            Uri uri = Uri.parse(Lua.tostring(L, 1));
            Adjust.processDeeplink(new AdjustDeeplink(uri), activity);
        }
        return 0;
    }

    // adjust.gdpr_forget_me()
    private int gdpr_forget_me(long L) {
        Utils.check_arg_count(L, 0);
        if (!check_is_initialized()) {
            return 0;
        }
        Adjust.gdprForgetMe(activity);
        return 0;
    }

    // adjust.get_attribution()
    private int get_attribution(long L) {

        Utils.check_arg_count(L, 1);
        if (!check_is_initialized()) {
            return 0;
        }
        if (Lua.type(L, 1) == Lua.Type.FUNCTION) {
            final LuaScriptListener sl = new LuaScriptListener();
            sl.listener = Utils.new_ref(L, 1);
            Lua.dmscript_getinstance(L);
            sl.script_instance = Utils.new_ref(L);
            Adjust.getAttribution(new OnAttributionReadListener() {
                @Override
                public void onAttributionRead(AdjustAttribution attribution) {
                    Hashtable<Object, Object> table = new Hashtable<Object, Object>();
                    Utils.put(table, "adgroup", attribution.adgroup);
                    Utils.put(table, "campaign", attribution.campaign);
                    Utils.put(table, "click_label", attribution.clickLabel);
                    Utils.put(table, "creative", attribution.creative);
                    Utils.put(table, "network", attribution.network);
                    Utils.put(table, "tracker_name", attribution.trackerName);
                    Utils.put(table, "tracker_token", attribution.trackerToken);
                    Utils.dispatch_event(sl, table, true);
                }
            });
        }

        return 0;
    }

    // adjust.get_adid()
    private int get_adid(long L) {
        Utils.check_arg_count(L, 1);
        if (!check_is_initialized()) {
            return 0;
        }
        if (Lua.type(L, 1) == Lua.Type.FUNCTION) {
            final LuaScriptListener sl = new LuaScriptListener();
            sl.listener = Utils.new_ref(L, 1);
            Lua.dmscript_getinstance(L);
            sl.script_instance = Utils.new_ref(L);
            Adjust.getAdid(new OnAdidReadListener() {
                @Override
                public void onAdidRead(String adid) {
                    Utils.dispatch_event(sl, adid, true);
                }
            });
        }
        return 0;
    }

    // adjust.get_amazon_ad_id()
    private int get_amazon_ad_id(long L) {
        Utils.check_arg_count(L, 1);
        if (!check_is_initialized()) {
            return 0;
        }
        if (Lua.type(L, 1) == Lua.Type.FUNCTION) {
            final LuaScriptListener sl = new LuaScriptListener();
            sl.listener = Utils.new_ref(L, 1);
            Lua.dmscript_getinstance(L);
            sl.script_instance = Utils.new_ref(L);
            Adjust.getAmazonAdId(activity, new OnAmazonAdIdReadListener() {
                @Override
                public void onAmazonAdIdRead(String amazon_ad_id) {
                    Utils.dispatch_event(sl, amazon_ad_id, true);
                }
            });
        }
        return 0;
    }

    // adjust.get_google_ad_id(listener)
    private int get_google_ad_id(long L) {
        Utils.check_arg_count(L, 1);
        if (!check_is_initialized()) {
            return 0;
        }
        if (Lua.type(L, 1) == Lua.Type.FUNCTION) {
            final LuaScriptListener sl = new LuaScriptListener();
            sl.listener = Utils.new_ref(L, 1);
            Lua.dmscript_getinstance(L);
            sl.script_instance = Utils.new_ref(L);
            Adjust.getGoogleAdId(activity, new OnGoogleAdIdReadListener() {
                @Override
                public void onGoogleAdIdRead(String google_ad_id) {
                    Utils.dispatch_event(sl, google_ad_id, true);
                }
            });
        }
        return 0;
    }

    // adjust.get_sdk_version()
    private int get_sdk_version(long L) {
        Utils.check_arg_count(L, 1);
        if (!check_is_initialized()) {
            return 0;
        }
        if (Lua.type(L, 1) == Lua.Type.FUNCTION) {
            final LuaScriptListener sl = new LuaScriptListener();
            sl.listener = Utils.new_ref(L, 1);
            Lua.dmscript_getinstance(L);
            sl.script_instance = Utils.new_ref(L);
            Adjust.getSdkVersion(new OnSdkVersionReadListener() {
                @Override
                public void onSdkVersionRead(String sdk_version) {
                    Utils.dispatch_event(sl, sdk_version, true);
                }
            });
        }
        return 0;
    }

    @Override
    public void onAttributionChanged(AdjustAttribution adjustAttribution) {
        Hashtable<Object, Object> event = Utils.new_event(ADJUST);
        Utils.put(event, EVENT_PHASE, "attribution_changed");
        Utils.put(event, EVENT_IS_ERROR, false);
        Utils.put(event, "adgroup", adjustAttribution.adgroup);
        // Utils.put(event, "adid", adjustAttribution.adid);
        Utils.put(event, "campaign", adjustAttribution.campaign);
        Utils.put(event, "click_label", adjustAttribution.clickLabel);
        Utils.put(event, "creative", adjustAttribution.creative);
        Utils.put(event, "network", adjustAttribution.network);
        Utils.put(event, "tracker_name", adjustAttribution.trackerName);
        Utils.put(event, "tracker_token", adjustAttribution.trackerToken);
        Utils.dispatch_event(script_listener, event);
    }

    @Override
    public boolean launchReceivedDeeplink(Uri uri) {
        Hashtable<Object, Object> event = Utils.new_event(ADJUST);
        Utils.put(event, EVENT_PHASE, "deeplink");
        Utils.put(event, EVENT_IS_ERROR, false);
        Utils.put(event, "url", uri.toString());
        Utils.dispatch_event(script_listener, event);
        return false;
    }

    @Override
    public void onEventTrackingFailed(AdjustEventFailure adjustEventFailure) {
        Hashtable<Object, Object> event = Utils.new_event(ADJUST);
        Utils.put(event, EVENT_PHASE, "event_tracking");
        Utils.put(event, EVENT_IS_ERROR, false);
        Utils.put(event, "callback_id", adjustEventFailure.callbackId);
        Utils.put(event, "adid", adjustEventFailure.adid);
        Utils.put(event, "event_token", adjustEventFailure.eventToken);
        Utils.put(event, "message", adjustEventFailure.message);
        Utils.put(event, "timestamp", adjustEventFailure.timestamp);
        Utils.put(event, "will_retry", adjustEventFailure.willRetry);
        Utils.dispatch_event(script_listener, event);
    }

    @Override
    public void onEventTrackingSucceeded(AdjustEventSuccess adjustEventSuccess) {
        Hashtable<Object, Object> event = Utils.new_event(ADJUST);
        Utils.put(event, EVENT_PHASE, "event_tracking");
        Utils.put(event, EVENT_IS_ERROR, false);
        Utils.put(event, "callback_id", adjustEventSuccess.callbackId);
        Utils.put(event, "adid", adjustEventSuccess.adid);
        Utils.put(event, "event_token", adjustEventSuccess.eventToken);
        Utils.put(event, "message", adjustEventSuccess.message);
        Utils.put(event, "timestamp", adjustEventSuccess.timestamp);
        Utils.dispatch_event(script_listener, event);
    }

    @Override
    public void onSessionTrackingFailed(AdjustSessionFailure adjustSessionFailure) {
        Hashtable<Object, Object> event = Utils.new_event(ADJUST);
        Utils.put(event, EVENT_PHASE, "session_tracking");
        Utils.put(event, EVENT_IS_ERROR, false);
        Utils.put(event, "adid", adjustSessionFailure.adid);
        Utils.put(event, "message", adjustSessionFailure.message);
        Utils.put(event, "timestamp", adjustSessionFailure.timestamp);
        Utils.put(event, "will_retry", adjustSessionFailure.willRetry);
        Utils.dispatch_event(script_listener, event);
    }

    @Override
    public void onSessionTrackingSucceeded(AdjustSessionSuccess adjustSessionSuccess) {
        Hashtable<Object, Object> event = Utils.new_event(ADJUST);
        Utils.put(event, EVENT_PHASE, "session_tracking");
        Utils.put(event, EVENT_IS_ERROR, false);
        Utils.put(event, "adid", adjustSessionSuccess.adid);
        Utils.put(event, "message", adjustSessionSuccess.message);
        Utils.put(event, "timestamp", adjustSessionSuccess.timestamp);
        Utils.dispatch_event(script_listener, event);
    }
    // endregion
}
