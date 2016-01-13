include("templating.jl")

""" Renders a given element tree by passing elements thru Jinja tempaltes """
function jinja(env, md::Markdown.MD)
    env.templates = LazyTemplateLoader(env)

    # return render(l, "elements/latex/Paragraph.tex"; paragraph="Paragraph")
    stream = IOBuffer()
    for element in md.content
        println(stream, jinja(env, element))
    end
    text = readall(seek(stream, 0))
    return text
end

jinja(env, md::AbstractString) = Markdown.latexesc(md)
jinja(env, md::Number) = string(md)
jinja(env, md::Array) = join([jinja(env, i) for i in md], "")

function jinja(env, md)
    fields = Dict{Symbol, Any}()
    for i in fieldnames(md)
        fields[i] = jinja(env, getfield(md, i))
    end
    return render(env.templates, "elements/latex/$(get_template_name(md)).tex"; settings=flatten(env.settings), fields...)
end

# Elements which need special attention
jinja(env, md::Marble.Document) = ""

function jinja(env, md::Base.Markdown.List)
    listitems = map(md.items) do item
        return jinja(env, item)
    end
    return render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=flatten(env.settings),
        ordered=md.ordered,
        items=listitems)
end

jinja(env, md::Base.Markdown.Code) = render(
    env.templates,
    "elements/latex/$(get_template_name(md)).tex";
    settings=flatten(env.settings),
    language=md.language,
    code=md.code
    )

function jinja(env, md::Base.Markdown.Table)
    rows = map(md.rows) do row
        return [jinja(env, col) for col in row]
    end
    headers = rows[1]
    content = rows[2:end]
    alignment = map(md.align) do a
        if a == :l
            return "left"
        elseif a == :r
            return "right"
        else
            return "center"
        end
    end
    return render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=flatten(env.settings),
        headers = headers,
        content = content,
        alignment = alignment)
end

function jinja(env, md::Marble.Table)
    # TODO: Decide if we want latex or MD inlines within tabels
    # content = map(md.content) do row
    #     return [jinja(env, col) for col in row]
    # end
    # headers = map(md.headers) do row
    #     return [jinja(env, col) for col in row]
    # end
    return render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=flatten(env.settings),
        path=md.path,
        name=md.name,
        content=md.content,
        caption=jinja(env, md.caption),
        headers=md.headers,
        alignment=md.alignment)
end

function jinja(env, md::Marble.Equation)
    return render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=flatten(env.settings),
        name=md.name,
        content=md.content)
end

function jinja(env, md::Marble.InlineCite)
    return render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=flatten(env.settings),
        sources=md.sources)
end

function jinja(env, md::Marble.InlineUnit)
    return render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=flatten(env.settings),
        units=md.units)
end

function jinja(env, md::Marble.InlineData)
    return render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=flatten(env.settings),
        text=md.text,
        format=md.format)
end

function jinja(env, md::Marble.Tex)
    return return render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=flatten(env.settings),
        content=md.content)
end