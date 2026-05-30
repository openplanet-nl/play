#if DEPENDENCY_NADEOSERVICES
void PlayNadeoAsync(ref@ r)
{
	auto params = cast<PlayParams>(r);

	Json::Value@ jsMap;

	if (IsUUID(params.m_id)) {
		// Get map info from Nadeo API through ID
		auto req = NadeoServices::CoreGet("/maps/" + Net::UrlEncode(params.m_id));
		await(req.Start());
		@jsMap = req.Json();
		if (jsMap.GetType() != Json::Type::Object) {
			ShowError("Nadeo API did not respond as expected. (Error 1)");
			return;
		}

	} else {
		// Get map info from Nadeo API through UID
		auto req = NadeoServices::CoreGet("/maps/by-uid/?mapUidList=" + Net::UrlEncode(params.m_id));
		await(req.Start());
		auto js = req.Json();
		if (js.GetType() != Json::Type::Array) {
			ShowError("Nadeo API did not respond as expected. (Error 2)");
			return;
		} else if (js.Length == 0) {
			ShowError("Map UID \"" + params.m_id + "\" does not exist on Nadeo API.");
			return;
		}
		@jsMap = js[0];
		if (jsMap.GetType() != Json::Type::Object) {
			ShowError("Nadeo API did not respond as expected. (Error 3)");
			return;
		}
	}

	// Get the URL to the map file
	auto jsFileUrl = jsMap.Get("fileUrl");
	if (jsFileUrl is null || jsFileUrl.GetType() != Json::Type::String) {
		ShowError("Nadeo API did not respond as expected. (Error 4)");
		return;
	}

	// Get the map type
	auto jsMapType = jsMap.Get("mapType");
	if (jsMapType is null || jsMapType.GetType() != Json::Type::String) {
		ShowError("Nadeo API did not respond as expected. (Error 5)");
		return;
	}

	Play(jsFileUrl, jsMapType);
}

void PlayNadeoRoomAsync(ref@ r)
{
	auto params = cast<PlayParams>(r);
	if (params.m_parts.Length == 0) {
		ShowError("Malformed room URL: missing ID");
		return;
	}

	string clubId = params.m_id;
	if (!IsNumber(clubId)) {
		ShowError("Malformed club ID");
		return;
	}

	string roomId = params.m_parts[0];
	if (!IsNumber(clubId)) {
		ShowError("Malformed room ID");
		return;
	}

	// This can take a while, set up the loading modal for this task
	Loading::Title = "Joining room";
	Loading::Status = "Requesting room join link..";
	Loading::CanCancel = true;
	Loading::ShowScope loading;

	bool starting;
	JoinLink joinLink;

	while (!Loading::CancelRequested) {
		// Get room join link from Nadeo API
		auto req = NadeoServices::LivePost("/api/token/club/" + clubId + "/room/" + roomId + "/join");
		await(req.Start());
		auto js = req.Json();
		if (js.GetType() != Json::Type::Object) {
			ShowError("Nadeo API did not respond as expected. (Error 1)");
			return;
		}

		auto jsStarting = js.Get("starting");
		if (jsStarting is null || jsStarting.GetType() != Json::Type::Boolean) {
			ShowError("Nadeo API did not respond as expected. (Error 2)");
			return;
		}
		starting = jsStarting;

		auto jsJoinLink = js.Get("joinLink");
		if (jsJoinLink is null || jsJoinLink.GetType() != Json::Type::String) {
			ShowError("Nadeo API did not respond as expected. (Error 3)");
			return;
		}
		joinLink = JoinLink::Parse(jsJoinLink);

		// If Nadeo is not starting the server, it should be joinable using the join
		// link right away.
		//
		// If it's still starting but the join link is not empty, the server should
		// exist. Instead of relying on the join endpoint, we'll start querying the
		// server directly instead.
		if (!starting || joinLink.Full != "") {
			break;
		}

		// Otherwise, if we're still waiting for the room to start, wait for a bit
		// and try again.
		//
		// NOTE: Nadeo's menu scripts use 2 seconds for club rooms and 5 seconds for
		//       the TOTD channel. Search "C_Retry_Timer" to find this constant.
		Loading::Status = "Waiting for Nadeo to allocate a server, please wait..";
		trace("Room is still starting. Retrying in 2 seconds..");
		sleep(2000);
	}

	// If the user wanted to cancel, we don't have to continue here
	if (Loading::CancelRequested) {
		return;
	}

	auto app = cast<CGameManiaPlanet>(GetApp());

	// While the server is still starting, query the server directly until ready
	if (starting) {
		// We have to exit the playground first before the game will let us query a
		// server
		ExitPlaygroundAsync();

		// Wait for mania title control script API to be ready
		while (!app.ManiaTitleControlScriptAPI.IsReady && !Loading::CancelRequested) {
			yield();
		}

		// If the user canceled, exit out now
		if (Loading::CancelRequested) {
			return;
		}

		trace("Server is still starting; switching to server querying of \"" + joinLink.ServerLoginOrIp + "\"");
		Loading::Status = "Server is still starting. Querying server, please be patient..";

		while (!Loading::CancelRequested) {
			// Get server info and wait for a result
			app.ManiaTitleControlScriptAPI.GetServerInfo(joinLink.ServerLoginOrIp);
			while (!app.ManiaTitleControlScriptAPI.IsReady && !Loading::CancelRequested) {
				yield();
			}

			// Cancellation may have been requested here so let's return if needed
			if (Loading::CancelRequested) {
				return;
			}

			// If we queried the server successfully, we're done
			if (app.ManiaTitleControlScriptAPI.LatestResult == CGameManiaTitleControlScriptAPI::EResult::Success) {
				trace("Server query was successful");
				break;
			}

			// Server is not yet ready. Wait for a bit and try again.
			//
			// NOTE: Nadeo's menu scripts use 2 seconds for all server status queries,
			//       regardless of server type.
			trace("Server is still starting. Retrying in 2 seconds..");
			sleep(2000);
		}
	}

	// If the user wanted to cancel, we don't have to continue here
	if (Loading::CancelRequested) {
		return;
	}

	// Finally, we can join the server!
	app.ManiaPlanetScriptAPI.OpenLink(joinLink.Full, CGameManiaPlanetScriptAPI::ELinkType::ManialinkBrowser);
}

// Helper functions to create requests on the core API with the necessary
// audience.
//
// NOTE: We should consider having functions like this in the NadeoServices
//       dependency. If you want to copy this function to your plugin, please
//       consider contributing to the NadeoServices plugin as well.
namespace NadeoServices
{
	Net::HttpRequest@ CoreGet(const string &in path)
	{
		string url = NadeoServices::BaseURLCore() + path;
		return NadeoServices::Get("NadeoServices", url);
	}

	Net::HttpRequest@ LivePost(const string &in path, const string &in body = "")
	{
		string url = NadeoServices::BaseURLLive() + path;
		return NadeoServices::Post("NadeoLiveServices", url, body);
	}
}
#endif
