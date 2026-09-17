#if defined(DM_PLATFORM_IOS)

#import <AdjustSdk/AdjustSdk.h>
#include "extension.h"

#import "ios/utils.h"

#define ExtensionInterface FUNCTION_NAME_EXPANDED(EXTENSION_NAME, ExtensionInterface)

// Using proper Objective-C object for main extension entity.
@interface ExtensionInterface : NSObject <AdjustDelegate>
@end

@implementation ExtensionInterface {
    bool is_initialized;
    LuaScriptListener *script_listener;
}

static NSString *const ADJUST = @"adjust";
static NSString *const EVENT_PHASE = @"phase";
static NSString *const EVENT_INIT = @"init";
static NSString *const EVENT_IS_ERROR = @"is_error";
static NSString *const EVENT_ERROR_MESSAGE = @"error_message";

static ExtensionInterface *extension_instance;
int EXTENSION_INIT(lua_State *L) {return [extension_instance init_:L];}
int EXTENSION_TRACK_EVENT(lua_State *L) {return [extension_instance track_event:L];}
int EXTENSION_TRACK_AD_REVENUE(lua_State *L) {return [extension_instance track_ad_revenue:L];}
int EXTENSION_SET_SESSION_PARAMETERS(lua_State *L) {return [extension_instance set_session_parameters:L];}
int EXTENSION_ENABLE(lua_State *L) {return [extension_instance enable:L];}
int EXTENSION_DISABLE(lua_State *L) {return [extension_instance disable:L];}
int EXTENSION_SET_PUSHTOKEN(lua_State *L) {return [extension_instance set_pushtoken:L];}
int EXTENSION_SWITCH_TO_OFFLINE_MODE(lua_State *L) {return [extension_instance switch_to_offline_mode:L];}
int EXTENSION_SWITCH_BACK_TO_ONLINE_MODE(lua_State *L) {return [extension_instance switch_back_to_online_mode:L];}
int EXTENSION_PROCESS_DEEPLINK(lua_State *L) {return [extension_instance process_deeplink:L];}
int EXTENSION_GDPR_FORGET_ME(lua_State *L) {return [extension_instance gdpr_forget_me:L];}
int EXTENSION_GET_ATTRIBUTION(lua_State *L) {return [extension_instance get_attribution:L];}
int EXTENSION_GET_ADID(lua_State *L) {return [extension_instance get_adid:L];}
int EXTENSION_GET_AMAZON_AD_ID(lua_State *L) {return [extension_instance get_amazon_ad_id:L];}
int EXTENSION_GET_GOOGLE_AD_ID(lua_State *L) {return [extension_instance get_google_ad_id:L];}
int EXTENSION_GET_SDK_VERSION(lua_State *L) {return [extension_instance get_sdk_version:L];}
int EXTENSION_GET_IDFA(lua_State *L) {return [extension_instance get_idfa:L];}

-(id)init {
    self = [super init];
    if (self) {
        is_initialized = false;
        script_listener = [LuaScriptListener new];
        script_listener.listener = LUA_REFNIL;
        script_listener.script_instance = LUA_REFNIL;
    }
    return self;
}

-(bool)check_is_initialized {
	if (is_initialized) {
		return true;
	} else {
		dmLogInfo("The extension is not initialized.");
		return false;
	}
}

# pragma mark - Lua functions -

