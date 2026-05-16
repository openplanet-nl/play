void PlayMxAsync(ref@ r)
{
	auto params = cast<PlayParams>(r);

	// Make sure we support this game
	if (ManiaExchange::BaseURL() == "") {
		ShowError("Play URLs for ManiaExchange are not supported on this game.");
		return;
	}

	// Make sure this is actually an MX ID
	int id;
	if (!Text::TryParseInt(params.m_id, id)) {
		ShowError("ManiaExchange ID is not a valid number.");
		return;
	}

	// See if we have a secret string
	string secret = params.m_query.Get("secret");

	// Setup map info URL with optional secret
	string infoPath = "/api/maps/?fields=MapType&id=" + id;
	if (secret != "") {
		infoPath += "&secret=" + Net::UrlEncode(secret);
	}

	// Find map type from map info results
	auto req = Net::HttpRequest(ManiaExchange::BaseURL() + infoPath);
	await(req.Start());
	auto jsRes = req.Json();
	if (jsRes.GetType() != Json::Type::Object) {
		ShowError("ManiaExchange API did not respond as expected. (Error 1)");
		return;
	}

	auto jsResults = jsRes.Get("Results");
	if (jsResults is null || jsResults.GetType() != Json::Type::Array) {
		ShowError("ManiaExchange API did not respond as expected. (Error 2)");
		return;
	}

	if (jsResults.Length == 0) {
		ShowError("Map ID " + id + " does not exist on ManiaExchange, or it may be hidden.");
		return;
	}

	auto jsMap = jsResults[0];
	if (jsMap.GetType() != Json::Type::Object) {
		ShowError("ManiaExchange API did not respond as expected. (Error 3)");
		return;
	}

	auto jsMapType = jsMap.Get("MapType");
	if (jsMapType is null || jsMapType.GetType() != Json::Type::String) {
		ShowError("ManiaExchange API did not respond as expected. (Error 4)");
		return;
	}

	// ManiaExchange does not return the *full* type
	string mapType = "TrackMania\\" + string(jsMapType);

	// Setup map download URL with optional secret
	string mapUrl = ManiaExchange::BaseURL() + "/mapgbx/" + id;
	if (secret != "") {
		mapUrl += "?guid=" + Net::UrlEncode(secret);
	}

	Play(mapUrl, mapType);
}

namespace ManiaExchange
{
	string BaseURL()
	{
#if TMNEXT
		return "https://trackmania.exchange";
#elif MP4
		return "https://tm.mania.exchange";
#else
		return "";
#endif
	}
}
