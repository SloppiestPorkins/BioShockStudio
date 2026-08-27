class AudioBeacon extends Actor
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var bool ShowInfo;

function PostBeginPlay()
{
	local string InfoString;

	TriggerEffectEvent('Active',,,,,,,, Label);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBF
	/*@Error*/
	InfoString = "AudioBeacon ";
	// End:0x87
	if(__NFUN_255__(Label, 'None'))
	{
		InfoString = __NFUN_112__(__NFUN_112__(InfoString, "Tag="), string(Label));
		AddDebugMessage(InfoString, -1.0000000, Class'Engine.Canvas'.static.MakeColor(byte(255), 64, 64), true);
	}
	super.PostBeginPlay();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function Destroyed()
{
	UnTriggerEffectEvent('Active', Label);
	super.Destroyed();
	return;
	@NULL
	Item
}

defaultproperties
{
	ShowInfo=true
	DrawType=8
	StaticMesh=StaticMesh'ShockGame.SimpleShapes.Sphere128Radius'
	bInGameRenderable=true
	DrawScale=0.5000000
	bTriggerEffectEventsBeforeGameStarts=true
}