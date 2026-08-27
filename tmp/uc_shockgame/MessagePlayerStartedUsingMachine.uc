class MessagePlayerStartedUsingMachine extends Message
	editinlinenew
	hidecategories(Object);

var name MachineLabel;
var name MachineClass;

function Construct(ShockMachine MachineThatWasUsed)
{
	MachineLabel = MachineThatWasUsed.Label;
	MachineClass = MachineThatWasUsed.Class.Name;
	return;
	@NULL
	Item
	Vector
	@NULL
}

function string editorDisplay(name Instigator, Message filter)
{
	return __NFUN_112__(__NFUN_112__("The player started interacting with Machine '", string(Instigator)), "'.");
	return;
	@NULL
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockMachine'
}