class AnimNotify_SpeechEvent extends AnimNotify_Scripted
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name SpeechEventName;

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	log('SpeechManager', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::Notify( "), string(Owner)), " )"));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x79
	/*@Error*/
	ShockAI(Owner).PlaySpeech(SpeechEventName);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}
