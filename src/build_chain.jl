"""
Acts as a store for build information. Passed around to the important setps
"""
type MarbleEnv
    settings::SettingsBundle
    tree::Markdown.MD # Parsed markdown tree
    content::AbstractString # Rendered markdown tree w/o templating
    final::AbstractString # Final document, ready for handoff to another processor
    is_built::Bool # Did the other processor successfully exicute
    templates::LazyTemplateLoader # Templateing environment
    scratch # Place for individual elements to store and share data while rendering

    function MarbleEnv(settings_sources...)
        this = new(SettingsBundle(settings_sources...), Markdown.MD(), "", "", false)

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

"""
Takes in a MarbleEnv and parses the Markdown in the primary_file setting
"""
function Base.parse(env::MarbleEnv)
    if env.settings["debug"]
        println("PARSING") # LOGGING
    end

    # Execute the analysis script. This will give it a chance to create any CSVs
    if "analysis" in keys(env.settings)
        try
            exec =  map(split(env.settings["analysiscmd"], ' ')) do command
                println(command)
                if command == "\$filename"
                    return env.settings["analysis"]
                else
                    return command
                end
            end
            env.scratch[:analysis] = JSON.parse(readall(`$exec`))
        catch y
            # throw(y)
            env.scratch[:analysis] = Dict()
            warn("Analysis script `$(env.settings["analysis"])` failed to run.")
            println(y)
        end
    end

    # Make sure they provide us with a valid file
    path = "$(env.settings["workdir"])/$(env.settings["maindoc"])"
    if !isfile(path)
        error("`$path` does not exist. Create it, or change the 'maindoc' setting in this project's settings.yaml")
    end

    env.tree = Markdown.parse_file(path, flavor=:mrbl)

    # show(env.tree)
end

"""
Takes and manipulates the freshly parsed Tree
"""
function process(env::MarbleEnv)
    if env.settings["debug"]
        println("PROCESSING") # LOGGING
    end

    # Make any Document tags part of the ENV
    for i in 1:length(env.tree.content)
        n = length(env.tree.content) + 1 - i
        if isa(env.tree.content[n], Document)
            add!(env.settings, env.tree.content[n].data)
        end
    end

    # probably side load the processors, e.g. for processor in processors...
    # skip
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

    # show(env.final)
end

"""
Takes the finished document, and calls a build script (probably Xelatex)
"""
function build(env::MarbleEnv)
    if env.settings["debug"]
        println("BUILDING") # LOGGING
    end

    basename = env.settings["maindoc"][1:findlast(env.settings["maindoc"], '.') - 1]

    texfile = "$basename.tex"
    open(texfile, "w") do f
        write(f, env.final)
    end

    try
        run(`latexmk -xelatex -shell-escape -jobname=build/$basename $texfile`)
        println("DONE")
    catch y
        println("BUILD FAILED")
    end
end
