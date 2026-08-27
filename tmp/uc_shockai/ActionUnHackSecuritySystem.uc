class ActionUnHackSecuritySystem extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super.execute();
	ShockGameInfo(parentScript.Level.Game).GetSecurityManager().SetUnHacked();
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Reenable a hacked security system.";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Un-hack Security System"
	actionHelp="Reactivates a hacked security system."
	Category="Security"
}