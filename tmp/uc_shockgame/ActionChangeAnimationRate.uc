class ActionChangeAnimationRate extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

const kRateAtTargetEpsilon = 0.1;

var travel name TargetLabel;
var travel name TargetAnimationName;
var travel float TargetAnimationRate;
var travel float RateChangeTime;

function Variable execute()
{
	super.execute();
	SetAnimsToTargetRateImmediately();
	return none;
	return;
	@NULL
}

function Variable latentExecute()
{
	// End:0x20
	if(__NFUN_178__(RateChangeTime, 0.0000000))
	{
		SetAnimsToTargetRateImmediately();
		goto J0x2A;
		SetAnimsToTargetRateGradually();
	}
	return none;
	return;
	J0x2A:

	@NULL
}

function editorDisplayString(out string S)
{
	// End:0xC9
	if(__NFUN_177__(RateChangeTime, 0.0000000))
	{
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Change playback rate for animation '", string(TargetAnimationName)), "' on '"), string(TargetLabel)), "'. New rate: "), string(TargetAnimationRate)), " with a change rate of 1 unit every "), string(RateChangeTime)), " seconds");
		goto J0x13B;
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Change playback rate for animation '", string(TargetAnimationName)), "' on '"), string(TargetLabel)), "'. New rate: "), string(TargetAnimationRate));
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function GetTargetAndAnimHandles(out Actor Target, out array<int> AnimHandles)
{
	local int i;

	Target = parentScript.findByLabel(Class'Engine.Actor', TargetLabel);
	AssertWithDescription(__NFUN_119__(Target, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("The Script named ", string(parentScript.Name)), " tried to execute an ActionChangeAnimationRate on a Target defined by having the Label '"), string(TargetLabel)), "', but no such target was found."));
	AssertWithDescription(__NFUN_154__(int(Target.DrawType), int(2)), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("The Script named ", string(parentScript.Name)), " tried to execute an ActionChangeAnimationRate on a Target defined by having the Label '"), string(TargetLabel)), "'.\nThe target was found (named "), string(Target.Name)), "), but it is not DrawType DT_Mesh, so it can't play animations."));
	Target.GetAnimationInstanceHandles(AnimHandles);
	i = __NFUN_147__(AnimHandles.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x301
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2D6
	/*@Error*/
	AnimHandles.Remove(i, 1);
	goto J0x2F3;
	SetThisActionAsAnimHandleOwner(AnimHandles[i]);
	__NFUN_164__(i);
	goto J0x278;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function SetAnimsToTargetRateImmediately()
{
	local Actor Target;
	local array<int> AnimHandles;
	local int i;

	GetTargetAndAnimHandles(Target, AnimHandles);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x80
	/*@Error*/
	Target.SetAnimationPlaybackRate(AnimHandles[i], TargetAnimationRate);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x27;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function SetAnimsToTargetRateGradually()
{
	local Actor Target;
	local array<int> AnimHandles;
	local int i;
	local bool isDone;
	local float LastTimeSeconds, DeltaTime;

	GetTargetAndAnimHandles(Target, AnimHandles);
	LastTimeSeconds = Target.Level.TimeSeconds;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1CA
	/*@Error*/
	DeltaTime = __NFUN_175__(Target.Level.TimeSeconds, LastTimeSeconds);
	LastTimeSeconds = Target.Level.TimeSeconds;
	isDone = true;
	i = __NFUN_147__(AnimHandles.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1B0
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x18E
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x18B
	/*@Error*/
	isDone = false;
	DoGradualAnimRateChange(Target, AnimHandles[i], DeltaTime);
	goto J0x1A2;
	AnimHandles.Remove(i, 1);
	__NFUN_164__(i);
	// [Loop Continue]
	goto J0xE0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1C7
	/*@Error*/
	__NFUN_256__(0.0000000);
	// [Loop Continue]
	goto J0x49;
	return;
	@NULL
	Collectable
	ShockPawn
	@NULL
}

function DoGradualAnimRateChange(Actor Target, int AnimHandle, float DeltaTime)
{
	local float CurrentRate, RateDiff, AbsRateDiff, ChangeSign, NewRate;

	assert(__NFUN_177__(RateChangeTime, 0.0000000));
	CurrentRate = Target.GetAnimationPlaybackRate(AnimHandle);
	RateDiff = __NFUN_175__(TargetAnimationRate, CurrentRate);
	AbsRateDiff = __NFUN_186__(RateDiff);
	// End:0x95
	if(__NFUN_177__(RateDiff, 0.0000000))
	{
		ChangeSign = 1.0000000;
		goto J0xA4;
		ChangeSign = -1.0000000;
		NewRate = __NFUN_174__(CurrentRate, __NFUN_171__(__NFUN_246__(__NFUN_171__(RateChangeTime, DeltaTime), 0.0000000, AbsRateDiff), ChangeSign));
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11B
	/*@Error*/
	NewRate = TargetAnimationRate;
	Target.SetAnimationPlaybackRate(AnimHandle, NewRate);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function SetThisActionAsAnimHandleOwner(int AnimHandle)
{
	//native.AnimHandle;	
	@NULL
}

function bool IsAnimOwnedByThisAction(int AnimHandle)
{
	//native.AnimHandle;	
	@NULL
}

defaultproperties
{
	TargetLabel="UNSPECIFIED"
	TargetAnimationRate=1.0000000
	actionDisplayName="Change the rate of a playing animation on a mesh actor"
	actionHelp="Causes a Target Actor of DrawType DT_Mesh to change the rate of an already playing animation."
	Category="Actor"
}