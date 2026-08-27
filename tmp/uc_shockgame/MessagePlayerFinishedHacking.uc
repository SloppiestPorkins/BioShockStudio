class MessagePlayerFinishedHacking extends Message
	editinlinenew
	hidecategories(Object);

var name ActorLabel;
var name actorClass;
var bool SuccessfulHack;

function Construct(ICanBeHacked ActorThatIsBeingHacked, bool Success)
{
	ActorLabel = Actor(ActorThatIsBeingHacked).Label;
	actorClass = ActorThatIsBeingHacked.Class.Name;
	SuccessfulHack = Success;
	return;
	@NULL
	Item
	Vector
	@NULL
}

function string editorDisplay(name Instigator, Message filter)
{
	return __NFUN_112__(__NFUN_112__("The player has finished hacking '", string(Instigator)), "'.");
	return;
	@NULL
}

defaultproperties
{
	specificTo=Class'ShockGame.ICanBeHacked'
}