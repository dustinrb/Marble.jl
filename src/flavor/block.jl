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

# Prototype for future rendering method rendering style is
# specified on a per-field basis
function META(md::Figure)
    return Dict(
        :path => :raw,
        :name => :raw,
        :caption => :interpreted,
        :tex => :raw
    )
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
            gettablecontent(data, col_meta, df),
            Markdown.parseinline(get(data, "caption", ""), md),
            getcolumnheaders(col_meta, df),
            getcolumnalignment(col_meta, df)
        ))
    end
end

""" Takes in a dataframe and converst a format easily renderable by Jinja"""
function gettablecontent(data, col_meta, df)
    fmt = getformattingstrings(col_meta)
    return map(eachrow(df)) do row
        # Apply formatting string to each element
        return [format(fmt[i], row[i]) for i in 1:length(row)]
    end
end

""" Returns a list of formatting string (default is "{}")"""
function getformattingstrings(data)
    return map(data) do x
        get(x, "format", "{}")
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


# –––––
# Lists
# –––––

type List
    items::Vector{Any}
    ordered::Bool
    startval::Int

    List(x::AbstractVector, b::Bool, s::Int) = new(x, b, s)
    List(x::AbstractVector, b::Bool) = new(x, b, 0)
    List(x::AbstractVector) = new(x, false, 0)
    List(b::Bool) = new(Any[], b, 0)
end

List(xs...) = List(vcat(xs...))

const bullets = "*•+-"
const num_or_bullets = r"^(\*|•|\+|-|\d+(\.|\))) "

# Todo: ordered lists, inline formatting
function list(stream::IO, block::Markdown.MD)
    withstream(stream) do
        eatindent(stream) || return false
        b = startswith(stream, num_or_bullets)
        (b === nothing || b == "") && return false
        ordered = !(b[1] in bullets)
        if ordered
            b = b[end - 1] == '.' ? r"^\d+\. " : r"^\d+\) "
            # TODO start value
        end
        the_list = List(ordered)

        buffer = IOBuffer()
        fresh_line = false
        while !eof(stream)
            if fresh_line
                sp = startswith(stream, r"^ {0,3}")
                if !(startswith(stream, b) in [false, ""])
                    push!(the_list.items, parseinline(takebuf_string(buffer), block))
                    buffer = IOBuffer()
                else
                    # TODO write a newline here, and deal with nested
                    write(buffer, ' ', sp)
                end
                fresh_line = false
            else
                c = read(stream, Char)
                if c == '\n'
                    eof(stream) && break
                    next = Char(peek(stream)) # ok since we only compare with ASCII
                    if next == '\n'
                        break
                    else
                        fresh_line = true
                    end
                else
                    write(buffer, c)
                end
            end
        end
        push!(the_list.items, parseinline(takebuf_string(buffer), block))
        push!(block, the_list)
        return true
    end
end
