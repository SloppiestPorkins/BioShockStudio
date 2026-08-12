namespace BioShockStudio.Core.Packages;

/// <summary>
/// Read-only sliding window over a region of an underlying seekable stream, so an export payload can
/// be parsed without copying it out of a multi-hundred-megabyte package.
/// </summary>
public sealed class WindowStream : Stream
{
    private readonly Stream _inner;
    private readonly long _origin;
    private readonly long _length;
    private long _position;

    public WindowStream(Stream inner, long origin, long length)
    {
        _inner = inner;
        _origin = origin;
        _length = length;
    }

    public override bool CanRead => true;
    public override bool CanSeek => true;
    public override bool CanWrite => false;
    public override long Length => _length;

    public override long Position
    {
        get => _position;
        set => _position = value;
    }

    public override int Read(byte[] buffer, int offset, int count) => Read(buffer.AsSpan(offset, count));

    public override int Read(Span<byte> buffer)
    {
        long remaining = _length - _position;
        if (remaining <= 0) return 0;
        if (buffer.Length > remaining) buffer = buffer[..(int)remaining];

        _inner.Position = _origin + _position;
        int read = _inner.Read(buffer);
        _position += read;
        return read;
    }

    public override long Seek(long offset, SeekOrigin origin)
    {
        _position = origin switch
        {
            SeekOrigin.Begin => offset,
            SeekOrigin.Current => _position + offset,
            SeekOrigin.End => _length + offset,
            _ => throw new ArgumentOutOfRangeException(nameof(origin)),
        };
        return _position;
    }

    public override void Flush() { }
    public override void SetLength(long value) => throw new NotSupportedException();
    public override void Write(byte[] buffer, int offset, int count) => throw new NotSupportedException();

    protected override void Dispose(bool disposing)
    {
        if (disposing) _inner.Dispose();
        base.Dispose(disposing);
    }
}
