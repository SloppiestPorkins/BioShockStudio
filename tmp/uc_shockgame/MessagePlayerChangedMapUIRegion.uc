class MessagePlayerChangedMapUIRegion extends Message
	editinlinenew
	hidecategories(Object);

var name OldHUDRegion;
var name NewHUDRegion;
var string DescriptionOfNewHUDRegion;
var float TimeSinceNewHUDRegionLastEntered;
var(MapUIRegion) name OldMapUIRegion;
var(MapUIRegion) name NewMapUIRegion;
var(MapUIRegion) float TimeSinceNewMapUIRegionLastEntered;

function Construct(LevelInfo LevelInfo, name inOldMapUIRegion, name inNewMapUIRegion)
{
	local int IndexOldMapUIRegion, IndexNewMapUIRegion;
	local float TimeLastVisitedHUDRegion;

	OldMapUIRegion = 'UNKNOWN_OR_INVALID';
	OldHUDRegion = 'UNKNOWN_OR_INVALID';
	NewMapUIRegion = 'UNKNOWN_OR_INVALID';
	NewHUDRegion = 'UNKNOWN_OR_INVALID';
	TimeSinceNewMapUIRegionLastEntered = __NFUN_169__(float(2147483647));
	TimeSinceNewHUDRegionLastEntered = __NFUN_169__(float(2147483647));
	DescriptionOfNewHUDRegion = "";
	IndexOldMapUIRegion = GetIndexOfMapUIRegion(LevelInfo, inOldMapUIRegion);
	// End:0x11B
	if(__NFUN_153__(IndexOldMapUIRegion, 0))
	{
		OldMapUIRegion = inOldMapUIRegion;
		OldHUDRegion = LevelInfo.MapUIRegions[IndexOldMapUIRegion].HUDRegion;
		// End:0x11B
		if(__NFUN_255__(OldHUDRegion, 'None'))
		{
			goto J0x11B;
			IndexNewMapUIRegion = GetIndexOfMapUIRegion(LevelInfo, inNewMapUIRegion);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2D6
			/*@Error*/
			NewMapUIRegion = inNewMapUIRegion;
			// End:0x1F2
			if(__NFUN_177__(LevelInfo.MapUIRegions[IndexNewMapUIRegion].TimeLastVisited, float(0)))
			{
			}
		}
		TimeSinceNewMapUIRegionLastEntered = __NFUN_175__(LevelInfo.TimeSeconds, LevelInfo.MapUIRegions[IndexNewMapUIRegion].TimeLastVisited);
		goto J0x203;
		TimeSinceNewMapUIRegionLastEntered = float(2147483647);
		NewHUDRegion = LevelInfo.MapUIRegions[IndexNewMapUIRegion].HUDRegion;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2D6
		/*@Error*/
		GetTimeLastVisitedHUDRegion(LevelInfo, NewHUDRegion, TimeLastVisitedHUDRegion, DescriptionOfNewHUDRegion);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2C2
		/*@Error*/
		TimeSinceNewHUDRegionLastEntered = __NFUN_175__(LevelInfo.TimeSeconds, TimeLastVisitedHUDRegion);
		goto J0x2D3;
		TimeSinceNewHUDRegionLastEntered = float(2147483647);		
	}
	else
	{
		return;
		@NULL
		Item
		Vector
		J0x203:

		@NULL
	}
}

function GetTimeLastVisitedHUDRegion(LevelInfo LevelInfo, name inHUDRegion, out float TimeMostRecentVisit, out string DescriptionOfHUDRegion)
{
	local int i;

	TimeMostRecentVisit = 0.0000000;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1DA
	/*@Error*/
	i = 0;
	// End:0x11F
	if(__NFUN_150__(i, LevelInfo.MapUIRegions.Length))
	{
		// End:0x111
		if(__NFUN_130__(__NFUN_254__(LevelInfo.MapUIRegions[i].HUDRegion, inHUDRegion), __NFUN_177__(LevelInfo.MapUIRegions[i].TimeLastVisited, TimeMostRecentVisit)))
		{
			TimeMostRecentVisit = LevelInfo.MapUIRegions[i].TimeLastVisited;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x31;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1DA
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1CC
			/*@Error*/
			DescriptionOfHUDRegion = LevelInfo.MapHUDRegions[i].Description;
		}
	}
	goto J0x1DA;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x12A;
	return;
	@NULL
	Item
	Item
	@NULL
}

function int GetIndexOfMapUIRegion(LevelInfo LevelInfo, name inMapUIRegion)
{
	local int i;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x9E
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9E
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x90
	/*@Error*/
	return i;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x22;
	return -1;
	return;
	@NULL
	Item
	Class'ShockGame.Item'
	@NULL
}

static function string editorDisplay(name Instigator, Message filter)
{
	return "The player changed Map UI regions";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPlayer'
}