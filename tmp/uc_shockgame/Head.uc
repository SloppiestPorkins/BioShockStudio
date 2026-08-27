class Head extends Actor
	native
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var travel array<name> PersistentEffectsSystemContexts;

function UpdateLocationAndRotation()
{
	local Vector CameraLocation;
	local Rotator CameraRotation;

	CameraLocation = Level.GetLocalPlayerController().Pawn.Location;
	Level.GetLocalPlayerController().CalcFirstPersonView(CameraLocation, CameraRotation);
	__NFUN_267__(CameraLocation);
	__NFUN_299__(CameraRotation);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function AddPersistentEffectsSystemContext(name Context)
{
	local int i;

	i = 0;
	// End:0x54
	if(__NFUN_150__(i, PersistentEffectsSystemContexts.Length))
	{
		// End:0x46
		if(__NFUN_254__(PersistentEffectsSystemContexts[i], Context))
		{
			return;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			PersistentEffectsSystemContexts[PersistentEffectsSystemContexts.Length] = Context;
		}
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function RemovePersistentEffectsSystemContext(name Context)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x68
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5A
	/*@Error*/
	PersistentEffectsSystemContexts.Remove(i, 1);
	return;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	DrawType=0
	bInGameRenderable=true
	DrawPriority=1
}