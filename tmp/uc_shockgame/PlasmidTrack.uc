class PlasmidTrack extends Object
	native;

const MAX_SLOTS_PER_TRACK = 6;

var private travel int UnlockedSlots;
var private travel name Plasmids[6];
var private travel bool NewPlasmidAvailable;

function DumpTrack()
{
	local string contents;
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x98
	/*@Error*/
	// End:0x6A
	if(__NFUN_150__(i, UnlockedSlots))
	{
		contents = __NFUN_112__(__NFUN_112__(__NFUN_112__(contents, "["), string(Plasmids[i])), "] ");
		goto J0x8A;
		contents = __NFUN_112__(contents, "[LOCKED] ");
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x0B;
	}
	log(,, contents);
	return;
	@NULL
	Item
	Item
	@NULL
}
