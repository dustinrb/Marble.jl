########## DIRECTORIES ##########

"""
gives the .mrbl dir
"""
function mrbldir()
    if "MARBLE_HOME" ∈ keys(ENV) # Would rather use `get_key`, but it doesnt work with ENV
        return "$(ENV["MARBLE_HOME"])"
    else
        return "$(homedir())/.mrbl"
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


########## PATH MANIPULATION  ##########

"""
Removes the file extension from a file or directory
"""
trimext(path) = splitext(path)[1]
trimext(doc::MarbleDoc) = trimext(doc.docname)

"""
Takes a given filename and returns its extension
Trims the leading `.`
"""
ext(path) = splitext(path)[2][2:end]

"""
Create a basename from a given path (filename without extension)
"""
get_basename(path) = splitext(splitdir(path)[2])[1]
get_basename(e::MarbleDoc) = get_basename(e.docname)

# Also use `basename`
# Maybe `dirname`
# splitext, splitdir

"""
Returns whether a document is a Markdown document
Should the default extension be .md or .mrbl
"""
ismarkdown(path, extension=["md"]) = ext(path) ∈ extension ? true : false
ismarkdown(path, s::SettingsBundle) = ismarkdown(path, extension=s["md_extension"])
