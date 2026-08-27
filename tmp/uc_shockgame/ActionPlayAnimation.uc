class ActionPlayAnimation extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

enum EEndBehaviorMode
{
	EndBehavior_Pause,              // 0
	EndBehavior_Loop,               // 1
	EndBehavior_Stop,               // 2
	EndBehavior_EaseOut             // 3
};

var travel name TargetLabel;
var travel name Animation;
var travel float AnimationRate;
var travel float TweenTime;
var travel int Channel;
var travel ActionPlayAnimation.EEndBehaviorMode EndBehavior;
var travel bool bWaitForCompletion;
var travel bool bPauseUntilEntirelyEasedIn;
var travel bool bOnlyPlayOnAlivePawns;
var travel array<Actor> TargetActors;
var travel bool bAssertedAboutMissingTarget;

function StoreTargetActors()
{
	local Actor A;
	local int i;

	TargetActors.Remove(0, TargetActors.Length);
	// End:0x69
	foreach parentScript.allActorLabel(Class'Engine.Actor', A, TargetLabel)
	{
		TargetActors[TargetActors.Length] = A;				
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2CD
		/*@Error*/
		bAssertedAboutMissingTarget = true;
		AssertWithDescription(__NFUN_151__(TargetActors.Length, 0), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("The Script named ", string(parentScript.Name)), " tried to execute an ActionPlayAnimation on a Target defined by having the Label '"), string(TargetLabel)), "', but no such target was found."));
	}
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2CD
	/*@Error*/
	AssertWithDescription(__NFUN_154__(int(TargetActors[i].DrawType), int(2)), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("The Script named ", string(parentScript.Name)), " tried to execute an ActionPlayAnimation on a Target defined by having the Label '"), string(TargetLabel)), "'.\nThe target was found (named "), string(TargetActors[i].Name)), "), but it is not DrawType DT_Mesh, so it can't play animations."));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x15B;
	return;
	@NULL
	Item
	Item
	@NULL
}

function int StartAnimationOnTarget(Actor Target)
{
	local int EndMode, Handle;
	local bool bIsLooping;
	local Pawn targetPawn;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x287
	/*@Error*/
	// End:0x7D
	if(bOnlyPlayOnAlivePawns)
	{
		targetPawn = Pawn(Target);
		// End:0x7D
		if(__NFUN_130__(__NFUN_119__(targetPawn, none), __NFUN_129__(Class'Engine.Pawn'.static.checkAlive(targetPawn))))
		{
			return Class'Engine.Actor'.0;
			// End:0xAD
			if(__NFUN_154__(int(EndBehavior), int(0)))
			{
				EndMode = Class'Engine.Actor'.4;
				goto J0x145;
				// End:0xE9
				if(__NFUN_154__(int(EndBehavior), int(1)))
				{
				}
			}
			EndMode = Class'Engine.Actor'.8;
			bIsLooping = true;
			goto J0x145;
			// End:0x119
			if(__NFUN_154__(int(EndBehavior), int(2)))
			{
			}
			EndMode = Class'Engine.Actor'.2;
			goto J0x145;
			// End:0x145
			if(__NFUN_154__(int(EndBehavior), int(3)))
			{
				EndMode = Class'Engine.Actor'.1;
			}
			// End:0x1B2
			if(__NFUN_254__(Animation, 'None'))
			{
				Handle = Target.GetAnimationOnChannel(Channel);
				Target.FlatEaseOutAnimation(Handle, TweenTime);
			}
			goto J0x287;
			Handle = Target.PlayAnimationOnChannel(Channel, Animation, EndMode);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x287
		/*@Error*/
		Target.SetAnimationPlaybackRate(Handle, AnimationRate);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x287
		/*@Error*/
		BaseShockAI(Target).NotifyPlayingScriptedLoopingAnimation(Handle);
	}
	return Handle;
	return;
	@NULL
	Item
	Item
	@NULL
}

function Variable execute()
{
	local int i;

	super.execute();
	StoreTargetActors();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x62
	/*@Error*/
	StartAnimationOnTarget(TargetActors[i]);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1F;
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function Variable latentExecute()
{
	local array<int> Handles;
	local int i;
	local bool isDone;

	// End:0x1A
	if(__NFUN_151__(resolveInfoList.Length, 0))
	{
		resolveParameters();
		StoreTargetActors();
	}
	i = 0;
	// End:0xA9
	if(__NFUN_150__(i, TargetActors.Length))
	{
		TargetActors[i].bStasis = false;
		Handles[i] = StartAnimationOnTarget(TargetActors[i]);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x2F;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2B2
		/*@Error*/
		i = 0;
		// End:0x11B
		if(__NFUN_150__(i, TargetActors.Length))
		{
			TargetActors[i].PauseAnimation(Handles[i]);
		}
		__NFUN_163__(i);
		goto J0xC1;
		isDone = false;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2B2
		/*@Error*/
		isDone = true;
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x298
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x28A
		/*@Error*/
	}
	// End:0x256
	if(__NFUN_130__(TargetActors[i].IsAnimationPerTrackEasingIn(Handles[i]), __NFUN_129__(TargetActors[i].IsAnimationPerTrackEntirelyEasedIn(Handles[i]))))
	{
		isDone = false;
		goto J0x28A;
		TargetActors[i].ResumeAnimation(Handles[i]);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x14D;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2AF
		/*@Error*/
		__NFUN_256__(0.0000000);
		// [Loop Continue]
		goto J0x127;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x398
		/*@Error*/
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x324
		/*@Error*/
		TargetActors[i].FinishAnimation(Handles[i]);
		__NFUN_163__(i);
		goto J0x2CA;
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x398
		/*@Error*/
		TargetActors[i].bStasis = TargetActors[i].default.bStasis;
	}
	__NFUN_163__(i);
	goto J0x32F;
	return none;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Play animation '", string(Animation)), "' on '"), string(TargetLabel)), "' at speed "), string(AnimationRate)), " on channel "), string(Channel)), " with tween time of "), string(TweenTime));
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	TargetLabel="UNSPECIFIED"
	AnimationRate=1.0000000
	bOnlyPlayOnAlivePawns=true
	actionDisplayName="Play an animation on a mesh actor"
	actionHelp="Causes a Target Actor of DrawType DT_Mesh to play a specified Animation."
	Category="Actor"
}