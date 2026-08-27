class ActionDisplayOnScreenDebugMessage extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel string Message;

function Variable execute()
{
	local PlayerController PC;

	super.execute();
	PC = parentScript.Level.GetLocalPlayerController();
	PC.ClientMessage(Message, 'Debug');
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Display \"[DEBUG: ", propertyDisplayString('Message')), "]\" on the screen");
	return;
	@NULL
}

defaultproperties
{
	Message="<message text>"
	actionDisplayName="Display On-screen Debug Message"
	actionHelp="Displays a temporary message on the screen for debugging purposes"
	Category="Other"
}