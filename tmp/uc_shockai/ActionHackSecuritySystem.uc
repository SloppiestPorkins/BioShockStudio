class ActionHackSecuritySystem extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel float ShutdownTime;

function Variable execute()
{
	super.execute();
	ShockGameInfo(parentScript.Level.Game).GetSecurityManager().HackSecuritySystem(ShutdownTime);
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Shutdown security for ", string(ShutdownTime)), " seconds.");
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	ShutdownTime=30.0000000
	actionDisplayName="Hack Security System"
	actionHelp="Shuts down the security system for a specified amount of time.  Same as if the player hacked the security system."
	Category="Security"
}