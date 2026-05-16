# Play
This is the `Play` plugin that ships with Openplanet. It's the handler for URIs
such as `trackmania://openplanet/play/PRXOh_5msNrp2Kxz1lv7DPsLL4k`.

## URL specification
`play` URLs always start with `trackmania://openplanet/play/`. This is usually
followed either a map ID, map UID, or an MX ID. A simple heuristic is used to
determine what source the map needs to be loaded from.

You can also explicitly state what source the map must be loaded from, in case
there's any possibility of an ambiguity (which is unlikely, but good to have
just in case). See the list of map sources below for the string to use. It must
be specified before the ID and separated with a `/`.

For example, the following URLs are equivalent and will load from the Nadeo API:

- `trackmania://openplanet/play/PRXOh_5msNrp2Kxz1lv7DPsLL4k`
- `trackmania://openplanet/play/nadeo/PRXOh_5msNrp2Kxz1lv7DPsLL4k`

## Map sources
The following map sources are supported:

- **Nadeo** (`nadeo`): map UIDs (as well as map IDs) that are uploaded to the
  Nadeo API (such as a campaign, room, or map review) can be played with this.
- **ManiaExchange** (`mx`): numeric IDs that are uploaded on Mania Exchange can
  be played with this.

## ManiaExchange secret
You can pass a secret string for ManiaExchange maps as well using the URL query
string. Simply append `?secret=` followed by the secret string for the map.

## Example URLs
The following are some example URLs:
```
trackmania://openplanet/play/PRXOh_5msNrp2Kxz1lv7DPsLL4k
trackmania://openplanet/play/56e30750-83af-449f-922e-7b1db9ffe728
trackmania://openplanet/play/316306
trackmania://openplanet/play/316536?secret=Jf2G0D2pjk2WwnypZCIySg

trackmania://openplanet/play/nadeo/PRXOh_5msNrp2Kxz1lv7DPsLL4k
trackmania://openplanet/play/nadeo/56e30750-83af-449f-922e-7b1db9ffe728
trackmania://openplanet/play/mx/316306
trackmania://openplanet/play/mx/316536?secret=Jf2G0D2pjk2WwnypZCIySg
```
