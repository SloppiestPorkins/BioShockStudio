class StaticMeshContainer extends ReactiveActor implements IHaveAContainer
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Movement);

var export editinline Container Container;

function PreBeginPlay()
{
	super(Actor).PreBeginPlay();
	// End:0x31
	if(__NFUN_119__(Container, none))
	{
		Container.SetOwner(self);
		return;
		@NULL
		Item
	}
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
	super.OnUsed(Pawn);
	ShockPlayer(Pawn).OpenContainer(Container, GetCurrentMaterial());
	return;
	@NULL
	Item
	Item
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

defaultproperties
{
	FriendlyName="Container"
	UseVerbText="SEARCH"
	bPathColliding=true
}