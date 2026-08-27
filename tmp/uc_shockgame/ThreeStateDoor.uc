class ThreeStateDoor extends ShockDoor
	abstract
	config(ShockGame)
	hidecategories(DrawScale3D,DisplayAdvanced,Lighting,LightColor,Force);

var(Door) private const name AlternateOpenAnimationName;
var(Door) private const name AlternateCloseAnimationName;
var(Door) private const float AlternateOpenAnimationRate;
var(Door) private const float AlternateCloseAnimationRate;
var private bool bIsAlternateMoving;
var private bool bIsAlternateOpen;
var private name OriginalState;

function OpenAlternateDoor()
{
	local int Handle;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xA3
	/*@Error*/
	bIsAlternateOpen = true;
	TriggerEffectEvent('SmallDoorOpened');
	Handle = PlayAnimationOnChannel(0, AlternateOpenAnimationName, 4);
	SetAnimationPlaybackRate(Handle, AlternateOpenAnimationRate);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA3
	/*@Error*/
	DoorPortal.bOpenPortals = true;
	return;
	@NULL
	Item
	Item
	@NULL
}

function CloseAlternateDoor()
{
	// End:0x49
	if(__NFUN_130__(bIsAlternateOpen, __NFUN_129__(bDoorOpen)))
	{
		TriggerEffectEvent('SmallDoorClosed');
		OriginalState = __NFUN_284__();
		__NFUN_113__('AlternateDoorClosing');
		return;
		@NULL
		Item
	}
	Item
}

state AlternateDoorClosing
{Begin:

	PlayAnimAndWaitForFinish(AlternateCloseAnimationName, AlternateCloseAnimationRate);
	bIsAlternateOpen = false;
	// End:0x59
	if(__NFUN_119__(DoorPortal, none))
	{
		DoorPortal.bOpenPortals = bIsInOperation;
		__NFUN_113__(OriginalState);
		stop;						
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

defaultproperties
{
	AlternateOpenAnimationRate=1.0000000
	AlternateCloseAnimationRate=1.0000000
}