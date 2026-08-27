class MessageTelekinesisStartedPullingActor extends Message
	editinlinenew
	hidecategories(Object);

var name ActorLabel;

function Construct(Actor theActor)
{
	ActorLabel = theActor.Label;
	return;
	@NULL
	Item
	Vector
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "Telekinesis started pulling an actor";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPlayer'
}