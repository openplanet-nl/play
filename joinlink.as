// NOTE: The monstrous regex in this file is borrowed directly from the game's
//       deprecated (but actively used) Tools library. Search "C_RegexJoinLink"
//       to find this constant. See also "ParseJoinLink()" in that same library.
class JoinLink
{
	string Full;
	string Type;
	string ServerLoginOrIp;
	string Password;
	string Port;
	string Title;
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
			ret.ServerLoginOrIp = matches[2];
			ret.Password = matches[3];
			ret.Port = matches[4];
			ret.Title = matches[5];
		}
		return ret;
	}
}
