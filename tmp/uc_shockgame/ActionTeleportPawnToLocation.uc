class ActionTeleportPawnToLocation extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name PawnLabel;
var travel name MarkerLabel;

function Variable execute()
{
	local ShockPawn targetPawn;
	local Actor targetMarker;
	local Actor.EPhysics PreviousPhysics;

	super.execute();
	targetPawn = ShockPawn(findByLabel(Class'ShockGame.ShockPawn', PawnLabel));
	targetMarker = findByLabel(Class'Engine.Actor', MarkerLabel);
	PreviousPhysics = targetPawn.Physics;
	targetPawn.__NFUN_3970__(0);
	targetPawn.ShouldNotTakeDamageOnNextLanding = true;
	targetPawn.__NFUN_267__(targetMarker.Location);
	targetPawn.__NFUN_299__(targetMarker.Rotation);
	targetPawn.Controller.__NFUN_299__(targetMarker.Rotation);
	targetPawn.__NFUN_3970__(PreviousPhysics);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Move the pawn with label ", string(PawnLabel)), " to Marker with label "), string(MarkerLabel)), ".");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Teleport Pawn."
	actionHelp="Teleports a pawn to a specified Marker location/rotation."
	Category="Actor"
}