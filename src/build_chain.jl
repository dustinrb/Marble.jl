"""
Acts as a store for build information. Passed around to the important setps
"""
type MarbleEnv
    settings::SettingsBundle
    tree::Markdown.MD # Parsed markdown tree
    content::AbstractString # Rendered markdown tree w/o templating
    final::AbstractString # Final document, ready for handoff to another processor
    is_built::Bool # Did the other processor successfully exicute
    templates # Templateing environment
    skratch # Places for individual elements to store and share data

    MarbleEnv() = new(SettingsBundle(), Markdown.MD(), "", "", false)
end

"""
Takes in a MarbleEnv and parses the Markdown in the primary_file setting
"""
function Base.parse(env::MarbleEnv)
    if env.settings["debug"]
        println("PARSING") # LOGGING
    end

    # Make sure they provide us with a valid file
    path = "$(env.settings["workdir"])/$(env.settings["maindoc"])"
    if isfile(path)
    else
        error("`$path` does not exist. Create it, or change the 'maindoc' setting in this project's settings.yaml")
    end

    env.tree = Markdown.parse_file(path, flavor=:mrbl)

    # show(env.tree)
end

"""
Takes and manipulates the freshly parsed Tree"
"""
function process(env::MarbleEnv)
    if env.settings["debug"]
        println("PROCESSING") # LOGGING
    end

    # Make any Document tags part of the ENV
    for i in 1:length(env.tree.content)
        n = length(env.tree.content) + 1 - i
        if isa(env.tree.content[n], Document)
            println("ADDING DOC")
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

    # pfn(x) = println(get_template_name(x))
    # function pfn(x::Base.Markdown.Paragraph)
    #     println(get_template_name(x))
    #     pfn(x.content)
    # end
    # pfn(x::AbstractArray) = map(pfn, x)
    # pfn(env.tree.content)

    env.content = jinja(env, env.tree)
    # show(env.content)
end

"""
Takes the finished document and puts it into template
"""
function template(env::MarbleEnv)
    if env.settings["debug"]
        println("TEMLATING") # LOGGING
    end

    println("documents/$(env.settings["template"]).tex")
    env.final = render(env.templates, "documents/$(env.settings["template"]).tex";
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
    run(`latexmk -xelatex -shell-escape -jobname=build/$basename $texfile`)
end
