class MessagePlayerEquippedPlasmid extends Message
	native
	editinlinenew
	hidecategories(Object);

var name Plasmid;

static function string editorDisplay(name Instigator, Message filter)
{
	return "The Player equipped a Plasmid";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.PlasmidManager'
}