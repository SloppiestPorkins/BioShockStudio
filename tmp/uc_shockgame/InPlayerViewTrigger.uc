class InPlayerViewTrigger extends Actor
	native
	config
	placeable
	hidecategories(DrawScale3D,DisplayAdvanced);

var(PlayerViewTrigger) float MinimumDistance;
var(PlayerViewTrigger) float ViewBoundsPercentage;
var(PlayerViewTrigger) float ViewTime;
var(PlayerViewTrigger) float UpdatePeriod;
var(PlayerViewTrigger) bool TriggerWhenNotSeen;
var(PlayerViewTrigger) bool enabled;

// Export UInPlayerViewTrigger::execPlayerCanSeeUs(FFrame&, void* const)
native function bool PlayerCanSeeUs();

function TriggerMessage()
{
	dispatchMessage(Class'Scripting.MessageTrigger'.static.Allocate(self)., construct_NameName(Label, Level.GetLocalPlayerController().Pawn.Label));
	return;
	@NULL
	Item
	Item
	@NULL
}

function WatchForTrigger()
{
	local float StartingTimeSeen;

	StartingTimeSeen = Level.TimeSeconds;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE6
	/*@Error*/
	// End:0x96
	if(__NFUN_130__(enabled, __NFUN_242__(PlayerCanSeeUs(), __NFUN_129__(TriggerWhenNotSeen))))
	{
		// End:0x93
		if(__NFUN_178__(__NFUN_174__(StartingTimeSeen, ViewTime), Level.TimeSeconds))
		{
			TriggerMessage();
			enabled = false;
			goto J0xC1;
			StartingTimeSeen = __NFUN_174__(Level.TimeSeconds, UpdatePeriod);
			__NFUN_256__(__NFUN_174__(UpdatePeriod, RandRange(0.0000000, 0.0500000)));
		}
	}
	// [Loop Continue]
	goto J0x20;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

auto state Startup
{Begin:

	WatchForTrigger();
	stop;	
}

defaultproperties
{
	MinimumDistance=2000.0000000
	ViewBoundsPercentage=0.8000000
	UpdatePeriod=0.3000000
	enabled=true
	Texture=Texture'ShockGame.Engine_res.S_Camera'
	DrawScale=1.5000000
}