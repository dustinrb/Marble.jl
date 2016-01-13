using DataFrames

### Figure ###
type Figure
    path
    name
    caption
    tex

    function Figure(stream::IO, md::Markdown.MD)
        data = YAML.load(stream)
        push!(md, new(
            get(data, "path", ""),
            get(data, "name", ""),
            Markdown.parseinline(get(data, "caption", ""), md),
            get(data, "tex", "")
        ))
    end
end

### Table ###
type Table
    path
    name
    content
    caption
    headers
    alignment

    function Table(stream::IO, md::Markdown.MD)
        data = YAML.load(stream)
        path = data["path"]
        df = DataFrame() # Because the try statement puts it out of scope

        try
            params = convert(Dict{Symbol, Any}, get(data, "parse", Dict()))
            df = readtable(path; params...)
        catch
            warn("Unabel to read `$(path)` into table.")
            return false
        end

        # Get the user specified column headers and alignment info
        col_meta = get(data, "columns", fill(Dict(), ncol(df)))
        if length(col_meta) != ncol(df)
            warn("Number of columns for table does not match number detected in CSV `$(data["path"])`")
            col_meta = fill(Dict(), ncol(df))
        end

        push!(md, new(
            path,
            get(data, "name", ""),
            gettablecontent(data,df),
            Markdown.parseinline(get(data, "caption", ""), md),
            getcolumnheaders(col_meta, df),
            getcolumnalignment(col_meta, df)
        ))
    end
end

""" Takes in a dataframe and converst a format easily renderable by Jinja"""
function gettablecontent(data, df)
    return map(eachrow(df)) do row
        return [i[2] for i in row]
    end
end

""" Returns a canonical list of column headers"""
function getcolumnheaders(data, df)
    return map(zip(data, names(df))) do x
        return get(x[1], "header", string(x[2]))
    end
end

""" Returns the column alignment based on explicit user input or infered
elignment

Infered Inputs
• String → left
• Int → right
• Float → decimal
• Everything else → left
"""
function getcolumnalignment(data, df)
    col_types = map(names(df)) do cn
        return eltype(df[cn])
    end
    return map(zip(data, col_types)) do col
        return get(col[1], "align", getcolumnalignment(col[2]))
    end
end

""" Given a type, returns the proper table alignment """
function getcolumnalignment(t::Type)
    if t <: Int
        return "right"
    elseif t <: Float64 # There is no AbstractFloat :(
        return "decimal"
    else
        return "left"
    end
end

Base.get(col::Void, key, default) = return default

### Equation ###
type Equation
    name
    content

    function Equation(stream::IO, md::Markdown.MD)
        data = YAML.load(stream)
        push!(md, new(
            get(data, "name", ""),
            get(data, "content", "")
        ))
    end
end

### Tex ###
type Tex
    content

    function Tex(stream::IO, md::Markdown.MD)
        data=readall(stream)
        push!(md, new(data))
    end
end

###  Document ###
type Document
    data

    function Document(stream::IO, md::Markdown.MD)
        data = YAML.load(stream)
        push!(md, new(data))
    end
end

function YAMLelement(stream::IO, md::Markdown.MD)
    elements = Dict(
        "Figure:" => Figure,
        "Table:" => Table,
        "Equation:" => Equation,
        "Tex:" => Tex,
        "Document:" => Document,
    )

    # Check if the line starts with one of our keywords
    block_type = ""
    for key in keys(elements)
        if Markdown.startswith(stream, key, padding=false) || Markdown.startswith(stream, lowercase(key), padding=false)
            isempty(strip(readline(stream))) || return false
            block_type = key
            break
        end
    end

    # If nothing, just quit
    if block_type == ""
        return false
    end

    # Now finish the run
    buffer = IOBuffer()
    while !eof(stream)
        line_start = position(stream)

        if rstrip(readline(stream)) == "end"
            elements[block_type](seek(buffer, 0), md)
            return true
        end
        # Now that we've check the line, push it into buffer
        seek(stream, line_start)
        write(buffer, readline(stream))
    end

    return false
end
