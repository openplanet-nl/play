// Helper class for array<Net::FormPair> to make our code a little bit more
// readable.
//
// NOTE: If you would like to copy this helper class to your plugin, please
//       consider if you really need it or if you can just walk through the
//       array.
//
// NOTE: This is not a very efficient way to query data parsed with the
//       Net::ParseUrlEncodedForm API. This helper ignores duplicate names
//       entirely (returning the first encountered value), and has a very
//       limited feature set. Furthermore, name lookups can be quite slow if
//       there are a lot of pairs.
class QueryMap
{
	private array<Net::FormPair> m_pairs;

	void opAssign(const array<Net::FormPair> &in pairs)
	{
		m_pairs = pairs;
	}

	string Get(const string &in name) const
	{
		for (uint i = 0; i < m_pairs.Length; i++) {
			if (m_pairs[i].Name == name) {
				return m_pairs[i].Value;
			}
		}
		return "";
	}
}
