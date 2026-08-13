namespace BioShockStudio.Core.Havok.Animation.SplineCompression;

/// <summary>
/// The NURBS basis Havok uses for spline-compressed tracks: a byte knot vector and a control-point
/// count, evaluated with de Boor's algorithm.
/// <para>
/// CONFIRMED_BYTES: the knot vector is <c>numItems + degree + 2</c> bytes and there are
/// <c>numItems + 1</c> control points. Walking every shipped block with those two rules consumes
/// all 132 blocks of the first-person hands package to the exact byte.
/// </para>
/// </summary>
public sealed class NurbsBasis
{
    private readonly byte[] _knots;

    public int Degree { get; }
    public int ControlPointCount { get; }

    public NurbsBasis(int numItems, int degree, byte[] knots)
    {
        Degree = degree;
        ControlPointCount = numItems + 1;
        _knots = knots;
    }

    /// <summary>Largest knot value, i.e. the last frame this curve describes.</summary>
    public int MaxKnot
    {
        get
        {
            int max = 0;
            foreach (byte k in _knots) if (k > max) max = k;
            return max;
        }
    }

    /// <summary>Knot vector length for a given item count and degree.</summary>
    public static int KnotCount(int numItems, int degree) => numItems + degree + 2;

    /// <summary>
    /// Locates the knot span containing <paramref name="t"/>.
    /// </summary>
    /// <remarks>
    /// Piegl &amp; Tiller A2.1, with <c>n = ControlPointCount - 1</c> and a knot vector of
    /// <c>n + Degree + 2</c> entries, so the curve's domain is <c>[knots[Degree], knots[n + 1]]</c>.
    /// <para>
    /// Both bounds matter and both were wrong. The clamp compared against <c>knots[n]</c> and
    /// returned span <c>n - 1</c>, and the search ran to <c>n</c> rather than <c>n + 1</c> — so the
    /// last knot span was never selected and every sample inside it was evaluated against the
    /// span below, extrapolating a basis outside its own interval. The error grew towards the end of
    /// each block and jumped at the boundary into the next, which on a long animation collapses a
    /// skeleton: <c>Ryan_Speech_B</c> moved a bone 1,159 units between two adjacent frames on a
    /// skeleton 130 units tall.
    /// </para>
    /// </remarks>
    public int FindSpan(float t)
    {
        int n = ControlPointCount - 1;
        if (n <= Degree) return Degree;

        if (t >= _knots[n + 1]) return n;
        if (t <= _knots[Degree]) return Degree;

        int low = Degree;
        int high = n + 1;
        int mid = (low + high) / 2;

        // Bounded so a malformed knot vector cannot spin.
        for (int guard = 0; guard < 64; guard++)
        {
            if (t >= _knots[mid] && t < _knots[mid + 1]) return mid;
            if (t < _knots[mid]) high = mid; else low = mid;
            int next = (low + high) / 2;
            if (next == mid) return mid;
            mid = next;
        }

        return mid;
    }

    /// <summary>
    /// Evaluates the <see cref="Degree"/>+1 non-zero basis functions at <paramref name="t"/> for the
    /// given span. Control point <c>span - Degree + i</c> is weighted by result <c>i</c>.
    /// </summary>
    public float[] BasisFunctions(int span, float t)
    {
        var n = new float[Degree + 1];
        var left = new float[Degree + 1];
        var right = new float[Degree + 1];

        n[0] = 1f;
        for (int j = 1; j <= Degree; j++)
        {
            left[j] = t - _knots[span + 1 - j];
            right[j] = _knots[span + j] - t;

            float saved = 0f;
            for (int r = 0; r < j; r++)
            {
                float denominator = right[r + 1] + left[j - r];
                float temp = denominator != 0f ? n[r] / denominator : 0f;
                n[r] = saved + right[r + 1] * temp;
                saved = left[j - r] * temp;
            }
            n[j] = saved;
        }

        return n;
    }

    /// <summary>Weights of each control point at time <paramref name="t"/>, as (index, weight) pairs.</summary>
    public IEnumerable<(int Index, float Weight)> Weights(float t)
    {
        int span = FindSpan(t);
        float[] basis = BasisFunctions(span, t);

        for (int i = 0; i <= Degree; i++)
        {
            int index = span - Degree + i;
            if (index >= 0 && index < ControlPointCount)
                yield return (index, basis[i]);
        }
    }
}
