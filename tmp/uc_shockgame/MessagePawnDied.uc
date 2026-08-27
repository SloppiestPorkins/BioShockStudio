class MessagePawnDied extends Message
	editinlinenew
	hidecategories(Object);

var name PawnLabel;
var name PawnClass;
var name PatrolName;

function Construct(ShockPawn ThePawn)
{
	PawnLabel = ThePawn.Label;
	PawnClass = ThePawn.Class.Name;
	PatrolName = ThePawn.GetPatrolName();
	return;
	@NULL
	Item
	Vector
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A Pawn died.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPawn'
}