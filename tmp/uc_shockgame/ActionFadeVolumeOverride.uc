class ActionFadeVolumeOverride extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel float Volume;
var travel float Duration;

function Variable latentExecute()
{
	local PlayerController PlayerController;
	local float Alpha, StartTime, diff, startVolume;

	resolveParameters();
	PlayerController = parentScript.Level.GetLocalPlayerController();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1A3
	/*@Error*/
	startVolume = float(PlayerController.ConsoleCommand("GETVOLUMEOVERRIDE"));
	diff = __NFUN_175__(Volume, startVolume);
	StartTime = parentScript.Level.TimeSeconds;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1A3
	/*@Error*/
	Alpha = __NFUN_172__(__NFUN_175__(parentScript.Level.TimeSeconds, StartTime), Duration);
	PlayerController.ConsoleCommand(__NFUN_112__("SETVOLUMEOVERRIDE ", string(__NFUN_174__(startVolume, __NFUN_171__(diff, Alpha)))));
	__NFUN_256__(0.0000000);
	// [Loop Continue]
	goto J0xCA;
	PlayerController.ConsoleCommand(__NFUN_112__("SETVOLUMEOVERRIDE ", string(Volume)));
	return none;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function Variable execute()
{
	super.execute();
	parentScript.Level.GetLocalPlayerController().ConsoleCommand(__NFUN_112__("SETVOLUMEOVERRIDE ", string(Volume)));
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Fade the volume override to '", string(Volume)), "' over '"), string(Duration)), "' seconds.");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Fade Volume Override."
	actionHelp="Fade the Volume Override."
	Category="AudioVisual"
}