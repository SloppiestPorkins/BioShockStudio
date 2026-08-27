class MessagePawnAquiredState extends Message
	editinlinenew
	hidecategories(Object);

var Class<ShockPawn> PawnClass;
var name PawnLabel;
var name StateName;
var bool UnAquired;

function Construct(ShockPawn ThePawn, name inStateName, bool inUnAquired)
{
	PawnClass = ThePawn.Class;
	PawnLabel = ThePawn.Label;
	StateName = inStateName;
	UnAquired = inUnAquired;
	return;
	@NULL
	Item
	Vector
	@NULL
}

static function string editorDisplay(name Instigator, Message filter)
{
	return "A Pawn Aquired or UnAquired a state.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPawn'
}