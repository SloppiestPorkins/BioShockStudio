namespace BioShockStudio.Core.Packages;

/// <summary>
/// Keeps a few opened packages alive, so asking for the same one twice does not parse its tables twice.
/// </summary>
/// <remarks>
/// <para>
/// <b>Measured, which is why this exists.</b> Opening <c>1-Medical.bsm</c> parses its name, import
/// and export tables in <b>31–46 ms</b> depending on the file cache; reading a payload out of the
/// opened package takes <b>0.001 ms</b>. Every service opened its own, and selecting a texture calls
/// <c>Describe</c> and then <c>Decode</c> — so a click paid twice that for 0.002 ms of reading.
/// From the cache the same open costs <b>0.0001 ms</b>. <c>PerformanceBaselineTests</c> holds the
/// figures and asserts the saving as a ratio, so it means the same thing on a slower machine.
/// </para>
/// <para>
/// <b>A lease, not a handle.</b> Callers keep their <c>using</c> — the lease's <c>Dispose</c>
/// returns the package rather than closing it.
/// </para>
/// <para>
/// <b>Bounded, least-recently-used, and reference-counted.</b> The cache holds
/// <see cref="Capacity"/> packages and evicts the coldest. Eviction does <i>not</i> close a package
/// somebody is still holding: the entry leaves the cache and the file closes when the last lease is
/// returned. Without that, a service holding a lease across a long operation — the details panel
/// does — would read from a closed file as soon as four other packages were touched, which is a
/// crash rather than a slowdown.
/// </para>
/// <para>
/// <b>Payload bytes are never cached.</b> A read is already a thousandth of a millisecond, and
/// caching hundreds of megabytes of mesh data to save that would buy nothing with memory this
/// project deliberately watches.
/// </para>
/// </remarks>
public sealed class PackageCache : IDisposable
{
    /// <summary>How many opened packages to keep. Four covers a browse, a preview and an export.</summary>
    public const int Capacity = 4;

    internal sealed class Entry(BioShockPackage package)
    {
        public BioShockPackage Package { get; } = package;
        public int Leases;
        public bool Evicted;
    }

    private readonly Dictionary<string, Entry> _open = new(StringComparer.OrdinalIgnoreCase);
    private readonly LinkedList<string> _order = new();
    private readonly object _gate = new();
    private bool _disposed;

    /// <summary>How many times a request was served without opening the file. Diagnostic.</summary>
    public int Hits { get; private set; }

    /// <summary>How many times a request had to open the file. Diagnostic.</summary>
    public int Misses { get; private set; }

    /// <summary>Packages currently held open. At most <see cref="Capacity"/>, plus any still leased.</summary>
    public int Count
    {
        get { lock (_gate) return _open.Count; }
    }

    /// <summary>
    /// Borrows the package at <paramref name="path"/>, opening it only if it is not already held.
    /// </summary>
    public Lease Rent(string path)
    {
        lock (_gate)
        {
            ObjectDisposedException.ThrowIf(_disposed, this);

            if (_open.TryGetValue(path, out var cached))
            {
                Hits++;
                Touch(path);
                cached.Leases++;
                return new Lease(this, cached);
            }
        }

        // Opened outside the lock: parsing tables takes tens of milliseconds, and holding the lock
        // across it would serialise every other package's reads behind this one.
        var opened = BioShockPackage.Open(path);

        lock (_gate)
        {
            if (_disposed)
            {
                opened.Dispose();
                throw new ObjectDisposedException(nameof(PackageCache));
            }

            // Another thread may have opened the same package meanwhile. Keep the one already in
            // the cache so that everybody shares one instance.
            if (_open.TryGetValue(path, out var raced))
            {
                opened.Dispose();
                Hits++;
                Touch(path);
                raced.Leases++;
                return new Lease(this, raced);
            }

            Misses++;
            var entry = new Entry(opened) { Leases = 1 };
            _open[path] = entry;
            _order.AddFirst(path);
            EvictWhileOverCapacity();
            return new Lease(this, entry);
        }
    }

    /// <summary>Closes everything not currently leased; the rest close as their leases return.</summary>
    public void Dispose()
    {
        lock (_gate)
        {
            if (_disposed) return;
            _disposed = true;

            foreach (var entry in _open.Values)
            {
                entry.Evicted = true;
                if (entry.Leases == 0) entry.Package.Dispose();
            }

            _open.Clear();
            _order.Clear();
        }
    }

    private void Return(Entry entry)
    {
        lock (_gate)
        {
            entry.Leases--;
            if (entry.Leases <= 0 && entry.Evicted) entry.Package.Dispose();
        }
    }

    private void Touch(string path)
    {
        _order.Remove(path);
        _order.AddFirst(path);
    }

    private void EvictWhileOverCapacity()
    {
        while (_order.Count > Capacity)
        {
            string coldest = _order.Last!.Value;
            _order.RemoveLast();

            if (!_open.Remove(coldest, out var entry)) continue;

            entry.Evicted = true;
            if (entry.Leases == 0) entry.Package.Dispose();
        }
    }

    /// <summary>A borrowed package. Disposing it returns it to the cache rather than closing it.</summary>
    public readonly struct Lease : IDisposable
    {
        private readonly PackageCache? _cache;
        private readonly Entry? _entry;

        internal Lease(PackageCache cache, Entry entry)
        {
            _cache = cache;
            _entry = entry;
        }

        public BioShockPackage Package =>
            _entry?.Package ?? throw new InvalidOperationException("This lease holds no package.");

        public static implicit operator BioShockPackage(Lease lease) => lease.Package;

        public void Dispose()
        {
            if (_cache is not null && _entry is not null) _cache.Return(_entry);
        }
    }
}
