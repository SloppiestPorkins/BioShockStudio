class MessagePlayerFinishedUsingMachine extends Message
	editinlinenew
	hidecategories(Object);

var name MachineLabel;
var name MachineClass;
var bool WasSuccessful;

function Construct(ShockMachine MachineThatWasUsed, bool Success)
{
	MachineLabel = MachineThatWasUsed.Label;
	MachineClass = MachineThatWasUsed.Class.Name;
	WasSuccessful = Success;
	return;
	@NULL
	Item
	Vector
	@NULL
}

function string editorDisplay(name Instigator, Message filter)
{
	return __NFUN_112__(__NFUN_112__("The player stopped interacting with Machine '", string(Instigator)), "'.");
	return;
	@NULL
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockMachine'
}