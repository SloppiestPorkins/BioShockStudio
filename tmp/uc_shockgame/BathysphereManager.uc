class BathysphereManager extends Object
	native
	config(Bathysphere)
	perobjectconfig;

struct native atomic BathysphereEntry
{
	var localized string Title;
	var name MapName;
	var name StartLocationLabel;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var config localized array<localized BathysphereEntry> Destinations;
var travel array<int> UnlockedDestinations;

function UnlockDestination(name MapName)
{
	local int i, InsertIndex;

	i = 0;
	// End:0x10E
	if(__NFUN_150__(i, Destinations.Length))
	{
		// End:0x100
		if(__NFUN_254__(MapName, Destinations[i].MapName))
		{
			InsertIndex = 0;
			// End:0xCD
			if(__NFUN_150__(InsertIndex, UnlockedDestinations.Length))
			{
				// End:0x9B
				if(__NFUN_154__(UnlockedDestinations[InsertIndex], i))
				{
					return;
					// End:0xBF
					if(__NFUN_151__(UnlockedDestinations[InsertIndex], i))
					{
						goto J0xCD;
						__NFUN_163__(InsertIndex);
						// [Loop Continue]
						goto J0x60;
						UnlockedDestinations.Insert(InsertIndex, 1);
						UnlockedDestinations[InsertIndex] = i;
					}
					return;
					__NFUN_163__(i);
					// [Loop Continue]
					goto J0x0B;
					AssertWithDescription(false, __NFUN_112__(__NFUN_112__(string(MapName), " was passed as a bathysphere destinations, but doesn't exist in "), string(Name)));
				}
			}
		}
		return;
		@NULL
	}
	Item
	Item
	@NULL
}
