using Formatting

### math ###
type InlineMath
    text
    InlineMath(text, md::Markdown.MD) = return new(strip(text))
end

### math ###
type InlineCode
    text
    InlineCode(text, md::Markdown.MD) = return new(text)
end

### Tex ###
type InlineTex
    text
    InlineTex(text, md::Markdown.MD) = return new(text)
end

### Citation ###
type InlineCite
    sources
    InlineCite(text, md::Markdown.MD) = return new(split(text, ','))
end

### Reference ###
type InlineRef
    text
    InlineRef(text, md::Markdown.MD) = return new(text)
end

### Units ###
type InlineUnit
    units
    InlineUnit(text, md::Markdown.MD) = return new(split(text, ' '))
end

### Chemical Equation ###
type InlineCE
    text
    InlineCE(text, md::Markdown.MD) = return new(text)
end

### Chemical Equation ###
type InlineFootnote
    text
    InlineFootnote(text, md::Markdown.MD) = return new(Markdown.parseinline(text, md))
end

### Data ###
type InlineData
    text
    format
    function InlineData(raw, md::Markdown.MD)
        t = split(raw, '|')
        text = t[1]
        format  = get(t, 2, "{}") # Just print the value
        return new(text, format)
    end
end

""" Does more traditional Tex/Pandoc style inline math. """
function inline_math(stream::IO, md::Markdown.MD)
    # The follow does not support whitespace between delimeters, so we won't be using it
    result = Markdown.parse_inline_wrapper(stream, "\$")
    return result === nothing ? nothing : InlineMath(result, md)
end

""" Does more traditional Tex/Pandoc style inline math. """
function inline_code(stream::IO, md::Markdown.MD)
    result = Markdown.parse_inline_wrapper(stream, "`")
    return result === nothing ? nothing : InlineCode(result, md)
end

# Trigger is (
""" Parses inline tages of the form (key text) """
function interpreted_inline(stream::IO, md::Markdown.MD)
    # Memory allocation every time function is run
    tags = Dict(
        ".math" => InlineMath,
        ".tex" => InlineTex,
        "@" => InlineCite,
        "#" => InlineRef,
        ".unit" => InlineUnit,
        ".ce" => InlineCE,
        "\$" => InlineData,
        "^" => InlineFootnote
    )

    inline_key = ""
    for key in keys(tags)
        if Markdown.startswith(stream, "[$key")
            inline_key = key
            break
        end
    end

    if isempty(inline_key)
        return nothing
    end

    text = Markdown.readuntil(stream, ']', match='[')
    return text === nothing ? nothing : tags[inline_key](text, md)
end
