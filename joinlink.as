// NOTE: The monstrous regex in this file is borrowed directly from the game's
//       deprecated (but actively used) Tools library. Search "C_RegexJoinLink"
//       to find this constant. See also "ParseJoinLink()" in that same library.
//
// NOTE: Some examples of join links from the Maniaplanet documentation:
//         #xxx=serverlogin@TITLEID
//         #xxx=serverlogin:serverpassword@TITLEID
//         #xxx=192.168.xx.xx::port@TITLEID
//         #xxx=192.168.xx.xx:serverpassword:port@TITLEID
class JoinLink
{
	string Full;

	string Type;
	string LoginOrIp;
	string Password;
	string Port;
	string Title;

	string ToString() const
	{
		string ret = "#" + Type + "=" + LoginOrIp;
		if (Password != "" || Port != "") {
			ret += ":" + Password;
		}
		if (Port != "") {
			ret += ":" + Port;
		}
		if (Title != "") {
			ret += "@" + Title;
		}
		return ret;
	}
}

namespace JoinLink
{
	JoinLink Parse(const string &in str)
	{
		JoinLink ret;
		auto matches = Regex::Match(str, """#(\S+)=([^:@\s]+)(?::([^:@\s]+)?(?::([^:@\s]+))?)?(?:@(\S+))?""");
		if (matches.Length >= 6) {
			ret.Full = matches[0];
			ret.Type = matches[1];
			ret.LoginOrIp = matches[2];
			ret.Password = matches[3];
			ret.Port = matches[4];
			ret.Title = matches[5];
		}
		return ret;
	}
}
