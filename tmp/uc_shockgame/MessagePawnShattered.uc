class MessagePawnShattered extends Message
	editinlinenew
	hidecategories(Object);

var name PawnLabel;
var Class<ShockPawn> PawnClass;

function Construct(ShockPawn inPawn)
{
	PawnLabel = inPawn.Label;
	PawnClass = inPawn.Class;
	return;
	@NULL
	Item
	Vector
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A pawn was shattered.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPawn'
}