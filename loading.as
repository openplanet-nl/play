// TODO: We should consider moving this entire thing to the Controls plugin, so
//       it can be re-used in other places as well. This also needs a much nicer
//       API in general. The ShowScope class is fun for async tasks, but the way
//       we assign properties and check for cancellation is a bit finicky.
//
// NOTE: If you would like to re-use this code, please wait for it to land in
//       the Controls plugin instead, or help us out with a contribution.
namespace Loading
{
	string Title = "";
	string Status = "";
	bool CanCancel = false;
	bool CancelRequested = false;

	void Show()
	{
		ShowRequested = true;
		CloseRequested = false;
		CancelRequested = false;
	}
	void Close() { CloseRequested = true; }

	bool ShowRequested = false;
	bool CloseRequested = false;

	void Render()
	{
		if (ShowRequested) {
			UI::OpenPopup("Loading");
			ShowRequested = false;
		}

		UI::SetNextWindowSize(500, 90);
		UI::SetNextWindowPos(
			int(Display::GetWidth() / 2.0f / UI::GetScale()),
			int(Display::GetHeight() / 2.0f / UI::GetScale()),
			UI::Cond::Appearing,
			0.5f, 0.5f
		);
		if (UI::BeginPopupModal("\\$666" + Icons::HourglassO + "\\$z " + Title + "###Loading", UI::GetDefaultWindowFlags() | UI::WindowFlags::NoResize)) {
			UI::Text(Status);
			if (CanCancel && !CancelRequested && UI::Button("Cancel")) {
				CancelRequested = true;
			}
			if (CloseRequested) {
				UI::CloseCurrentPopup();
				CloseRequested = false;
			}
			UI::EndPopup();
		}
	}

	class ShowScope
	{
		ShowScope() { Loading::Show(); }
		~ShowScope() { Loading::Close(); }
	}
}

void Render()
{
	Loading::Render();
}
