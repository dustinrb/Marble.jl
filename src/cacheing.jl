# Rhudametry implementation of the caching protocol
# module Cacheing
#
# using JSON
#
# export Cache, cache, cache!, save, changed

"""
Entry for our caching table.
"""
type Cache
    cachepath::AbstractString # Path to file where cache data is stored
    lookup::Dict{UTF8String, ASCIIString}
    function Cache(fname)
        fpath = abspath(fname)
        try
            lookup = JSON.parsefile(fpath)
            return new(fpath, lookup)
        catch e
            if isa(e, ArgumentError)
                error("$fname exists, but is not valud JSON")
                exit(1)
            elseif isa(e, SystemError)
                c = new(fpath, Dict{UTF8String, ASCIIString}())
                save(c)
                return c
            else
                throw(e)
            end
        end
    end
end

"Adds file to cache or updates existing entry"
cache(c::Cache, f) = c[f] = open(sha1, f)

"Addes flie to cache, and updates the cachefile"
function cache!(c::Cache, f)
    shasum = cache(c, f)
    save(c)
    return shasum
end

"Saves cache database to file"
save(c::Cache) = open(o -> JSON.print(o, c.lookup), c.cachepath, "w")

Base.getindex(collection::Cache, key) = collection.lookup[abspath(key)]

Base.setindex!(collection::Cache, value, key) = collection.lookup[abspath(key)] = value

"""
Given a filename and a cache, tells user if cache is still valid
"""
function changed(c::Cache, fname)
    try
        return open(sha1, fname) != c[fname]
    catch y
        return isa(y, KeyError) ? true : throw(y)
    end
end

# end # module