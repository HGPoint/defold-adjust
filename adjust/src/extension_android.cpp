#if defined(DM_PLATFORM_ANDROID)

#include <android/native_window_jni.h>

#include "extension.h"
#include "android/java_lua.h"

static jobject java_extension_object = NULL;
static jmethodID java_extension_update = NULL;
static jmethodID java_extension_app_activate = NULL;
static jmethodID java_extension_app_deactivate = NULL;
static jmethodID java_extension_finalize = NULL;
static jmethodID java_extension_init = NULL;
static jmethodID java_extension_track_event = NULL;
static jmethodID java_extension_set_session_parameters = NULL;
static jmethodID java_extension_enable = NULL;
static jmethodID java_extension_disable = NULL;
static jmethodID java_extension_set_pushtoken = NULL;
static jmethodID java_extension_switch_to_offline_mode = NULL;
static jmethodID java_extension_switch_back_to_online_mode = NULL;
static jmethodID java_extension_process_deeplink = NULL;
static jmethodID java_extension_gdpr_forget_me = NULL;
static jmethodID java_extension_get_attribution = NULL;
static jmethodID java_extension_get_adid = NULL;
static jmethodID java_extension_get_amazon_ad_id = NULL;
static jmethodID java_extension_get_google_ad_id = NULL;
static jmethodID java_extension_get_sdk_version = NULL;

int EXTENSION_INIT(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_init, (jlong)L);
	}
	return result;
}

int EXTENSION_TRACK_EVENT(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_track_event, (jlong)L);
	}
	return result;
}

int EXTENSION_SET_SESSION_PARAMETERS(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_set_session_parameters, (jlong)L);
	}
	return result;
}

int EXTENSION_ENABLE(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_enable, (jlong)L);
	}
	return result;
}

int EXTENSION_DISABLE(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_disable, (jlong)L);
	}
	return result;
}

int EXTENSION_SET_PUSHTOKEN(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_set_pushtoken, (jlong)L);
	}
	return result;
}

int EXTENSION_SWITCH_TO_OFFLINE_MODE(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_switch_to_offline_mode, (jlong)L);
	}
	return result;
}

int EXTENSION_SWITCH_BACK_TO_ONLINE_MODE(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_switch_back_to_online_mode, (jlong)L);
	}
	return result;
}

int EXTENSION_PROCESS_DEEPLINK(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_process_deeplink, (jlong)L);
	}
	return result;
}

int EXTENSION_GDPR_FORGET_ME(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_gdpr_forget_me, (jlong)L);
	}
	return result;
}

int EXTENSION_GET_ATTRIBUTION(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_get_attribution, (jlong)L);
	}
	return result;
}

int EXTENSION_GET_ADID(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_get_adid, (jlong)L);
	}
	return result;
}

int EXTENSION_GET_AMAZON_AD_ID(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_get_amazon_ad_id, (jlong)L);
	}
	return result;
}

int EXTENSION_GET_GOOGLE_AD_ID(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_get_google_ad_id, (jlong)L);
	}
	return result;
}

int EXTENSION_GET_SDK_VERSION(lua_State *L)
{
	int result = 0;
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_get_sdk_version, (jlong)L);
	}
	return result;
}

void EXTENSION_INITIALIZE(lua_State *L)
{
	// Mention java_lua.h exports so they don't get optimized away.
	if (L == NULL)
	{
		JAVA_LUA_REGISTRYINDEX(NULL, NULL, 0);
		JAVA_LUA_GETTOP(NULL, NULL, 0);
	}
	ThreadAttacher attacher;
	JNIEnv *env = attacher.env;
	ClassLoader class_loader = ClassLoader(env);

	// Invoke Extension from the Java extension.
	jclass java_extension_class = class_loader.load("extension/" EXTENSION_NAME_STRING "/Extension");
	if (java_extension_class == NULL)
	{
		dmLogError("java_extension_class is NULL");
	}
	jmethodID screen_recorder_constructor = env->GetMethodID(java_extension_class, "<init>", "(Landroid/app/Activity;)V");
	java_extension_init = env->GetMethodID(java_extension_class, "init", "(J)I");
	java_extension_track_event = env->GetMethodID(java_extension_class, "track_event", "(J)I");
	java_extension_set_session_parameters = env->GetMethodID(java_extension_class, "set_session_parameters", "(J)I");
	java_extension_enable = env->GetMethodID(java_extension_class, "enable", "(J)I");
	java_extension_disable = env->GetMethodID(java_extension_class, "disable", "(J)I");
	java_extension_set_pushtoken = env->GetMethodID(java_extension_class, "set_pushtoken", "(J)I");
	java_extension_switch_to_offline_mode = env->GetMethodID(java_extension_class, "switch_to_offline_mode", "(J)I");
	java_extension_switch_back_to_online_mode = env->GetMethodID(java_extension_class, "switch_back_to_online_mode", "(J)I");
	java_extension_process_deeplink = env->GetMethodID(java_extension_class, "process_deeplink", "(J)I");
	java_extension_gdpr_forget_me = env->GetMethodID(java_extension_class, "gdpr_forget_me", "(J)I");
	java_extension_get_attribution = env->GetMethodID(java_extension_class, "get_attribution", "(J)I");
	java_extension_get_adid = env->GetMethodID(java_extension_class, "get_adid", "(J)I");
	java_extension_get_amazon_ad_id = env->GetMethodID(java_extension_class, "get_amazon_ad_id", "(J)I");
	java_extension_get_google_ad_id = env->GetMethodID(java_extension_class, "get_google_ad_id", "(J)I");
	java_extension_get_sdk_version = env->GetMethodID(java_extension_class, "get_sdk_version", "(J)I");
	java_extension_finalize = env->GetMethodID(java_extension_class, "extension_finalize", "(J)V");
	java_extension_update = env->GetMethodID(java_extension_class, "update", "(J)V");
	java_extension_app_activate = env->GetMethodID(java_extension_class, "app_activate", "(J)V");
	java_extension_app_deactivate = env->GetMethodID(java_extension_class, "app_deactivate", "(J)V");
	java_extension_object = (jobject)env->NewGlobalRef(env->NewObject(java_extension_class, screen_recorder_constructor, dmGraphics::GetNativeAndroidActivity()));
	if (java_extension_object == NULL)
	{
		dmLogError("java_extension_object is NULL");
	}
}

void EXTENSION_UPDATE(lua_State *L)
{
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		// Update the Java side so it can invoke any pending listeners.
		attacher.env->CallVoidMethod(java_extension_object, java_extension_update, (jlong)L);
	}
}

void EXTENSION_APP_ACTIVATE(lua_State *L)
{
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		attacher.env->CallVoidMethod(java_extension_object, java_extension_app_activate, (jlong)L);
	}
}

void EXTENSION_APP_DEACTIVATE(lua_State *L)
{
	if (java_extension_object != NULL)
	{
		ThreadAttacher attacher;
		attacher.env->CallVoidMethod(java_extension_object, java_extension_app_deactivate, (jlong)L);
	}
}

void EXTENSION_FINALIZE(lua_State *L)
{
	ThreadAttacher attacher;
	if (java_extension_object != NULL)
	{
		attacher.env->CallVoidMethod(java_extension_object, java_extension_finalize, (jlong)L);
		attacher.env->DeleteGlobalRef(java_extension_object);
	}
	java_extension_object = NULL;
}

#endif
