"""
Acts as a store for build information. Passed around to the important setps
"""
type MarbleDoc
    docname::AbstractString # For loggin and tex output
    settings::SettingsBundle
    raw # The file. The stream. The whatever
    tree::Markdown.MD # Parsed markdown tree
    content::AbstractString # Rendered markdown tree w/o main template
    final::AbstractString # Final document, ready for handoff to another processor

    cache::States # Storage of cached files
    templates::LazyTemplateLoader # Templateing environment
    scratch # Place for individual elements to store and share data while rendering
    # log

    function MarbleDoc(docname, raw, cache, settings)
        templates = LazyTemplateLoader([
                settings["paths"]["template"],
                "$(ENV["HOME"])/.mrbl/templates",
                "$(Pkg.dir("Marble"))/templates"
            ];
            block_start_string=settings["JINJA_block_start_string"],
            block_end_string=settings["JINJA_block_end_string"],
            variable_start_string=settings["JINJA_variable_start_string"],
            variable_end_string=settings["JINJA_variable_end_string"],
            comment_start_string=settings["JINJA_comment_start_string"],
            comment_end_string=settings["JINJA_comment_end_string"],
            keep_trailing_newline=true,
        )

        return new(
            docname,
            settings,
            raw,
            Markdown.MD(),
            "",
            "",
            cache,
            templates,
            Dict())
    end
end

"""
Simplification of MarbleDoc constructor
"""
function Marble.MarbleDoc(contents, path, docname; cache=nothing)
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

############## The Main Build Process ##############


"""
Takes in a MarbleDoc and parses the Markdown in the primary_file setting
"""
function Base.parse(env::MarbleDoc)
    if env.settings["debug"]
        println("PARSING") # LOGGING
    end

    env.scratch[:analysis] = get_analysis(env)
    env.tree = Markdown.parse(env.raw, flavor=:mrbl)
end


"""
Takes and manipulates the freshly parsed Tree
"""
function process(env::MarbleDoc)
    if env.settings["debug"]
        println("PROCESSING") # LOGGING
    end

    # Make any Document tags part of the ENV
    for e in env.tree.content
        if isa(e, Document)
            add!(env.settings, e.data)
        end
    end

    #=
    I don't like this implementation. I would prefere something more like

    # References

    {references}

    where the header does not have any magic meaning
    =#
    ref_ind = 0
    addrefs = false
    walk(env) do e, c, env
        if isa(e, Markdown.Header) &&
            strip(e.text[1]) == env.settings["references_header"]
            ref_ind = c[1]
            addrefs = true
        end
    end
    # replace header with actual element
    if ref_ind != 0
        deleteat!(env.tree.content, ref_ind)
        insert!(env.tree.content, ref_ind, Tex("\\printbibliography\n"))
    end

    # probably side load the processors, e.g. for processor in processors...
    # skip
end


"""
Takes a marble and converst the abstract tree object, and renders
each object to it's corrisponding Latex (could be HTML. Who knows)
"""
function render(env::MarbleDoc)
    if env.settings["debug"]
        println("RENDERING") # LOGGING
    end

    env.content = jinja(env, env.tree)
end


"""
Takes the finished document and puts it into template
"""
function template(env::MarbleDoc)
    if env.settings["debug"]
        println("TEMLATING") # LOGGING
    end

    env.final = JinjaTemplates.render(env.templates, "documents/$(env.settings["template"]).tex";
        settings=flatten(env.settings),
        content=env.content
    )

    # Write to file
    texfile = "$(env.settings["paths"]["base"])/$(get_basename(env)).tex"
    open(texfile, "w") do f
        write(f, env.final)
    end
    # show(env.final)
end


"""
Takes the finished document, and calls a build script (probably lualatex)
"""
function build(env::MarbleDoc)
    if env.settings["debug"]
        println("BUILDING") # LOGGING
    end

    print("Building $(env.docname)... ")

    basename = get_basename(env)
    texfile = "$(env.settings["paths"]["base"])/$(get_basename(env)).tex"
    builddir = relpath(env.settings["paths"]["build"])

    logf = open(joinpath(env.settings["paths"]["log"], "$(get_basename(env))_build.log"), "a")
    errf = open(joinpath(env.settings["paths"]["log"], "$(get_basename(env))_error.log"), "a")
    write(logf, "\nBuild at $(now())\n")
    write(errf, "\nBuild at $(now())\n")

    if env.settings["topdf"]
        try
            runindir(builddir) do
                run(pipeline(`latexmk -$(env.settings["texcmd"]) -shell-escape -halt-on-error $(env.settings["paths"]["base"])/$(env.docname).tex`; stdout=logf, stderr=errf))
            end
            println("DONE")
        catch y
            print_with_color(:red, "BUILD FAILED: ")
            println("See $(abspath(env.settings["paths"]["log"]))/$(basename)_error.log for details.")
            return
        finally
          close(logf)
          close(errf)
        end
    end
end

############## The Supporting Functions ##############
"""
Run the analysis CMD specified in the `analysis` command
"""
function get_analysis(env)
    # Execute the analysis script.
    if "analysis" in keys(env.settings)
        a_file = env.settings["analysis"]

        # Use cached settings if analysis.jl is up to date
        if changed(env.cache, a_file)
            # Get the executable command
            exec =  map(split(env.settings["analysiscmd"], ' ')) do command
                if command == "\$filename"
                    return a_file
                else
                    return command
                end
            end

            try
                out = JSON.parse(readstring(`$exec`))
                open(f->JSON.print(f, env.scratch[:analysis]),
                    "$(env.settings["cachedir"])/analysis.json",
                    "w")
            catch y
                out = Dict()
                warn("Analysis script `$(env.settings["analysis"])` failed to run.")
                println(y)
            end
            pin!(env.cache, a_file)
        else
            println("Using cached analysis file")
            out = JSON.parsefile("$(env.settings["cachedir"])/analysis.json")
        end
    end
    return nothing
end

"""
Needs to add support for inlines and nested block elements
NEEDS TO MAKE A COPY OF THE TREE, OR ELSE WALKING GETS WIERD

f should accept e, c, env::MarbleEnv
e → The element itself
c → The coordinates for this element (array of indicies)
env → The tree itself
"""
function walk(f::Function, env::MarbleDoc)
    for i in 1:length(env.tree.content)
        n = length(env.tree.content) + 1 - i
        f(env.tree.content[n], (n,), env)
    end
end

"""
Gets a proper basename for the environment
"""
function get_basename(name)
    last_ind = findlast(name, '.')
    last_ind = last_ind == 0 ? length(name) : findlast(name, '.') - 1
    return name[1:last_ind]
end

get_basename(env::MarbleDoc) = get_basename(env.docname)
