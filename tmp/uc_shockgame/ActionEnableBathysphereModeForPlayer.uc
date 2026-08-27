class ActionEnableBathysphereModeForPlayer extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool EnableBathysphereMode;

function Variable execute()
{
	local ShockPlayer Player;

	super.execute();
	Player = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	// End:0xC0
	if(EnableBathysphereMode)
	{
		Player.bUseHavokRigidBodyCapsuleCollisions = false;
		Player.bUseHavokPhantomCollisions = false;
		Player.DisableHavokCollision();
		Player.bCannotFall = true;
		goto J0x122;
		Player.bUseHavokRigidBodyCapsuleCollisions = true;
		Player.bUseHavokPhantomCollisions = true;
		Player.EnableHavokCollision();
		Player.bCannotFall = false;
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
	// End:0x43
	if(EnableBathysphereMode)
	{
		S = "Enable bathysphere mode for the player.";
		goto J0x77;
		S = "Disable bathysphere mode for the player.";
	}
	return;
	@NULL
	Item
	J0x77:

	Item
}

defaultproperties
{
	actionDisplayName="Enable Bathysphere Mode."
	actionHelp="Puts the player into or takes the player out of a state that allows for proper bathysphere travel."
	Category="Player"
}