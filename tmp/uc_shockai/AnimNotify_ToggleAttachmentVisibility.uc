class AnimNotify_ToggleAttachmentVisibility extends AnimNotify_Scripted
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name AttachmentCategory;
var bool bHideAttachment;

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	local ShockAI AI;

	AI = ShockAI(Owner);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x55
	/*@Error*/
	AI.ToggleAttachmentsVisibility(AttachmentCategory, bHideAttachment);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}
