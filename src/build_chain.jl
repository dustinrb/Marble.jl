"""
Acts as a store for build information. Passed around to the important setps
"""
type MarbleEnv
    settings::SettingsBundle
    # docs::Array{MarbleDoc}
    tree::Markdown.MD # Parsed markdown tree
    content::AbstractString # Rendered markdown tree w/o templating
    final::AbstractString # Final document, ready for handoff to another processor

    cache::Cache # Storage of cached files
    templates::LazyTemplateLoader # Templateing environment
    scratch # Place for individual elements to store and share data while rendering

    function MarbleEnv(settings_sources...)
        this = new(SettingsBundle(settings_sources...), Markdown.MD(), "", "", Cache("mrbl/cache_list.json"))

        this.templates = LazyTemplateLoader([
                this.settings["templatedir"],
                "$(ENV["HOME"])/.mrbl/templates",
                "$(Pkg.dir("Marble"))/templates"
            ];
            block_start_string=this.settings["JINJA_block_start_string"],
            block_end_string=this.settings["JINJA_block_end_string"],
            variable_start_string=this.settings["JINJA_variable_start_string"],
            variable_end_string=this.settings["JINJA_variable_end_string"],
            comment_start_string=this.settings["JINJA_comment_start_string"],
            comment_end_string=this.settings["JINJA_comment_end_string"],
            keep_trailing_newline=true,
            # trim_blocks=true
        )

        this.scratch = Dict()
        return this
    end
end

type MarbleDoc

end

"""
Takes in a MarbleEnv and parses the Markdown in the primary_file setting
"""
function Base.parse(env::MarbleEnv)
    if env.settings["debug"]
        println("PARSING") # LOGGING
    end


    # Execute the analysis script. This will give it a chance to create any CSVs
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
                env.scratch[:analysis] = JSON.parse(readall(`$exec`))
                open(f->JSON.print(f, env.scratch[:analysis]),
                    "mrbl/cache/analysis.json",
                    "w")
            catch y
                # throw(y)
                env.scratch[:analysis] = Dict()
                warn("Analysis script `$(env.settings["analysis"])` failed to run.")
                println(y)
            end
            cache(env.cache, a_file)
            save(env.cache)
        else
            println("Using cached analysis file")
            env.scratch[:analysis] = JSON.parsefile("mrbl/cache/analysis.json")
        end
    end

    # Make sure they provide us with a valid file
    path = "$(env.settings["workdir"])/$(env.settings["maindoc"])"
    if !isfile(path)
        error("`$path` does not exist. Create it, or change the 'maindoc' setting in this project's settings.yaml")
    end

    env.tree = Markdown.parse_file(path, flavor=:mrbl)
end

"""
Takes and manipulates the freshly parsed Tree
"""
function process(env::MarbleEnv)
    if env.settings["debug"]
        println("PROCESSING") # LOGGING
    end

    # Make any Document tags part of the ENV
    walk(env) do e, c, env
        if isa(e, Document)
            add!(env.settings, env.tree.content[c[1]].data)
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
    deleteat!(env.tree.content, ref_ind)
    insert!(env.tree.content, ref_ind, Tex("\\printbibliography\n"))

    # probably side load the processors, e.g. for processor in processors...
    # skip
end

"""
Needs to add support for inlines and nested block elements
NEEDS TO MAKE A COPY OF THE TREE, OR ELSE WALKING GETS WIERD

f should accept e, c, env::MarbleEnv
e → The element itself
c → The coordinates for this element (array of indicies)
env → The tree itself
"""
function walk(f::Function, env::MarbleEnv)
    for i in 1:length(env.tree.content)
        n = length(env.tree.content) + 1 - i
        f(env.tree.content[n], (n,), env)
    end
end

"""
Takes a marble and converst the abstract tree object, and renders
each object to it's corrisponding Latex (could be HTML. Who knows)
"""
function render(env::MarbleEnv)
    if env.settings["debug"]
        println("RENDERING") # LOGGING
    end

    env.content = jinja(env, env.tree)
end

"""
Takes the finished document and puts it into template
"""
function template(env::MarbleEnv)
    if env.settings["debug"]
        println("TEMLATING") # LOGGING
    end

    env.final = JinjaTemplates.render(env.templates, "documents/$(env.settings["template"]).tex";
        settings=flatten(env.settings),
        content=env.content
    )

    # Write to file
    texfile = "$(get_basename(env)).tex"
    open(texfile, "w") do f
        write(f, env.final)
    end
    # show(env.final)
end

"""
Takes the finished document, and calls a build script (probably Xelatex)
"""
function build(env::MarbleEnv)
    if env.settings["debug"]
        println("BUILDING") # LOGGING
    end

    basename = get_basename(env)
    texfile = "$basename.tex"
    if env.settings["topdf"]
        try
            # run(`latexmk -xelatex -shell-escape -halt-on-error -jobname=build/$basename $texfile`)
            run(pipeline(`latexmk -xelatex -shell-escape -halt-on-error -jobname=build/$basename $texfile`; stdout=DevNull, stderr=DevNull))
            println("DONE")
        catch y
            print_with_color(:red, "BUILD FAILED: ")
            println("See build/$basename.log for details.")
        end
    end
end
