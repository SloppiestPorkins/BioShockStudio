class DifficultyAdvisor extends Object
	abstract
	native
	config(Difficulty);

struct native atomic AdjustmentRecommendation
{
	var Class<DifficultyAdjustment> AdjustmentClass;
	var name ProbabilityTableName;
	var int Count;
	var int Priority;
	var float Weight;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var config array<AdjustmentRecommendation> AdjustmentRecommendations;
var private DifficultyEvaluator DifficultyEvaluator;
var private config Class<DifficultyEvaluator> DifficultyEvaluatorClass;
var private config name DifficultyEvaluatorName;
var private config int CreditsNeededToBeConsideredRich;
var private config string AdvisorCategory;
var private float EaseValue;
var private transient DifficultyManager DifficultyManager;

function Construct(DifficultyManager DifficultyManager)
{
	self.DifficultyManager = DifficultyManager;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x64
	/*@Error*/
	DifficultyEvaluator = DifficultyEvaluatorClass.static.Allocate(self,, string(DifficultyEvaluatorName)).;
	Construct_Void();
	return;
	@NULL
	Item
	Vector
	@NULL
}

function int Assess(ShockPlayer Player)
{
	local int BaseEaseValue;

	EaseValue = float(AssessInternal(Player, BaseEaseValue));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE8
	/*@Error*/
	// End:0xAC
	if(__NFUN_130__(__NFUN_150__(BaseEaseValue, 0), __NFUN_153__(Player.GetCredits(), CreditsNeededToBeConsideredRich)))
	{
		DifficultyManager.GetGameDriver().GetPlayerStatsManager().WeakButRich(AdvisorCategory);
		goto J0xE8;
		DifficultyManager.GetGameDriver().GetPlayerStatsManager().NotWeakButRich(AdvisorCategory);
	}
	return int(EaseValue);
	return;
	@NULL
	Freebie
	Item
	@NULL
}

protected function int AssessInternal(ShockPlayer Player, out int BaseEase)
{
	return;
}

function float GetEaseValue()
{
	return EaseValue;
	return;
	@NULL
}

function AdjustmentRecommendation GetRecommendedAdjustment()
{
	local float TotalWeight;
	local int i;
	local AdjustmentRecommendation emptyRecommendataion;

	i = 0;
	// End:0x110
	if(__NFUN_150__(i, AdjustmentRecommendations.Length))
	{
		// End:0x94
		if(__NFUN_130__(__NFUN_176__(AdjustmentRecommendations[i].Weight, float(0)), __NFUN_176__(EaseValue, float(0))))
		{
			__NFUN_185__(TotalWeight, AdjustmentRecommendations[i].Weight);
			goto J0x102;
			// End:0x102
			if(__NFUN_130__(__NFUN_177__(AdjustmentRecommendations[i].Weight, float(0)), __NFUN_177__(EaseValue, float(0))))
			{
				__NFUN_184__(TotalWeight, AdjustmentRecommendations[i].Weight);
			}
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0x0B;
			TotalWeight = __NFUN_171__(__NFUN_195__(), TotalWeight);
			log('DifficultyAdvisor', 4, __NFUN_112__(__NFUN_112__("Choosing recommendation using ", string(TotalWeight)), " as weight"));
		}
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x36C
		/*@Error*/
	}
	else
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x27B
		/*@Error*/
		__NFUN_184__(TotalWeight, AdjustmentRecommendations[i].Weight);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x278
		/*@Error*/
		log('DifficultyAdvisor', 4, __NFUN_112__("Choosing ", string(AdjustmentRecommendations[i].AdjustmentClass.Name)));
		return AdjustmentRecommendations[i];
		goto J0x35E;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x35E
		/*@Error*/
		__NFUN_185__(TotalWeight, AdjustmentRecommendations[i].Weight);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x35E
		/*@Error*/
		log('DifficultyAdvisor', 4, __NFUN_112__("Choosing ", string(AdjustmentRecommendations[i].AdjustmentClass.Name)));
		return AdjustmentRecommendations[i];
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x17D;
		return emptyRecommendataion;
		return;
		@NULL
		Item
		Item
		@NULL
	}
}
