class MessageTrigger extends Message
	editinlinenew
	hidecategories(Object);

var name Trigger;
var name Instigator;

function Construct(name _trigger, name _instigator)
{
	Trigger = _trigger;
	Instigator = _instigator;
	return;
	@NULL
	Variable
	GetPropertyTextByName
	@NULL
}

function string editorDisplay(name TriggeredBy, Message filter)
{
	return __NFUN_112__("Any trigger message from ", string(TriggeredBy));
	return;
	@NULL
}

defaultproperties
{
	specificTo=Class'Scripting.Trigger'
}