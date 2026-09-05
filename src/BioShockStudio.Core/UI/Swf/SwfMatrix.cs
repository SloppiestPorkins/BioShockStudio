namespace BioShockStudio.Core.UI.Swf;

/// <summary>
/// SWF MATRIX: 2D affine transform, x' = ScaleX*x + RotateSkew1*y + TranslateX (twips),
/// y' = RotateSkew0*x + ScaleY*y + TranslateY. Scale/rotate values are FB (signed fixed-point,
/// 16.16); translate values are already twips (no fixed-point).
/// </summary>
public readonly record struct SwfMatrix(double ScaleX, double RotateSkew0, double RotateSkew1, double ScaleY, double TranslateX, double TranslateY)
{
    public static readonly SwfMatrix Identity = new(1, 0, 0, 1, 0, 0);

    public (double X, double Y) Apply(double x, double y) =>
        (ScaleX * x + RotateSkew1 * y + TranslateX, RotateSkew0 * x + ScaleY * y + TranslateY);

    /// <summary>Compose so that applying the result equals applying `this` then `outer`
    /// (i.e. `outer` is the parent/ancestor transform, `this` is the child's own).</summary>
    public SwfMatrix Then(SwfMatrix outer) => new(
        ScaleX: outer.ScaleX * ScaleX + outer.RotateSkew1 * RotateSkew0,
        RotateSkew0: outer.RotateSkew0 * ScaleX + outer.ScaleY * RotateSkew0,
        RotateSkew1: outer.ScaleX * RotateSkew1 + outer.RotateSkew1 * ScaleY,
        ScaleY: outer.RotateSkew0 * RotateSkew1 + outer.ScaleY * ScaleY,
        TranslateX: outer.ScaleX * TranslateX + outer.RotateSkew1 * TranslateY + outer.TranslateX,
        TranslateY: outer.RotateSkew0 * TranslateX + outer.ScaleY * TranslateY + outer.TranslateY);
}

public static class SwfMatrixReader
{
    public static SwfMatrix Read(ref SwfBitReader bits)
    {
        double scaleX = 1, scaleY = 1;
        if (bits.ReadUnsigned(1) != 0)
        {
            int n = (int)bits.ReadUnsigned(5);
            scaleX = bits.ReadSigned(n) / 65536.0;
            scaleY = bits.ReadSigned(n) / 65536.0;
        }
        double rotateSkew0 = 0, rotateSkew1 = 0;
        if (bits.ReadUnsigned(1) != 0)
        {
            int n = (int)bits.ReadUnsigned(5);
            rotateSkew0 = bits.ReadSigned(n) / 65536.0;
            rotateSkew1 = bits.ReadSigned(n) / 65536.0;
        }
        int nTranslate = (int)bits.ReadUnsigned(5);
        double tx = bits.ReadSigned(nTranslate);
        double ty = bits.ReadSigned(nTranslate);
        return new SwfMatrix(scaleX, rotateSkew0, rotateSkew1, scaleY, tx, ty);
    }
}
