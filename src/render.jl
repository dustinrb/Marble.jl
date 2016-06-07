using JinjaTemplates
""" JinjaTemplates.renders a given element tree by passing elements thru Jinja Templates """
function jinja(env, md::Markdown.MD)
    env.scratch[:settings_cache] = flatten(env.settings)
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
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex"; settings=env.scratch[:settings_cache], fields...)
end

# Elements which need special attention
jinja(env, md::Marble.Document) = ""

function jinja(env, md::Base.Markdown.List)
    listitems = map(md.items) do item
        return jinja(env, item)
    end
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=env.scratch[:settings_cache],
        ordered=md.ordered,
        items=listitems)
end

jinja(env, md::Base.Markdown.Code) = JinjaTemplates.render(
    env.templates,
    "elements/latex/$(get_template_name(md)).tex";
    settings=env.scratch[:settings_cache],
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
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=env.scratch[:settings_cache],
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
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=env.scratch[:settings_cache],
        path=md.path,
        name=md.name,
        content=md.content,
        caption=jinja(env, md.caption),
        headers=md.headers,
        alignment=md.alignment)
end

function jinja(env, md::Marble.Figure)
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=env.scratch[:settings_cache],
        name=md.name,
        path=md.path,
        caption=jinja(env, md.caption),
        tex=md.tex)
end

function jinja(env, md::Marble.Equation)
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=env.scratch[:settings_cache],
        name=md.name,
        content=md.content)
end

function jinja(env, md::Marble.Tex)
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=env.scratch[:settings_cache],
        content=md.content)
end

function jinja(env, md::Marble.InlineCite)
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=env.scratch[:settings_cache],
        sources=md.sources)
end

function jinja(env, md::Marble.InlineUnit)
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=env.scratch[:settings_cache],
        units=md.units)
end

function jinja(env, md::Marble.InlineData)
    text = format(md.format, env.scratch[:analysis][md.text])
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=env.scratch[:settings_cache],
        text=text,
        format=md.format,
        original=md.text)
end

function jinja(env, md::Marble.InlineMath)
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=env.scratch[:settings_cache],
        text=md.text)
end

function jinja(env, md::Marble.InlineCE)
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=env.scratch[:settings_cache],
        text=md.text)
end

function jinja(env, md::Marble.InlineTex)
    return JinjaTemplates.render(env.templates, "elements/latex/$(get_template_name(md)).tex";
        settings=env.scratch[:settings_cache],
        text=md.text)
end