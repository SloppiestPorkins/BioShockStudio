class MessagePlayerHitGathererVent extends Message
	editinlinenew
	hidecategories(Object);

var name VentLabel;
var bool bGathererSpawned;

function Construct(GathererVent vent, bool _bGathererSpawned)
{
	VentLabel = vent.Label;
	bGathererSpawned = _bGathererSpawned;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function string editorDisplay(name Instigator, Message filter)
{
	return __NFUN_112__(__NFUN_112__("The player hit '", string(Instigator)), "' with a wrench.");
	return;
	@NULL
}

defaultproperties
{
	specificTo=Class'ShockAI.GathererVent'
}