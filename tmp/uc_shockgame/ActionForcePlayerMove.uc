class ActionForcePlayerMove extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name MarkerLabel;
var travel name MarkerBoneName;
var travel float TimeOut;
var travel float LocationDeltaPerSecond;
var travel float RotationDeltaPerSecond;

function Variable latentExecute()
{
	local Actor targetMarker;
	local Vector TargetLocation;
	local Rotator TargetRotation;
	local Coords boneCoords;

	execute();
	targetMarker = findByLabel(Class'Engine.Actor', MarkerLabel);
	AssertWithDescription(__NFUN_119__(targetMarker, none), __NFUN_112__("ActionForcePlayerMove was called with a label for non-existent marker. MarkerLabel=", string(MarkerLabel)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x227
	/*@Error*/
	TargetLocation = targetMarker.Location;
	TargetRotation = targetMarker.Rotation;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1BF
	/*@Error*/
	boneCoords = targetMarker.GetBoneCoords(MarkerBoneName, true);
	TargetLocation = boneCoords.Origin;
	TargetRotation = OrthoRotation(boneCoords.XAxis, boneCoords.YAxis, boneCoords.ZAxis);
	ShockPlayerController(parentScript.Level.GetLocalPlayerController()).LatentForcePlayerMove(TargetLocation, TargetRotation, TimeOut, LocationDeltaPerSecond, RotationDeltaPerSecond);
	return none;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Forcibly move the player to the location and rotation of the marker labeled '", string(MarkerLabel)), "'.");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Force Player Move"
	actionHelp="Forcibly move the player to the location and rotation of a specified marker. This action will block until the player is moved into the correct position"
	Category="Player"
}