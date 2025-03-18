#if !defined(DM_PLATFORM_IOS) && !defined(DM_PLATFORM_ANDROID)

#include "extension.h"

int EXTENSION_INIT(lua_State *L)
{
	dmLogInfo("init");
	return 0;
}

int EXTENSION_TRACK_EVENT(lua_State *L)
{
	dmLogInfo("track_event");
	return 0;
}

int EXTENSION_TRACK_AD_REVENUE(lua_State *L)
{
	dmLogInfo("track_ad_revenue");
	return 0;
}

int EXTENSION_SET_SESSION_PARAMETERS(lua_State *L)
{
	dmLogInfo("set_session_parameters");
	return 0;
}

int EXTENSION_ENABLE(lua_State *L)
{
	dmLogInfo("enabled");
	return 0;
}

int EXTENSION_DISABLE(lua_State *L)
{
	dmLogInfo("disable");
	return 0;
}

int EXTENSION_SET_PUSHTOKEN(lua_State *L)
{
	dmLogInfo("set_pushtoken");
	return 0;
}

int EXTENSION_SWITCH_TO_OFFLINE_MODE(lua_State *L)
{
	dmLogInfo("switch_to_offline_mode");
	return 0;
}

int EXTENSION_SWITCH_BACK_TO_ONLINE_MODE(lua_State *L)
{
	dmLogInfo("switch_back_to_online_mode");
	return 0;
}

int EXTENSION_PROCESS_DEEPLINK(lua_State *L)
{
	dmLogInfo("process_deeplink");
	return 0;
}

int EXTENSION_GDPR_FORGET_ME(lua_State *L)
{
	dmLogInfo("gdpr_forget_me");
	return 0;
}

int EXTENSION_GET_ATTRIBUTION(lua_State *L)
{
	dmLogInfo("get_attribution");
	return 0;
}

int EXTENSION_GET_ADID(lua_State *L)
{
	dmLogInfo("get_adid");
	return 0;
}

int EXTENSION_GET_AMAZON_AD_ID(lua_State *L)
{
	dmLogInfo("get_amazon_ad_id");
	return 0;
}

int EXTENSION_GET_GOOGLE_AD_ID(lua_State *L)
{
	dmLogInfo("get_google_ad_id");
	return 0;
}

int EXTENSION_GET_SDK_VERSION(lua_State *L)
{
	dmLogInfo("get_sdk_version");
	return 0;
}

void EXTENSION_INITIALIZE(lua_State *L)
{
}

void EXTENSION_UPDATE(lua_State *L)
{
}

void EXTENSION_APP_ACTIVATE(lua_State *L)
{
}

void EXTENSION_APP_DEACTIVATE(lua_State *L)
{
}

void EXTENSION_FINALIZE(lua_State *L)
{
}

#endif
