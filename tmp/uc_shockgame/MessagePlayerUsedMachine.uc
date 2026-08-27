class MessagePlayerUsedMachine extends Message
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
	return __NFUN_112__(__NFUN_112__("(Deprecated: Use the 'Finished Using' message instead)Machine '", string(Instigator)), "' was used by the player");
	return;
	@NULL
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockMachine'
}