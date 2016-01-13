using PyCall
@pyimport jinja2

""" Object to store in memory PyObjects representing Jinja templates """
type LazyTemplateLoader
    jinjaenv
    templates

    function LazyTemplateLoader(env)
        new(mkjinjaenv(env), Dict())
    end
end

""" Creates a Jinja2 ENV based on the settings ENV """
function mkjinjaenv(env::MarbleEnv)
    return jinja2.Environment(
        loader=jinja2.FileSystemLoader([
            env.settings["templatedir"],
            "$(ENV["HOME"])/.mrbl/templates",
            "$(Pkg.dir("Marble"))/templates"
        ]),
        block_start_string=env.settings["JINJA_block_start_string"],
        block_end_string=env.settings["JINJA_block_end_string"],
        variable_start_string=env.settings["JINJA_variable_start_string"],
        variable_end_string=env.settings["JINJA_variable_end_string"],
        comment_start_string=env.settings["JINJA_comment_start_string"],
        comment_end_string=env.settings["JINJA_comment_end_string"],
        keep_trailing_newline=true
    )
end

""" Returns a jinja template. Onload loads the tempalte once requested """
function Base.getindex(loader::LazyTemplateLoader, key)
    try
        return loader.templates[key]
    catch x
        if isa(x, KeyError)
            loader.templates[key] = loader.jinjaenv[:get_template](key)
            return loader.templates[key]
        else
            throw(x)
        end
    end
end

""" Takes a variable and converts its type into a string fit for the filesystem """
function get_template_name(item)
    t = string(typeof(item))
    return replace(t, r"[^\w\.]", s"_")
end

""" Renders given kwargs into the specified tempalte """
function render(loader::LazyTemplateLoader, template::AbstractString; kwargs...)
    template = loader[template]
    return template[:render](; kwargs...)
end

render(loader::LazyTemplateLoader, obj; kwargs...) = render(loader, "$get_template_name(obj).tex"; kwargs...) # TODO: Make file extension dependant on settings
