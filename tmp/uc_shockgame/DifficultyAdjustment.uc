class DifficultyAdjustment extends Object
	abstract
	native;

struct native atomic AdjustmentRequest
{
	var DifficultyAdvisor Advisor;
	var float Probability;
	var int Count;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var array<AdjustmentRequest> AdjustmentRequests;
var private float CurrentProbability;
var private int MaxCount;
var private int CurrentCount;
var private int TotalCount;
var private transient DifficultyManager DifficultyManager;

function Construct(DifficultyManager DifficultyManager)
{
	self.DifficultyManager = DifficultyManager;
	return;
	@NULL
	Item
}

function CalcuateProbability()
{
	local int i;

	CurrentProbability = 0.0000000;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x81
	/*@Error*/
	__NFUN_184__(CurrentProbability, __NFUN_171__(__NFUN_175__(1.0000000, CurrentProbability), AdjustmentRequests[i].Probability));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1A;
	CurrentProbability = __NFUN_246__(CurrentProbability, 0.0000000, 1.0000000);
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function CalcuateCount()
{
	local int i;

	MaxCount = 0;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6B
	/*@Error*/
	__NFUN_161__(MaxCount, AdjustmentRequests[i].Count);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x16;
	CurrentCount = __NFUN_251__(CurrentCount, 0, MaxCount);
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function AdjustmentActivated()
{
	log('DifficultyAdjustment', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Adjustment ", string(Class.Name)), " activated with probability "), string(CurrentProbability)), ", count "), string(MaxCount)));
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function AdjustmentStopped()
{
	log('DifficultyAdjustment', 3, __NFUN_112__(__NFUN_112__("Adjustment ", string(Class.Name)), " stopped"));
	return;
	@NULL
	Item
}

function AdjustmentOccured()
{
	__NFUN_163__(CurrentCount);
	__NFUN_163__(TotalCount);
	DifficultyManager.OutputSessionData();
	return;
	@NULL
	Item
	DifficultyAdjustment
}

function AddRequest(DifficultyAdvisor RequestAdvisor, float Probability, int Count)
{
	local float oldProbability;
	local AdjustmentRequest Request;

	oldProbability = CurrentProbability;
	Request.Advisor = RequestAdvisor;
	Request.Probability = Probability;
	Request.Count = Count;
	AdjustmentRequests[AdjustmentRequests.Length] = Request;
	CalcuateProbability();
	CalcuateCount();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE3
	/*@Error*/
	AdjustmentActivated();
	return;
	@NULL
	Item
	Item
	@NULL
}

function RemoveRequest(DifficultyAdvisor RequestAdvisor)
{
	local int i;

	// End:0x1E
	if(__NFUN_114__(RequestAdvisor, none))
	{
		AdjustmentRequests.Length = 0;
		goto J0x98;
		i = 0;
		// End:0x98
		if(__NFUN_150__(i, AdjustmentRequests.Length))
		{
		}
		// End:0x8A
		if(__NFUN_114__(AdjustmentRequests[i].Advisor, RequestAdvisor))
		{
			AdjustmentRequests.Remove(i, 1);
			goto J0x98;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x29;
			CalcuateProbability();
			CalcuateCount();
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xC9
			/*@Error*/
			AdjustmentStopped();
		}
		return;
		@NULL
	}
	J0x98:

	Item
	Item
	@NULL
}

function bool IsActive()
{
	return __NFUN_130__(__NFUN_176__(__NFUN_195__(), CurrentProbability), __NFUN_132__(__NFUN_150__(CurrentCount, MaxCount), __NFUN_154__(MaxCount, 0)));
	return;
	@NULL
	Item
	Item
	@NULL
}