// adjust.init(params)
-(int)init_:(lua_State*)L {
	[Utils check_arg_count:L count:1];
	if (is_initialized) {
		dmLogInfo("The extension is already initialized.");
		return 0;
	}

    Scheme *scheme = [[Scheme alloc] init];
	[scheme string:@"app_token"];
	[scheme string:@"fb_app_id"];
	[scheme string:@"external_device_id"];
	[scheme boolean:@"is_sandbox"];
	[scheme string:@"default_tracker"];
	[scheme string:@"log_level"];
	[scheme string:@"sdk_prefix"];
	[scheme boolean:@"send_in_background"];
    [scheme function:@"listener"];

    Table *params = [[Table alloc] init:L index:1];
    [params parse:scheme];

	NSString *app_token = [params get_string_not_null:@"app_token"];
	NSString *fb_app_id = [params get_string:@"fb_app_id"];
	NSString *external_device_id = [params get_string:@"external_device_id"];
	bool is_sandbox = [params get_boolean:@"is_sandbox" default:false];
	// app_secret, delay_start, is_device_known, event_buffering, user_agent — removed in v5
	NSString *default_tracker = [params get_string:@"default_tracker"];
	NSString *log_level = [params get_string:@"log_level"];
	NSString *sdk_prefix = [params get_string:@"sdk_prefix"];
	NSNumber *send_in_background = [params get_boolean:@"send_in_background"];

	[Utils delete_ref_if_not_nil:script_listener.listener];
	[Utils delete_ref_if_not_nil:script_listener.script_instance];
    script_listener.listener = [params get_function:@"listener" default:LUA_REFNIL];
	dmScript::GetInstance(L);
	script_listener.script_instance = [Utils new_ref:L];

	ADJConfig *config = [[ADJConfig alloc] initWithAppToken:app_token
	                                            environment:is_sandbox ? ADJEnvironmentSandbox : ADJEnvironmentProduction];


	if (fb_app_id) {
		[config setFbAppId:fb_app_id];
	}

	if (external_device_id) {
		[config setExternalDeviceId:external_device_id];
	}

	if (default_tracker) {
		[config setDefaultTracker:default_tracker];
	}

	if (log_level) {
		ADJLogLevel l;
		if ([log_level isEqualToString:@"assert"]) {
			l = ADJLogLevelAssert;
		} else if ([log_level isEqualToString:@"debug"]) {
			l = ADJLogLevelDebug;
		} else if ([log_level isEqualToString:@"error"]) {
			l = ADJLogLevelError;
		} else if ([log_level isEqualToString:@"suppress"]) {
			l = ADJLogLevelSuppress;
		} else if ([log_level isEqualToString:@"verbose"]) {
			l = ADJLogLevelVerbose;
		} else if ([log_level isEqualToString:@"warn"]) {
			l = ADJLogLevelWarn;
		} else {
			l = ADJLogLevelInfo;
		}
		[config setLogLevel:l];
	}

	if (sdk_prefix) {
		[config setSdkPrefix:sdk_prefix];
	}

	if (send_in_background && send_in_background.boolValue) {
		[config enableSendingInBackground];
	}

	[config setDelegate:self];

	[Adjust initSdk:config];

    is_initialized = true;
    NSMutableDictionary *event = [Utils new_event:ADJUST];
    event[EVENT_PHASE] = EVENT_INIT;
    event[EVENT_IS_ERROR] = @((bool)false);
    [Utils dispatch_event:script_listener event:event];
	return 0;
}

// adjust.track_event(params)
-(int)track_event:(lua_State*)L {
	[Utils check_arg_count:L count:1];
	if (![self check_is_initialized]) {
		return 0;
	}

	Scheme *scheme = [[Scheme alloc] init];
	[scheme string:@"token"];
	[scheme number:@"revenue"];
	[scheme string:@"currency"];
	[scheme string:@"transaction_id"];
	[scheme string:@"callback_id"];
	[scheme string:@"deduplication_id"];   // new in v5 (replaces transaction_id for dedup)
	[scheme table:@"callback_parameters"];
	[scheme string:@"callback_parameters.#"];
	[scheme table:@"partner_parameters"];
	[scheme string:@"partner_parameters.#"];

	Table *params = [[Table alloc] init:L index:1];
	[params parse:scheme];

	NSString *token = [params get_string_not_null:@"token"];
	NSNumber *revenue = [params get_double:@"revenue"];
	NSString *currency = [params get_string:@"currency"];
	NSString *transaction_id = [params get_string:@"transaction_id"];
	NSString *callback_id = [params get_string:@"callback_id"];
	NSString *deduplication_id = [params get_string:@"deduplication_id"];
	NSDictionary *callback_parameters = [params get_table:@"callback_parameters"];
	NSDictionary *partner_parameters = [params get_table:@"partner_parameters"];

	ADJEvent *event = [[ADJEvent alloc] initWithEventToken:token];

	if (revenue && currency) {
		[event setRevenue:revenue.doubleValue currency:currency];
	}
	if (transaction_id) {
		[event setTransactionId:transaction_id];
	}
	if (callback_id) {
		[event setCallbackId:callback_id];
	}
	if (deduplication_id) {
		[event setDeduplicationId:deduplication_id];
	}

	if (callback_parameters) {
		for (id key in callback_parameters) {
			[event addCallbackParameter:(NSString*)key value:(NSString*)[callback_parameters objectForKey:key]];
		}
	}

	if (partner_parameters) {
		for (id key in partner_parameters) {
			[event addPartnerParameter:(NSString*)key value:(NSString*)[partner_parameters objectForKey:key]];
		}
	}

	[Adjust trackEvent:event];

	return 0;
}

