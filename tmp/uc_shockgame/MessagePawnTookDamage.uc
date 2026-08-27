class MessagePawnTookDamage extends Message
	editinlinenew
	hidecategories(Object);

var Class<ShockPawn> PawnClass;
var name PawnLabel;
var float PawnHealth;
var Class<Actor> DamagerClass;
var name DamagerLabel;

function Construct(ShockPawn ThePawn, Actor Damager)
{
	PawnClass = ThePawn.Class;
	PawnLabel = ThePawn.Label;
	PawnHealth = ThePawn.GetHealth();
	DamagerClass = Damager.Class;
	DamagerLabel = Damager.Label;
	return;
	@NULL
	Item
	Vector
	@NULL
}

static function string editorDisplay(name Instigator, Message filter)
{
	return "A Pawn took damage.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPawn'
}