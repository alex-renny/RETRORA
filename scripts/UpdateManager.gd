extends Node

# UpdateManager checks GitHub Releases for new RETRORA versions.

signal update_available(version_tag: String, apk_url: String, release_notes: String)
signal update_check_completed(has_update: bool)

const CURRENT_VERSION: String = "v1.2.0"
const GITHUB_REPO: String = "alex-renny/RETRORA"

var has_checked: bool = false
var is_update_available: bool = false
var latest_version: String = ""
var download_url: String = ""
var release_notes: String = ""

var is_checking: bool = false

func _ready():
	# Automatically check for updates on game startup
	check_for_updates()

func check_for_updates():
	if is_checking:
		return
	is_checking = true
	var http = HTTPRequest.new()
	http.timeout = 8.0 # 8s timeout for mobile data
	add_child(http)
	http.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		is_checking = false
		_on_request_completed(result, response_code, body)
		http.queue_free()
	)

	var url = "https://api.github.com/repos/%s/releases/latest" % GITHUB_REPO
	var headers = ["User-Agent: RETRORA-Godot-App", "Accept: application/vnd.github.v3+json"]
	var err = http.request(url, headers)
	if err != OK:
		is_checking = false
		has_checked = true
		update_check_completed.emit(false)

func _on_request_completed(result: int, response_code: int, body: PackedByteArray):
	has_checked = true
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		# Offline or no releases yet
		update_check_completed.emit(false)
		return

	var json_str = body.get_string_from_utf8()
	var data = JSON.parse_string(json_str)
	if typeof(data) != TYPE_DICTIONARY:
		update_check_completed.emit(false)
		return

	var tag = data.get("tag_name", "")
	var assets = data.get("assets", [])
	var apk_url = ""

	for asset in assets:
		if typeof(asset) == TYPE_DICTIONARY:
			var asset_name: String = asset.get("name", "")
			if asset_name.ends_with(".apk"):
				apk_url = asset.get("browser_download_url", "")
				break

	if apk_url == "":
		apk_url = data.get("html_url", "https://github.com/%s/releases" % GITHUB_REPO)

	if tag != "" and _is_newer(tag, CURRENT_VERSION):
		is_update_available = true
		latest_version = tag
		download_url = apk_url
		release_notes = data.get("body", "")
		update_available.emit(latest_version, download_url, release_notes)
		update_check_completed.emit(true)
	else:
		is_update_available = false
		update_check_completed.emit(false)

func _is_newer(remote_tag: String, current_tag: String) -> bool:
	var r_clean = remote_tag.trim_prefix("v").strip_edges()
	var c_clean = current_tag.trim_prefix("v").strip_edges()

	var r_parts = r_clean.split(".")
	var c_parts = c_clean.split(".")

	var max_len = max(r_parts.size(), c_parts.size())
	for i in range(max_len):
		var r_num = int(r_parts[i]) if i < r_parts.size() else 0
		var c_num = int(c_parts[i]) if i < c_parts.size() else 0
		if r_num > c_num:
			return true
		elif r_num < c_num:
			return false

	return false

func open_download_page():
	var target = download_url
	if target == "":
		target = "https://github.com/%s/releases" % GITHUB_REPO
	OS.shell_open(target)
