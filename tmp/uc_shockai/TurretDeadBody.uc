class TurretDeadBody extends PhysicalReactiveActor implements IHaveAContainer
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Collision);

var private Container LootContainer;
var private string UseText;
var private string FocusDisplayName;
var private string HUDMessageForFocusAttained;

function InitializeDeadBody(Container inContainer, string inUseText, string inFocusDisplayName, string inHUDMessageForFocusAttained)
{
	LootContainer = inContainer;
	UseText = inUseText;
	FocusDisplayName = inFocusDisplayName;
	HUDMessageForFocusAttained = inHUDMessageForFocusAttained;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x73
	/*@Error*/
	LootContainer.SetOwner(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Container GetContainer()
{
	return LootContainer;
	return;
	@NULL
}

function bool CanBeUsedNow()
{
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	return __NFUN_130__(thePlayer.CanUseContainer(LootContainer), bShowHudElements);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnUsed(Pawn Pawn)
{
	AssertWithDescription(Pawn.__NFUN_303__('ShockPlayer'), __NFUN_112__(string(Class.Name), " was used by someone other than a ShockPlayer."));
	super(ReactiveActor).OnUsed(Pawn);
	ShockPlayer(Pawn).OpenContainer(LootContainer, GetCurrentMaterial());
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function string GetUseVerbText()
{
	return UseText;
	return;
	@NULL
}

function string GetFocusDisplayName()
{
	return FocusDisplayName;
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
		LootContainer.ModifyHudMessage(feedbackString);
		return feedbackString;
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}