// adjust.track_ad_revenue(params)
-(int)track_ad_revenue:(lua_State*)L {
	[Utils check_arg_count:L count:1];
	if (![self check_is_initialized]) {
		return 0;
	}

	Scheme *scheme = [[Scheme alloc] init];
	[scheme string:@"source"];                    // required: "applovin_max_sdk", "admob_sdk", etc.
	[scheme number:@"revenue"];
	[scheme string:@"currency"];
	[scheme number:@"ad_impressions_count"];
	[scheme string:@"ad_revenue_network"];
	[scheme string:@"ad_revenue_unit"];
	[scheme string:@"ad_revenue_placement"];
	[scheme table:@"callback_parameters"];
	[scheme string:@"callback_parameters.#"];
	[scheme table:@"partner_parameters"];
	[scheme string:@"partner_parameters.#"];

	Table *params = [[Table alloc] init:L index:1];
	[params parse:scheme];

	NSString *source = [params get_string_not_null:@"source"];
	NSNumber *revenue = [params get_double:@"revenue"];
	NSString *currency = [params get_string:@"currency"];
	NSNumber *ad_impressions_count = [params get_long:@"ad_impressions_count"];
	NSString *ad_revenue_network = [params get_string:@"ad_revenue_network"];
	NSString *ad_revenue_unit = [params get_string:@"ad_revenue_unit"];
	NSString *ad_revenue_placement = [params get_string:@"ad_revenue_placement"];
	NSDictionary *callback_parameters = [params get_table:@"callback_parameters"];
	NSDictionary *partner_parameters = [params get_table:@"partner_parameters"];

	ADJAdRevenue *adRevenue = [[ADJAdRevenue alloc] initWithSource:source];
	if (!adRevenue) {
		dmLogInfo("Failed to create ADJAdRevenue with source: %s", [source UTF8String]);
		return 0;
	}

	if (revenue && currency) {
		[adRevenue setRevenue:revenue.doubleValue currency:currency];
	}

	if (ad_impressions_count) {
		[adRevenue setAdImpressionsCount:ad_impressions_count.intValue];
	}

	if (ad_revenue_network) {
		[adRevenue setAdRevenueNetwork:ad_revenue_network];
	}

	if (ad_revenue_unit) {
		[adRevenue setAdRevenueUnit:ad_revenue_unit];
	}

	if (ad_revenue_placement) {
		[adRevenue setAdRevenuePlacement:ad_revenue_placement];
	}

	if (callback_parameters) {
		for (id key in callback_parameters) {
			[adRevenue addCallbackParameter:(NSString*)key value:(NSString*)[callback_parameters objectForKey:key]];
		}
	}

	if (partner_parameters) {
		for (id key in partner_parameters) {
			[adRevenue addPartnerParameter:(NSString*)key value:(NSString*)[partner_parameters objectForKey:key]];
		}
	}

	[Adjust trackAdRevenue:adRevenue];

	return 0;
}

