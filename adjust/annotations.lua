---@meta

---@class adjust.config
---@field app_token string
---@field is_sandbox? boolean
---@field app_secret? table
---@field default_tracker? string
---@field log_level? string
---@field process_name? string
---@field sdk_prefix? string
---@field fb_app_id? string
---@field preinstall_tracking? boolean
---@field coppa_compliance? boolean
---@field play_store_kids_compliance? boolean
---@field event_deduplication_ids_max_size? number
---@field external_device_id? string
---@field listener? function

---@class adjust.event
---@field token string
---@field revenue? number
---@field currency? string
---@field transaction_id? string
---@field callback_id? string
---@field callback_parameters? string[]
---@field partner_parameters? string[]

---@class adjust.ad_revenue
---@field source string
---@field revenue? number
---@field currency? string
---@field impressions_count? number
---@field network? string
---@field unit? string
---@field placement? string
---@field callback_parameters? string[]
---@field partner_parameters? string[]

---@class adjust.session_parameters
---@field callback_parameters? string[]
---@field partner_parameters? string[]

---@class adjust.attribution
---@field adgroup string
---@field campaign string
---@field click_label string
---@field creative string
---@field network string
---@field tracker_name string
---@field tracker_token string

---@class adjust
adjust = {}

---@param cfg adjust.config
function adjust.init(cfg) end

---@param event adjust.event
function adjust.track_event(event) end

---@param event adjust.ad_revenue
function adjust.track_ad_revenue(event) end

---@param parameters adjust.session_parameters
function adjust.set_session_parameters(parameters) end

function adjust.enable() end

function adjust.disable() end

---@param token string
function adjust.set_pushtoken(token) end

function adjust.switch_to_offline_mode() end

function adjust.switch_back_to_online_mode() end

---@param url string
function adjust.process_deeplink(url) end

function adjust.gdpr_forget_me() end

---@param callback fun(attribution: adjust.attribution)
function adjust.get_attribution(callback) end

---@param callback fun(adid: string)
function adjust.get_adid(callback) end

---@param callback fun(amazon_ad_id: string)
function adjust.get_amazon_ad_id(callback) end

---@param callback fun(google_ad_id: string)
function adjust.get_google_ad_id(callback) end

---@param callback fun(sdk_version: string)
function adjust.get_sdk_version(callback) end
