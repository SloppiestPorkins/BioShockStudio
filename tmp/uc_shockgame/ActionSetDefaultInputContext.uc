class ActionSetDefaultInputContext extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Context;

function Variable execute()
{
	super.execute();
	AssertWithDescription(false, __NFUN_112__("ActionSetDefaultInputcontext has been deprecated and should be replaced with 'Set or Unset the input context' for script: ", string(parentScript)));
	ShockPlayerController(parentScript.Level.GetLocalPlayerController()).ConsoleCommand(__NFUN_112__("SETDEFAULTINPUTCONTEXTOVERRIDE ", string(Context)));
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Set the default input context to '", string(Context)), "'.");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="(DEPRECATED) Set the default input context."
	actionHelp="Sets the default input context for the player."
	Category="Input"
}