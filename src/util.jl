"""
Takes a given filename and returns its extension
"""
function extension(path)
    return split(path, '.')[end]
end


"""
gives the .mrbl dir
"""
function mrbldir()
    if "MARBLE_HOME" ∈ keys(ENV) # Would rather use `get_key`, but it doesnt work with ENV
        return "$(ENV["MARBLE_HOME"])"
    else
        return "$(ENV["HOME"])/.mrbl"
    end
end
mrbldir(path...) = joinpath(mrbldir(), path...)


"""
Runs code snippets within the specified directory.
Due to the changeing directories, beware of relatvie paths
"""
function runindir(f::Function, path)
    curdir = pwd()
    cd(path)
    output = nothing
    try
        output = f()
    finally
        cd(curdir)
    end
    return output
end
