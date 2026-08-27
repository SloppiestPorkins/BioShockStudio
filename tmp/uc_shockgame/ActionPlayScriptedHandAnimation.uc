class ActionPlayScriptedHandAnimation extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name HandAnimation;
var travel name AttachmentAnimation;
var travel int AnimationEndBehavior;
var travel float EaseIn;
var travel bool WaitForAnimationToFinish;

function Variable latentExecute()
{
	local Hands theHands;

	execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xFE
	/*@Error*/
	theHands = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).GetHands();
	// End:0xAD
	if(__NFUN_255__(HandAnimation, 'None'))
	{
		theHands.FinishAnimation(theHands.ScriptedHandsAnimationHandle);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xFE
		/*@Error*/
		theHands.ScriptedAttachment.FinishAnimation(theHands.ScriptedAttachmentAnimationHandle);
	}
	return none;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function Variable execute()
{
	local Hands theHands;

	super.execute();
	theHands = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).GetHands();
	theHands.PlayScriptedHandAnimation(HandAnimation, AttachmentAnimation, AnimationEndBehavior, EaseIn);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Play animation '", string(HandAnimation)), "' on the Player's hands.");
	return;
	@NULL
	Item
}

defaultproperties
{
	AnimationEndBehavior=4
	actionDisplayName="Play an animation on the player's hands"
	actionHelp="Plays a specified animation on the player's hands."
	Category="Animation"
}