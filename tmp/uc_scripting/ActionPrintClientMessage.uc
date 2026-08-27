class ActionPrintClientMessage extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var localized travel string MessageText;
var travel name MessageType;

function Variable execute()
{
	super.execute();
	parentScript.Level.GetLocalPlayerController().ClientMessage(MessageText, MessageType);
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Print '", MessageText), "' to the HUD.");
	return;
	@NULL
	Variable
}

defaultproperties
{
	actionDisplayName="Print to HUD"
	actionHelp="Prints a message on the HUD using ClientMessage."
	Category="Other"
	bIsGameCritical=false
}