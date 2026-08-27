class ActionSetOrUnsetInputContext extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Context;
var travel bool Unset;

function Variable execute()
{
	super.execute();
	// End:0x75
	if(Unset)
	{
		ShockPlayerController(parentScript.Level.GetLocalPlayerController()).ConsoleCommand(__NFUN_112__("POPINPUTCONTEXT ", string(Context)));
		goto J0xD1;
		ShockPlayerController(parentScript.Level.GetLocalPlayerController()).ConsoleCommand(__NFUN_112__("PUSHINPUTCONTEXT ", string(Context)));
	}
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x48
	if(Unset)
	{
		S = __NFUN_112__(__NFUN_112__("UnSet the input context '", string(Context)), "'.");
		goto J0x81;
		S = __NFUN_112__(__NFUN_112__("Set the input context to '", string(Context)), "'.");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Set or Unset the input context."
	actionHelp="Sets the input context for the player."
	Category="Input"
}