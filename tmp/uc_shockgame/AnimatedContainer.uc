class AnimatedContainer extends ReactiveAnimatedMesh implements IHaveAContainer
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Movement,Havok);

var private export editinline Container Container;
var private name AnimOpening;
var private name AnimOpened;
var private bool bIsOpened;

function PreBeginPlay()
{
	super.PreBeginPlay();
	Container.SetOwner(self);
	return;
	@NULL
	Item
}

function Container GetContainer()
{
	return Container;
	return;
	@NULL
}

function bool CanBeUsedNow()
{
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	return __NFUN_130__(thePlayer.CanUseContainer(Container), bShowHudElements);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnUsed(Pawn Pawn)
{
	AssertWithDescription(Pawn.__NFUN_303__('ShockPlayer'), __NFUN_112__(string(Class.Name), " was used by someone other than a ShockPlayer."));
	super(ReactiveActor).OnUsed(Pawn);
	Open();
	ShockPlayer(Pawn).OpenContainer(Container, GetCurrentMaterial());
	return;
	@NULL
	Item
	Item
	@NULL
}

function Open()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x1A
	/*@Error*/
	__NFUN_113__('Opened');
	return;
	@NULL
}

function string GetHUDMessageForFocusAttained()
{
	local string feedbackString;

	feedbackString = GetFocusDisplayName();
	// End:0x41
	if(CanBeUsedNow())
	{
		Container.ModifyHudMessage(feedbackString);
		return feedbackString;
		return;
		@NULL
	}
	Item
	Item
	@NULL
}

function bool IsOpened()
{
	return bIsOpened;
	return;
	@NULL
}

state Opened
{
	ignores BeginOpened;
Begin:

	bIsOpened = true;
	log('Game', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), ": Beginning code for state "), string(__NFUN_284__())), ""));
	// End:0xA8
	if(__NFUN_154__(int(DrawType), int(2)))
	{
		FinishAnimation(GetAnimationOnChannel(0));
		TriggerEffectEvent('ContainerOpening');
		FinishAnimation(PlayAnimationOnChannel(0, AnimOpening, 4));
		goto J0xBB;
		TriggerEffectEvent('ContainerOpening');
		BeginOpened();
	}
	stop;		
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
	AnimOpening="SimpleAnim_Rock"
	AnimOpened="SimpleAnim_Rotate"
	bPlayOnStartup=false
	FriendlyName="Container"
	UseVerbText="SEARCH"
	bBlockHavok=true
}