// adjust.set_session_parameters(params)  — now Global parameters in v5
-(int)set_session_parameters:(lua_State*)L {
	[Utils check_arg_count:L count:1];
	if (![self check_is_initialized]) {
		return 0;
	}

	Scheme *scheme = [[Scheme alloc] init];
	[scheme table:@"callback_parameters"];
	[scheme string:@"callback_parameters.#"];
	[scheme table:@"partner_parameters"];
	[scheme string:@"partner_parameters.#"];

	Table *params = [[Table alloc] init:L index:1];
	[params parse:scheme];

	NSDictionary *callback_parameters = [params get_table:@"callback_parameters"];
	NSDictionary *partner_parameters = [params get_table:@"partner_parameters"];

	if (callback_parameters) {
		[Adjust removeGlobalCallbackParameters];
		for (id key in callback_parameters) {
			[Adjust addGlobalCallbackParameter:(NSString*)[callback_parameters objectForKey:key] forKey:(NSString*)key];
		}
	}

	if (partner_parameters) {
		[Adjust removeGlobalPartnerParameters];
		for (id key in partner_parameters) {
			[Adjust addGlobalPartnerParameter:(NSString*)[partner_parameters objectForKey:key] forKey:(NSString*)key];
		}
	}

	return 0;
}

// adjust.enable()
-(int)enable:(lua_State*)L {
	[Utils check_arg_count:L count:0];
	if (![self check_is_initialized]) {
		return 0;
	}
	[Adjust enable];
	return 0;
}

// adjust.disable()
-(int)disable:(lua_State*)L {
	[Utils check_arg_count:L count:0];
	if (![self check_is_initialized]) {
		return 0;
	}
	[Adjust disable];
	return 0;
}

// adjust.set_pushtoken(token)
-(int)set_pushtoken:(lua_State*)L {
	[Utils check_arg_count:L count:1];
	if (![self check_is_initialized]) {
		return 0;
	}
	if (lua_isstring(L, 1)) {
		// v5 prefers NSData, but string overload still works in many builds
		NSString *tokenStr = @(lua_tostring(L, 1));
		NSData *tokenData = [tokenStr dataUsingEncoding:NSUTF8StringEncoding];
		[Adjust setPushToken:tokenData];
	}
	return 0;
}

// adjust.switch_to_offline_mode()
-(int)switch_to_offline_mode:(lua_State*)L {
	[Utils check_arg_count:L count:0];
	if (![self check_is_initialized]) {
		return 0;
	}
	[Adjust switchToOfflineMode];
	return 0;
}

// adjust.switch_back_to_online_mode()
-(int)switch_back_to_online_mode:(lua_State*)L {
	[Utils check_arg_count:L count:0];
	if (![self check_is_initialized]) {
		return 0;
	}
	[Adjust switchBackToOnlineMode];
	return 0;
}

// adjust.process_deeplink(url)
-(int)process_deeplink:(lua_State*)L {
	[Utils check_arg_count:L count:1];
	if (![self check_is_initialized]) {
		return 0;
	}
	if (lua_isstring(L, 1)) {
		NSURL *url = [NSURL URLWithString:@(lua_tostring(L, 1))];
		if (url) {
			ADJDeeplink *deeplink = [[ADJDeeplink alloc] initWithDeeplink:url];
			[Adjust processDeeplink:deeplink];
		}
	}
	return 0;
}

// adjust.gdpr_forget_me()
-(int)gdpr_forget_me:(lua_State*)L {
	[Utils check_arg_count:L count:0];
	if (![self check_is_initialized]) {
		return 0;
	}
	[Adjust gdprForgetMe];
	return 0;
}

