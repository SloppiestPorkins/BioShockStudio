class LinkConfiguration extends ReferenceCountedObject
	native
	config(Plasmids)
	perobjectconfig;

struct native atomic Link
{
	var config Plasmid.ePlasmidTrack TrackA;
	var config int SlotA;
	var config Plasmid.ePlasmidTrack TrackB;
	var config int SlotB;
	var config Plasmid.ePlasmidTrack TrackC;
	var config int SlotC;
};

var config array<Link> Links;

function DumpConfiguration()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x19B
	/*@Error*/
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("   [", string(GetEnum(Enum'ShockGame.Plasmid.ePlasmidTrack', int(Links[i].TrackA)))), ":"), string(Links[i].SlotA)), "] ----- ["), string(GetEnum(Enum'ShockGame.Plasmid.ePlasmidTrack', int(Links[i].TrackB)))), ":"), string(Links[i].SlotB)), "] ----- ["), string(GetEnum(Enum'ShockGame.Plasmid.ePlasmidTrack', int(Links[i].TrackC)))), ":"), string(Links[i].SlotC)), "]"));
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}
