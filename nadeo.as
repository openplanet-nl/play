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

namespace NadeoServices
{
	// Helper function to create a request on the core API with the necessary
	// audience.
	//
	// NOTE: We should consider having functions like this in the NadeoServices
	//       dependency. If you want to copy this function to your plugin, please
	//       consider contributing to the NadeoServices plugin as well.
	Net::HttpRequest@ CoreGet(const string &in path)
	{
		string url = NadeoServices::BaseURLCore() + path;
		return NadeoServices::Get("NadeoServices", url);
	}
}
#endif
