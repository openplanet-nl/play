// Play parameters sent to play functions that need it. Contains the requested
// map ID and the query parameters specified in the URL.
class PlayParams
{
	string m_id;
	QueryMap m_query;
}

void Main()
{
#if DEPENDENCY_NADEOSERVICES
	NadeoServices::AddAudience("NadeoServices");
#endif
}

// Returns true if the given string looks like a valid UUID.
bool IsUUID(const string &in str)
{
	return Regex::IsMatch(str, "^[A-Fa-f0-9]{8}-([A-Fa-f0-9]{4}-){3}[A-Fa-f0-9]{12}$");
}

// Returns true if the given string looks like a valid map UID.
//
// NOTE: This check is pretty simple and should be considered a heuristic rather
//       than a concrete result. The minimum and maximum length is based on the
//       request validation done by the Nadeo API.
bool IsUID(const string &in str)
{
	return Regex::IsMatch(str, "^[A-Za-z0-9_]{25,27}$");
}

// Returns true if the given string looks like a number.
bool IsNumber(const string &in str)
{
	return Regex::IsMatch(str, "^[0-9]+$");
}

// Helper function to print an error to log and show a UI notification with an
// error style. Should match Openplanet's own error notification styling.
//
// NOTE: We should consider moving this function to the Controls plugin so that
//       the same consistent style can be re-used by every plugin without having
//       to copy the same code everywhere. If you want to copy this function to
//       your plugin, please consider contributing to the Controls dependency
//       as well.
void ShowError(const string &in message)
{
	error("Unable to play map: " + message);
	UI::ShowNotification("\\$f33" + Icons::TimesCircle + "\\$z Unable to play map", message, vec4(0.27f, 0, 0, 1));
}

void OnProtocolUrl(const string &in path)
{
#if TMNEXT
	if (!Permissions::PlayLocalMap()) {
		ShowError("You need a Club subscription to play arbitrary maps.");
		return;
	}
#endif

	PlayParams params;
	array<string> parts;

	int queryIndex = path.IndexOf("?");
	if (queryIndex != -1) {
		params.m_query = Net::ParseUrlEncodedForm(path.SubStr(queryIndex + 1));
		parts = path.SubStr(0, queryIndex).Split("/");
	} else {
		parts = path.Split("/");
	}

	if (parts.Length == 1) {
		params.m_id = parts[0];
		PlayImplicit(params);
	} else if (parts.Length == 2) {
		params.m_id = parts[1];
		PlayExplicit(parts[0], params);
	} else {
		error("Unexpected number of URL parts (" + parts.Length + ")");
	}
}

// Play the given map using a heuristic on the ID parameter to determine the
// source of the map.
void PlayImplicit(const PlayParams &in params)
{
#if DEPENDENCY_NADEOSERVICES
	// If this is a UUID or regular ID, we can assume it can be sourced from the
	// Nadeo API
	if (Setting_MapSource_Nadeo && (IsUID(params.m_id) || IsUUID(params.m_id))) {
		PlayExplicit("nadeo", params);
		return;
	}
#endif

	// If this is a number, we can assume it's probably a ManiaExchange ID
	if (Setting_MapSource_Mx && IsNumber(params.m_id)) {
		PlayExplicit("mx", params);
		return;
	}

	// Anything else is unknown and should throw an error
	ShowError("Unknown implicit map source for ID \"" + params.m_id + "\"");
}

// Play the given map from an explicit source and parameters.
void PlayExplicit(const string &in source, const PlayParams &in params)
{
#if DEPENDENCY_NADEOSERVICES
	if (Setting_MapSource_Nadeo && source == "nadeo") {
		startnew(PlayNadeoAsync, params);
		return;
	}
#endif

	if (Setting_MapSource_Mx && source == "mx") {
		startnew(PlayMxAsync, params);
		return;
	}

	ShowError("Unknown explicit map source \"" + source + "\"");
}

// Play a map directly from the given URL and map type.
void Play(const string &in url, const string &in mapType)
{
	// NOTE: If you would like to copy this function to your plugin, please add a
	//       permissions check using Permissions::PlayLocalMap. This is already
	//       done in this plugin before this function is called, so it's commented
	//       out here.
	// if (!Permissions::PlayLocalMap()) {
	// 	error("No permissions");
	// 	return;
	// }

	auto app = cast<CGameManiaPlanet>(GetApp());

	// If an in-game menu is displayed, we'll need to close it to avoid locking up
	// when calling BackToMainMenu
	if (app.ManiaPlanetScriptAPI.ActiveContext_InGameMenuDisplayed) {
		app.CurrentPlayground.Interface.ManialinkScriptHandler.CloseInGameMenu(
			CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Resume);
	}

	// Exit playground to get ready to load another map, and wait to make sure it
	// has been exited
	app.BackToMainMenu();
	while (app.CurrentPlayground !is null) {
		yield();
	}

	// Get the gamemode path for the map type
	auto modePath = GetModePathForMapType(mapType);

	// Play the map with the mode
	app.ManiaTitleControlScriptAPI.PlayMap(url, modePath, "");
}

// Returns the gamemode to pass to PlayMap() for the given map type. The map
// type is expected to be in a format like "TrackMania\TM_Race".
string GetModePathForMapType(const string &in mapType)
{
#if TMNEXT
	if (mapType == "TrackMania\\TM_Race") { return "TrackMania/TM_PlayMap_Local"; }
	if (mapType == "TrackMania\\TM_Royal") { return "TrackMania/TM_RoyalTimeAttack_Local"; }
	if (mapType == "TrackMania\\TM_Stunt") { return "TrackMania/TM_StuntSolo_Local"; }
	if (mapType == "TrackMania\\TM_Platform") { return "TrackMania/TM_Platform_Local"; }

	error("Unknown mode path for map type \"" + mapType + "\"");
	return "";

#elif MP4
	// We're pretty much only ever going to need CampaignSolo, unless we're in
	// ShootMania. We should improve this when adding ShootMania support.
	return "Modes/TrackMania/CampaignSolo";
#endif
}
