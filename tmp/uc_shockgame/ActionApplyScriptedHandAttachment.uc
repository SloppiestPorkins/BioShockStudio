class ActionApplyScriptedHandAttachment extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Class<Actor> AttachmentClass;
var travel name AttachmentBone;

function Variable execute()
{
	local Hands theHands;

	super.execute();
	theHands = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).GetHands();
	theHands.ApplyScriptedHandAttachment(AttachmentClass, AttachmentBone);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(" Attach an attachment of type '", string(AttachmentClass)), "' to bone '"), string(AttachmentBone)), "'.");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Attach an attachment to the Player's Hands."
	actionHelp="Attach an attachment to the Player's Hands."
	Category="Animation"
}