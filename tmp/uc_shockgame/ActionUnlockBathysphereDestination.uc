class ActionUnlockBathysphereDestination extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name MapName;
var travel name BathysphereSystem;

function Variable execute()
{
	super.execute();
	ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).UnlockBathysphereDestination(BathysphereSystem, MapName);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function enumMaps(LevelInfo Level, out array<name> S)
{
	local BathysphereManager BathysphereManager;
	local int i;

	BathysphereManager = Class'ShockGame.BathysphereManager'.static.Allocate(self,, string(BathysphereSystem)).;
	Construct_Void();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC1
	/*@Error*/
	S[S.Length] = BathysphereManager.Destinations[i].MapName;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x48;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Allow bathysphere travel to ", string(MapName));
	return;
	@NULL
	Item
}

defaultproperties
{
	BathysphereSystem="BioshockBathyspheres"
	actionDisplayName="Allow bathysphere travel to a new map."
	actionHelp="Allow bathysphere travel to a new map."
	Category="Level"
}