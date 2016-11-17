"""
Manages the build of a project. Includes multiple documents
"""
type MarbleEnv{T}
    settings::SettingsBundle
    cache::States # Storage of ached files
    documents::Array{T}
    # log

    MarbleEnv(settings, cache, documents) = new(settings, cache, documents)
end


# Construct a MarbleEnv with an array of MarbleDocs
# Oh the price of explicit typeing
function MarbleEnv(settings)
    cache = States("$(settings["cachedir"])/filehash_list.json")
    documents = map(settings["documents"]) do docname
        show(docname)
        return MarbleDoc(
            docname[1:findlast(docname, '.') - 1],
            readstring(docname),
            cache,
            SettingsBundle(settings))
    end

    this = MarbleEnv{MarbleDoc}(
        settings,
        cache,
        documents)
    return this
end


function Base.parse(env::MarbleEnv)
    for doc in env.documents
        parse(doc)
    end
end


function process(env::MarbleEnv)
    for doc in env.documents
        process(doc)
    end
end


function render(env::MarbleEnv)
    for doc in env.documents
        render(doc)
    end
end


function template(env::MarbleEnv)
    for doc in env.documents
        template(doc)
    end
end


function build(env::MarbleEnv)
    for doc in env.documents
        build(doc)
    end
end


function buildall(env::MarbleEnv)
    parse(env)
    process(env)
    render(env)
    template(env)
    build(env)
end