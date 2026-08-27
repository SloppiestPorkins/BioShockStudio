class MessageTriggerVolume extends Message
	editinlinenew
	hidecategories(Object);

var name TriggerVolume;
var name Instigator;

function Construct(name _triggerVolume, name _instigator)
{
	TriggerVolume = _triggerVolume;
	Instigator = _instigator;
	return;
	@NULL
	Variable
	GetPropertyTextByName
	@NULL
}

function string editorDisplay(name TriggeredBy, Message filter)
{
	return __NFUN_112__("Any TriggerVolume message from ", string(TriggeredBy));
	return;
	@NULL
}

defaultproperties
{
	specificTo=Class'Scripting.TriggerVolume'
}