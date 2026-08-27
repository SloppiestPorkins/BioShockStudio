class ActionAttachToBone extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AttachmentActorLabel;
var travel name BaseActorLabel;
var travel name TargetBone;
var travel Vector AttachmentRelativeLocation;
var travel Rotator AttachmentRelativeRotation;

function Variable execute()
{
	local Actor AttachmentActor, BaseActor;

	super.execute();
	AttachmentActor = parentScript.findByLabel(Class'Engine.Actor', AttachmentActorLabel);
	BaseActor = parentScript.findByLabel(Class'Engine.Actor', BaseActorLabel);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF9
	/*@Error*/
	BaseActor.AttachToBone(AttachmentActor, TargetBone);
	AttachmentActor.SetRelativeLocation(AttachmentRelativeLocation);
	AttachmentActor.SetRelativeRotation(AttachmentRelativeRotation);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Attach actor '", string(AttachmentActorLabel)), "' to '"), string(BaseActorLabel)), "' on bone '"), string(TargetBone)), "'");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Attach one actor to another on a specified bone"
	actionHelp="Attach one actor to another on a specified bone."
	Category="Actor"
}