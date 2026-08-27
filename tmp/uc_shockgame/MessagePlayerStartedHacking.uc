class MessagePlayerStartedHacking extends Message
	editinlinenew
	hidecategories(Object);

var name ActorLabel;
var name actorClass;

function Construct(ICanBeHacked ActorThatIsBeingHacked)
{
	ActorLabel = Actor(ActorThatIsBeingHacked).Label;
	actorClass = ActorThatIsBeingHacked.Class.Name;
	return;
	@NULL
	Item
	Vector
	@NULL
}

function string editorDisplay(name Instigator, Message filter)
{
	return __NFUN_112__(__NFUN_112__("The player has started hacking '", string(Instigator)), "'.");
	return;
	@NULL
}

defaultproperties
{
	specificTo=Class'ShockGame.ICanBeHacked'
}