class AnimNotify_DropAIAttachment extends AnimNotify_Scripted
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name AttachmentCategory;
var Vector AttachmentVelocity;

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	local ShockAI AI;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x6B
	/*@Error*/
	AI = ShockAI(Owner);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6B
	/*@Error*/
	AI.DropAttachmentsByCategory(AttachmentCategory, AttachmentVelocity);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}