// adjust.get_attribution() — now async
-(int)get_attribution:(lua_State*)L {
	[Utils check_arg_count:L count:1];
	if (![self check_is_initialized]) {
		return 0;
	}
	[Adjust attributionWithCompletionHandler:^(ADJAttribution * _Nullable attribution) {
		NSMutableDictionary *event = [Utils new_event:ADJUST];
		event[EVENT_PHASE] = @"attribution";
		event[EVENT_IS_ERROR] = @((bool)false);
		if (attribution) {
			[Utils put:event key:@"adgroup" value:attribution.adgroup];
			[Utils put:event key:@"campaign" value:attribution.campaign];
			[Utils put:event key:@"click_label" value:attribution.clickLabel];
			[Utils put:event key:@"creative" value:attribution.creative];
			[Utils put:event key:@"network" value:attribution.network];
			[Utils put:event key:@"tracker_name" value:attribution.trackerName];
			[Utils put:event key:@"tracker_token" value:attribution.trackerToken];
			// adid removed from ADJAttribution in v5
		}
		[Utils dispatch_event:script_listener event:event];
	}];
	return 0;
}

// adjust.get_adid() — now async
-(int)get_adid:(lua_State*)L {
	[Utils check_arg_count:L count:0];
	if (![self check_is_initialized]) {
		return 0;
	}
	[Adjust adidWithCompletionHandler:^(NSString * _Nullable adid) {
		NSMutableDictionary *event = [Utils new_event:ADJUST];
		event[EVENT_PHASE] = @"adid";
		event[EVENT_IS_ERROR] = @((bool)false);
		[Utils put:event key:@"adid" value:adid];
		[Utils dispatch_event:script_listener event:event];
	}];
	return 0;
}

// adjust.get_amazon_ad_id()
-(int)get_amazon_ad_id:(lua_State*)L {
	[Utils check_arg_count:L count:0];
	if (![self check_is_initialized]) {
		return 0;
	}
	return 0;
}

// adjust.get_google_ad_id()
-(int)get_google_ad_id:(lua_State*)L {
	[Utils check_arg_count:L count:1];
	if (![self check_is_initialized]) {
		return 0;
	}
	return 0;
}

// adjust.get_sdk_version() — now async
-(int)get_sdk_version:(lua_State*)L {
	[Utils check_arg_count:L count:0];
	if (![self check_is_initialized]) {
		return 0;
	}
	[Adjust sdkVersionWithCompletionHandler:^(NSString * _Nullable sdkVersion) {
		NSMutableDictionary *event = [Utils new_event:ADJUST];
		event[EVENT_PHASE] = @"sdk_version";
		event[EVENT_IS_ERROR] = @((bool)false);
		[Utils put:event key:@"sdk_version" value:sdkVersion];
		[Utils dispatch_event:script_listener event:event];
	}];
	return 0;
}

// adjust.get_idfa() — now async
-(int)get_idfa:(lua_State*)L {
	[Utils check_arg_count:L count:0];
	if (![self check_is_initialized]) {
		return 0;
	}
	[Adjust idfaWithCompletionHandler:^(NSString * _Nullable idfa) {
		NSMutableDictionary *event = [Utils new_event:ADJUST];
		event[EVENT_PHASE] = @"idfa";
		event[EVENT_IS_ERROR] = @((bool)false);
		[Utils put:event key:@"idfa" value:idfa];
		[Utils dispatch_event:script_listener event:event];
	}];
	return 0;
}

#pragma mark - AdjustDelegate -

-(void)adjustAttributionChanged:(nullable ADJAttribution *)attribution {
	NSMutableDictionary *event = [Utils new_event:ADJUST];
	event[EVENT_PHASE] = @"attribution_changed";
	event[EVENT_IS_ERROR] = @((bool)false);
	[Utils put:event key:@"adgroup" value:attribution.adgroup];
	// adid removed from ADJAttribution in v5
	[Utils put:event key:@"campaign" value:attribution.campaign];
	[Utils put:event key:@"click_label" value:attribution.clickLabel];
	[Utils put:event key:@"creative" value:attribution.creative];
	[Utils put:event key:@"network" value:attribution.network];
	[Utils put:event key:@"tracker_name" value:attribution.trackerName];
	[Utils put:event key:@"tracker_token" value:attribution.trackerToken];
	[Utils dispatch_event:script_listener event:event];
}

