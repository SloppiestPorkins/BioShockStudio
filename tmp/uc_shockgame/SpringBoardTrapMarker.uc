class SpringBoardTrapMarker extends Actor
	native
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var /*0x00000000-0x01000000*/ private transient pointer Phantom;

function CreateSpringBoardTrapPhantom(ShockPlayer Player)
{
	//native.Player;	
	@NULL
}

function PostBeginPlay()
{
	CreateSpringBoardTrapPhantom(ShockPlayer(Level.GetLocalPlayerController().Pawn));
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	DrawType=0
}