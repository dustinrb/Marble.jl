"""
Simplification of MarbleDoc constructor
"""
function get_doc(contents, path, docname; cache=nothing)
    # Configure the build env
    settings = get_settings(path)
    create_paths(settings)
    cache = cache == nothing ? States("$(settings["paths"]["cache"])/hashes.json") : cache

    return Marble.MarbleDoc(
        docname,
        contents,
        cache,
        settings)
end


"""
Builds document with Marble
"""
function build(contents, path, docname; build::Bool=true, cache=nothing)

    doc = get_doc(contents, path, docname; cache=cache)

    # Build the document
    Marble.parse(doc)
    Marble.process(doc)
    Marble.render(doc)
    Marble.template(doc)
    build && Marble.build(doc)

    return doc
end


"""
Given a directory, compiles all documents under the documents settings
"""
function build_dir(path)
    settings = get_settings(path)
    cache

    # Check to see if both .md and .tex file is changed
    # Backup changes

    # Compile .tex if new .md
    # Compile .pdf if new .tex (and target is pdf)
end


"""
Given a file, creates a build environment in .mrbl and creates a .pdf or .tex
"""
function build_file(file; fmt=:pdf, out=nothing)

    doc = build(
        readstring(file),
        mrbldir("files/$(bytes2hex(sha1(abspath(file))))"),
        split(get_basename(file), "/")[end];
        build=(fmt==:pdf))

    out_path = out == nothing ? "$(pwd())/$(doc.docname).pdf" : out
    isdir(out_path) && error("$out_path is an existing directory")

    # Move to the desired directory
    try
        mv(get_out_doc(doc, fmt), out_path, remove_destination=true)
    catch y
        !isa(y, Base.UVError) && rethrow(y)
    end
end


"""
Given a stream (for example, STDIN), outputes to a stream (for example STDOUT)
TODO: Properly change output with `redirect_stdout`
https://thenewphalls.wordpress.com/2014/03/21/capturing-output-in-julia/
"""
function build_stream(streamin, streamout; fmt=:pdf)
    doc = build(
        readstring(streamin),
        mrbldir("streams/$(string(Base.Random.uuid4()))"),
        "stream";
        build=(fmt==:pdf))

    write(streamout, readstring(get_out_doc(doc, fmt)))
end


"""
Given a path, creates a Marble compatable directory
"""
function init_dir(path; template="", project_name="")
    ispath(path) && error("Path `$path` is an existing directory.")

    settings = get_settings(path)
    project_name = isempty(project_name) ? split(settings["paths"]["base"], '/')[end] : project_name
    p_templates = mrbldir("project_templates")

    create_paths(settings)

    if !isempty(template) &&
        if template in readdir(p_templates)
            for f in readdir(joinpath(p_templates, template))
                cp(joinpath(p_templates, template, f),
                    joinpath(path, f);
                    remove_destination=true)
            end
        else
            error("Project template `$template` not found in $(mrbldir("project_templates"))")
        end
    else
        touch(joinpath(path, "$(get).md"))
    end
end


"""
Create a settings environment
"""
function get_settings(path; runtime_settings=Dict())
    println("Loading settings... ") # LOGGING
    s = SettingsBundle()
    load_conf_file!(s, "$(Pkg.dir("Marble"))/defaults.yaml") # Defaults
    load_conf_file!(s, "$(ENV["HOME"])/.mrbl/settings.yaml") # User settings
    add!(s, Dict("paths"=>get_paths(path))) # Settings Path
    add!(s, runtime_settings)
    load_conf_file!(s, "$path/settings.yaml") # Project Settings
    return s
end


"""
Gives the working directory for a given MRBL documents (except for streams)
returns nothing if document cannot be build by MRBL and is not garunteed to
to be an actual directory
"""
function get_build_dir(path)
    if isfile(path)
        return mrbldir("files/$(bytes2hex(sha1(abspath(path))))")
    elseif ispath(path)
        return abspath(path) # Need to check if this is a valid file
    else
        return nothing
    end
end


"""
Takes a MRBL file/folder and clears out the mrbl/build dir for a clean build
TODO: Should make env cleanable. For now, just clean out the directory
"""
function clean_tex(path)
    p = joinpath(get_build_dir(path), "mrbl", "build")
    rm(p, force=true, recursive=true)
    mkpath(p)
end


"""
Creates a path based based on a buildpath
"""
function get_paths(path)
    env = abspath("$path/mrbl")
    return Dict(
        "base" => abspath(path),
        "env" => env,
        "build" => "$env/build",
        "cache" => "$env/cache",
        "log" => "$env/log",
        "backup" => "$env/backup",
        "template" => "$env/templates",
    )
end


"""
Gets the appropriate output path for a given file format
"""
function get_out_doc(env::MarbleDoc, fmt::Symbol)::String
    if fmt == :pdf
        return "$(env.settings["paths"]["build"])/$(env.docname).pdf"
    elseif fmt == :tex
        return "$(env.settings["paths"]["base"])/$(env.docname).tex"
    else
        error("Unknown output format $fmt")
    end
end


"""
Create the paths in a settings environment
"""
function create_paths(settings)
    # Create directories
    for path in settings["paths"]
        if !isdir(path.second) && !isfile(path.second)
            mkpath(path.second)
        end
    end

    # Create delinquent files
    for file in (
        "$(settings["paths"]["base"])/settings.yaml",) #Maybe this list will grow
        if !isfile(file)
            touch(file)
        end
    end

    mk_mrbl_dir()
end


"""
Create .mrbl directory
"""
function mk_mrbl_dir()
        create_or_ignore.([
            mrbldir(),
            mrbldir("project_templates"),
            mrbldir("files"),
            mrbldir("streams"),
            mrbldir("templates")
        ])
end


"""
Creates the mrbl dir (if it need to be build)
"""
create_or_ignore(m) = !isdir(m) && !isfile(m) && mkpath(m)
