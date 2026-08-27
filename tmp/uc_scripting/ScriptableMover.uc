class ScriptableMover extends Mover
	config
	hidecategories(DrawScale3D,DisplayAdvanced,MoverEvents,AI);

var Class<MessageTrigger> triggerMessageType;
var bool bDisableScriptLogs;

function PostBeginPlay()
{
	super.PostBeginPlay();
	// End:0x35
	if(__NFUN_119__(triggerMessageType, none))
	{
		registerMessage(triggerMessageType, TriggeredBy);
		return;
		@NULL
		Variable
		Variable
	}
	@NULL
}

function DoPlayerBumpEvent(Actor Other)
{
	super.DoPlayerBumpEvent(Other);
	dispatchMessage(Class'Scripting.MessageMoverPlayerBump'.static.Allocate(self)., construct_NameName(Label, Other.Label));
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function DoBumpEvent(Actor Other)
{
	super.DoBumpEvent(Other);
	dispatchMessage(Class'Scripting.MessageMoverBump'.static.Allocate(self)., construct_NameName(Label, Other.Label));
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function FinishedOpening()
{
	super.FinishedOpening();
	dispatchMessage(Class'Scripting.MessageMoverOpened'.static.Allocate(self)., construct_Name(Label));
	return;
	@NULL
	Variable
	Variable
}

function DoOpen()
{
	super.DoOpen();
	dispatchMessage(Class'Scripting.MessageMoverOpening'.static.Allocate(self)., construct_Name(Label));
	return;
	@NULL
	Variable
	Variable
}

function FinishedClosing()
{
	super.FinishedClosing();
	dispatchMessage(Class'Scripting.MessageMoverClosed'.static.Allocate(self)., construct_Name(Label));
	return;
	@NULL
	Variable
	Variable
}

function DoClose()
{
	super.DoClose();
	dispatchMessage(Class'Scripting.MessageMoverClosing'.static.Allocate(self)., construct_Name(Label));
	return;
	@NULL
	Variable
	Variable
}

function onMessage(Message msg)
{
	local MessageTrigger t;
	local Pawn Instigator;
	local Actor Other;
	local string otherName, instigatorName;

	// End:0x75
	if(__NFUN_129__(bDisableScriptLogs))
	{
		SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__("ScriptableMover ", string(Name)), " received message "), string(msg.Class.Name)));
		// End:0x86
		if(__NFUN_114__(triggerMessageType, none))
		{
			return;
			t = MessageTrigger(msg);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x220
		/*@Error*/
	}
	Other = findByLabel(Class'Engine.Pawn', t.Trigger);
	Instigator = Pawn(findByLabel(Class'Engine.Actor', t.Instigator));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x204
	/*@Error*/
	// End:0x156
	if(__NFUN_119__(Other, none))
	{
		otherName = string(Other);
		goto J0x166;
		otherName = "None";
		// End:0x18D
		if(__NFUN_119__(Instigator, none))
		{
			instigatorName = string(Instigator);
			goto J0x19D;
			instigatorName = "None";
			SLog(__NFUN_112__(__NFUN_112__(__NFUN_112__("   ScriptableMover triggering with instigator = ", string(Instigator)), " and other = "), string(Other)));
		}
		Trigger(Other, Instigator);
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	triggerMessageType=Class'Scripting.MessageTrigger'
	bStasis=false
	bBlockHavok=true
}