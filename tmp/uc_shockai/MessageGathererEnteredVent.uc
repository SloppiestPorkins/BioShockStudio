class MessageGathererEnteredVent extends Message
	editinlinenew
	hidecategories(Object);

var name GathererLabel;
var name ProtectorLabel;
var name VentLabel;

function Construct(Gatherer theGatherer)
{
	GathererLabel = theGatherer.Label;
	VentLabel = theGatherer.GetCurrentVent().Label;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x99
	/*@Error*/
	ProtectorLabel = theGatherer.GetProtectorEscort().Label;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "A Gatherer finished entering a vent.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockAI.ShockAI'
}