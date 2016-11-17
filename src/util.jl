"""
Takes a given filename and returns its extension
"""
function extension(path)
    return split(path, '.')[end]
end


"""
gives the .mrbl dir
"""
mrbldir() = "$(ENV["HOME"])/.mrbl"
mrbldir(path) = "$(mrbldir())/$path"


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
