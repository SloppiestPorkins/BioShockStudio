class ManualTopic extends Object
	native
	config(Manual)
	perobjectconfig;

var config localized transient string TopicType;
var config localized transient string FriendlyName;
var config travel bool bHidden;
var config localized transient array<localized string> Entry;
var config localized transient array<localized string> EntryPC;

function DumpTopic(float LevelTime, int Level, optional bool bShowHidden, optional bool bShowCompleted)
{
	local int i;
	local string displayString;

	i = 0;
	// End:0x4B
	if(__NFUN_150__(i, Level))
	{
		displayString = __NFUN_112__(displayString, "    ");
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x0B;
		displayString = __NFUN_112__(__NFUN_112__(__NFUN_112__(displayString, FriendlyName), " | Tag: "), string(Name));
	}
	displayString = __NFUN_112__(__NFUN_112__(displayString, " | Type: "), TopicType);
	displayString = __NFUN_112__(__NFUN_112__(displayString, " | Hidden: "), string(bHidden));
	log(,, displayString);
	return;
	@NULL
	Item
	Item
	@NULL
}
