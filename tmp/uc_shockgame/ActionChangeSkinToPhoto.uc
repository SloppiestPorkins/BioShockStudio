class ActionChangeSkinToPhoto extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name TargetLabel;
var travel name PhotoLabel;
var travel int Index;

function Variable execute()
{
	local Actor Target;
	local ShockPlayer Player;

	super.execute();
	Target = parentScript.findByLabel(Class'Engine.Actor', TargetLabel);
	AssertWithDescription(__NFUN_119__(Target, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("The Script named ", string(parentScript.Name)), " tried to execute an ActionChangeSkinToPhoto on a Target defined by having the Label '"), string(TargetLabel)), "', but no such target was found."));
	Player = ShockPlayer(Target.Level.GetLocalPlayerController().Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D2
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x192
	/*@Error*/
	Target.CopyMaterialsToSkins();
	Target.SetSkin(Index, Player.GetCopyOfPhoto(PhotoLabel));
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Change skin on '", string(TargetLabel)), "' at index "), string(Index)), " to Photo '"), string(PhotoLabel)), "'.");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	TargetLabel="UNSPECIFIED"
	PhotoLabel="UNSPECIFIED"
	actionDisplayName="Change a skin to photo on a mesh actor"
	actionHelp="Changes the skin of an Actor to a photo."
	Category="Actor"
}