class ActionTelekinesisDropObject extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super.execute();
	ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).DropObject();
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = "Forces the player to drop anything they are holding with telekinesis";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Drops object held with telekinesis"
	actionHelp="Force player to drop any object held with telekinesis"
	Category="Player"
}