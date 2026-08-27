class ActionRemoveScriptedHandAttachment extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	local Hands theHands;

	super.execute();
	theHands = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).GetHands();
	theHands.RemoveScriptedHandAttachment();
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = " Remove an existing scripted attachment from the Player's Hands.";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Remove an existing scripted attachment from the Player's Hands."
	actionHelp="Remove an existing scripted attachment from the Player's Hands."
	Category="Animation"
}