-(void)adjustEventTrackingSucceeded:(nullable ADJEventSuccess *)eventSuccessResponseData {
	NSMutableDictionary *event = [Utils new_event:ADJUST];
	event[EVENT_PHASE] = @"event_tracking";
	event[EVENT_IS_ERROR] = @((bool)false);
	[Utils put:event key:@"callback_id" value:eventSuccessResponseData.callbackId];
	[Utils put:event key:@"adid" value:eventSuccessResponseData.adid];
	[Utils put:event key:@"event_token" value:eventSuccessResponseData.eventToken];
	[Utils put:event key:@"message" value:eventSuccessResponseData.message];
	[Utils put:event key:@"timestamp" value:eventSuccessResponseData.timestamp];
	[Utils dispatch_event:script_listener event:event];
}

-(void)adjustEventTrackingFailed:(nullable ADJEventFailure *)eventFailureResponseData {
	NSMutableDictionary *event = [Utils new_event:ADJUST];
	event[EVENT_PHASE] = @"event_tracking";
	event[EVENT_IS_ERROR] = @((bool)true);
	[Utils put:event key:@"callback_id" value:eventFailureResponseData.callbackId];
	[Utils put:event key:@"adid" value:eventFailureResponseData.adid];
	[Utils put:event key:@"event_token" value:eventFailureResponseData.eventToken];
	[Utils put:event key:@"message" value:eventFailureResponseData.message];
	[Utils put:event key:@"timestamp" value:eventFailureResponseData.timestamp];
	[Utils put:event key:@"will_retry" value:@(eventFailureResponseData.willRetry)];
	[Utils dispatch_event:script_listener event:event];
}

-(void)adjustSessionTrackingSucceeded:(nullable ADJSessionSuccess *)sessionSuccessResponseData {
	NSMutableDictionary *event = [Utils new_event:ADJUST];
	event[EVENT_PHASE] = @"session_tracking";
	event[EVENT_IS_ERROR] = @((bool)false);
	[Utils put:event key:@"adid" value:sessionSuccessResponseData.adid];
	[Utils put:event key:@"message" value:sessionSuccessResponseData.message];
	[Utils put:event key:@"timestamp" value:sessionSuccessResponseData.timestamp];
	[Utils dispatch_event:script_listener event:event];
}

-(void)adjustSessionTrackingFailed:(nullable ADJSessionFailure *)sessionFailureResponseData {
	NSMutableDictionary *event = [Utils new_event:ADJUST];
	event[EVENT_PHASE] = @"session_tracking";
	event[EVENT_IS_ERROR] = @((bool)true);
	[Utils put:event key:@"adid" value:sessionFailureResponseData.adid];
	[Utils put:event key:@"message" value:sessionFailureResponseData.message];
	[Utils put:event key:@"timestamp" value:sessionFailureResponseData.timestamp];
	[Utils put:event key:@"will_retry" value:@(sessionFailureResponseData.willRetry)];
	[Utils dispatch_event:script_listener event:event];
}

-(BOOL)adjustDeferredDeeplinkReceived:(nullable NSURL *)deeplink {
	NSMutableDictionary *event = [Utils new_event:ADJUST];
	event[EVENT_PHASE] = @"deeplink";
	event[EVENT_IS_ERROR] = @((bool)false);
	[Utils put:event key:@"url" value:deeplink.absoluteString];
	[Utils dispatch_event:script_listener event:event];
	return true;
}

@end

#pragma mark - Defold lifecycle -

void EXTENSION_INITIALIZE(lua_State *L) {
    extension_instance = [[ExtensionInterface alloc] init];
}

void EXTENSION_UPDATE(lua_State *L) {
	[Utils execute_tasks:L];
}

void EXTENSION_APP_ACTIVATE(lua_State *L) {
}

void EXTENSION_APP_DEACTIVATE(lua_State *L) {
}

void EXTENSION_FINALIZE(lua_State *L) {
    extension_instance = nil;
}

#endif
