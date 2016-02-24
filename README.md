# Marble

<!--[![Build Status](https://travis-ci.org/dustinrb/Marble.jl.svg?branch=master)](https://travis-ci.org/dustinrb/Marble.jl)-->

Marble is yet another academic Markdown flavor. It emphasizes an easy transition from Markdown to Latex. Consequently, it currently cannot convert files into HTML. So, what does Marble offer:

1. Highly configurable output. Marble uses Jinja2 templating to control the rending of each element. Each template can be easily overwritten.
2. First class support for [figures](#figure), [tables](#table), [equations](#equation), and [analysis script output](#data)
3. Readable Latex output

**NOTE:** Marble is currently a proof of concept. Installation and error handling are currently not as smooth as they should be, and Marble has not yet been submitted to the official Julia package index due to lack of testing. Please open an issue on github if you encounter any problems.

## Installation

### Dependancies

Marble is written in the Julia programming language, but also relies Jinja2 which is a Python package. Marble also requires a working Latex installation to render documents.

#### OSX

1. Install [Julia](http://julialang.org). It is highly suggested you install Julia using [Homebrew](https://github.com/staticfloat/homebrew-julia/) following the instructions found at [https://github.com/staticfloat/homebrew-julia/](https://github.com/staticfloat/homebrew-julia/)
2. Install [MacTex](https://tug.org/mactex/). Again, it is suggested you use Homebrew Cask. Be aware that MacTex is a very large application (~2.5gb), so it may take a while to download and install
    ```sh
    # If you do not yet have cask installed
    brew update
    brew install cask

    # Now install MacTex
    brew cask install mactex
    ```
3. Install Jinja2. From the command-line run `pip install Jinja2`. This may require `sudo` privileges depending on how Python is configured.

#### Linux

This project has not been tested on Linux. Here are some hypothetical instructions.

1. Install [Julia](http://julialang.org) (>= 4.2), either with your package manager or from a binary. The Marble command line tool expects Julia to be installed at `/usr/local/bin/julia` so it may be necessary to create a symbolic link or modify  the first line in `src/marble.jl`.
2. Install TexLive and make sure `latexmk` and `xelatex` work
3. Make sure python is installed with Jinja2: `pip install Jinja2`

#### Windows

This project has not been tested on Windows, and I am not confident it will work due to bash style syntax for building the PDF and references and heavy use of `ENV["HOME"]`. If someone does manage to get Marble up and running on Windows, please submit a pull request with instructions. Thanks.

### Installing Marble

Now that the dependancies are installed, create a Marble configuration directory. This is where the user level settings.yaml is stored plus any custom templates

```sh
mkdir -p $HOME/.mrbl/templates
touch $HOME/.mrbl/settings.yaml
```

Now, from the Julia REPL, install Marble and its dependancies. Please note that Marble and its dependancies have yet to be submitted to the official Julia package repository, so this step uses `Pkg.clone` instead of `Pkg.add`.

```julia
# Install dependancies
Pkg.clone("https://gitlab.com/dustinrb/JinjaTemplates.jl.git")
Pkg.clone("https://gitlab.com/dustinrb/SettingsBundles.jl.git")
# Install Marble
Pkg.clone("https://gitlab.com/dustinrb/Marble.jl.git")
```

Finally, link the Marble CLI to your /usr/loca/bin directory

```sh
ln -s $HOME/.julia/v0.4/Marble/src/cli/marble.jl /usr/local/bin/mrbl
```

## Using Marble

### Creating a Marble Project

**NOTE:** The `project-init` branch of this project has preliminary support for the `mrbl init [path]` command. This command creates the a project folder at the specified path, instantiates a git repository, and adds a git hook to build the project on commit.

To use marble for a project, create a directory as so:

```
myproject
    build
        (empty dir for building PDFs)
    document.md
    settings.yaml
```

If you do not want your document to be named `document.md`, add a the following line to the settings.yaml file.

```yaml
maindoc: mydocname.md
```

### Running Marble

To build a Markdown document once Marble is installed, switch to the document's directory and run `mrbl`. This will parse the projects' `document.md` and output a PDF in `build/document.pdf`

## Supported Elements

Marble uses Julia's build-in [Markdown parser](https://github.com/JuliaLang/julia/tree/master/base/markdown) for standard elements. Support for certain elements is limited at the moment, but should improve over time.

Below are examples of Marble input and output. Please see the element templates for more specifics.

### Inline Elements

#### Italics

```
*text* → textit{text}
```

**NOTE:** Standard markdown underscore syntax (`_text_`) is not supported.

#### Bold

```
**text** → textbf{text}
```

**NOTE:** Standard markdown underscore syntax (`__text__`) is not supported.

#### Code

```
`code` → \texttt{code}
```

#### Link

```
[Text](http://example.com) → \href{http://example.com}{Text}
```

#### Image

```
![Alt Text](path/to/image.png) → \includegraphics[width=4in>]{path\to\image.png}
```

The image alternate text is not actually rendered. Width is configurable in Marble's `imagewidth` setting which defaults to "4in"

#### Math

```
$a+b=c$ → $a+b=c$
```

Please note that inline math cannot have spaces directly after the initial $ or before the final $. For example, `$ a+b=c $` will be rendered as `\$ a+b=c \$`.

#### Footnote

```
(^My footnote text) → \footnote{My footnote text}
```

#### Citation

```
(@source1) → \cite{source1}
(@source1, source2) → \cite(source1,source2)
```

Marble relies on Biber for citation rendering. In order for citations to work, the `citationfile` settings must point towards a valid .bib file.

#### Data

Marble allows the user to specify an analysis script. This script must print valid JSON to STDOUT, making those variables available within the Marble document. This requires two settings: `analysiscmd` is the command to execute the analysis file, where `$filename` will be replaced by the name of the analysis script, and `analysis` is the name of the analysis script (`$filename`'s value'). For example

```yaml
analysiscmd: julia $filename
analysis: myscript.jl
```

will run `julia myscript.jl` and parse the output as JSON.

Use the following syntax to reference variables in your Marble document.

```
($varname|format_str)
```

`varname` is the name of the variable from the analysis file's JSON, and `format_str` is an optional Python formatting string (see [Formatting.jl's](https://github.com/JuliaLang/Formatting.jl) documentation for more details).

For example, if the analysis script outputs `{"A": 2.3344}`, you can access this data in Marble as follows:

```
($A) → 2.3344
($A|.2d) → 2.33
```

#### Reference

```
(#fig:name) → \ref{fig:name}
```

#### Unit

This feature uses the [siunitx](https://www.ctan.org/pkg/siunitx?lang=en) package for unit output and formatting. See the package documentation for acceptable units.

```
(unit kilogram meter per second squared) → \si{\kilogram\meter\per\second\squared}
```

#### Tex

Outputs raw tex.

```
(tex This is \textit{my content}) → This is \textit{my content}
```

### Block Elements

#### Paragraph

In:
```
This is a paragraph
```

Out:
```
This is a paragraph
```

#### Header

In:
```
# H1
## H2
### H3
#### H4
##### H5
###### H6
```

Out:
```
\section{H1}

\subsection{H2}

\subsubsection{H3}

\subsubsection{H4}

\subsubsection{H5}

\subsubsection{H6}
```

#### List

In:
```
1. EN 1
2. EN 2

• LI 1
• LI 2
```

Out:
```
\begin{enumerate}
\item EN 1
\item EN 2

\end{enumerate}

\begin{itemize}
\item LI 1
\item LI 2

\end{itemize}
```

Note that Julias build in Markdown parser does not support nested lists.

#### Block Quote

In:
```
> This is a quote
```

Out:
```
\begin{displayquote}
This is a quote

\end{displayquote}
```

#### Code

In:
<pre>
```js
This is a fenced code block
```
</pre>

Out:
```
\begin{verbatim}
This is a fenced code block
\end{verbatim}
```

#### Horizontal Rule/Page Break

In:
```
---
```

Out:
```
\pagebreak
```

This is done because a page break is more common in paginated media than horizontal rules.

#### Figure

In:
```
Figure:  
    name: fig1
    path: 1h.jpg
    caption: |
      Figure Figure *caption*
end
```

Out:
```
\begin{figure}[h]
    \centering
    \label{fig1}
    \includegraphics[width=4in]{1h.jpg}

    \caption{Figure Figure \textit{caption}
}
\end{figure}
```

Alternatively, figure content can be specified with raw tex.

In:
```
Figure:
    name: fig2
    caption: Figure without image.
    tex: |
        \schemestart
        \chemfig{H-[::60]O-[::-60]H}\arrow \chemfig{O-C=C}
        \schemestop
end
```

Out:
```
\begin{figure}[h]
    \centering
    \label{fig2}

    \schemestart
\chemfig{H-[::60]O-[::-60]H}\arrow \chemfig{O-C=C}
\schemestop

    \caption{Figure without image.}
\end{figure}
```

#### Table

Marble supports two types of table, github style and CSV style.

##### GitHub Tables

In:
```
| First Header  | Second Header |
| ------------- | :------------ |
| Content Cell  | Content Cell  |
| Content Cell  | Content Cell  |
```

Out:
```
\begin{table}[h]
    \begin{tabular}{rl}
        \toprule
        First Header & Second Header \\
        \midrule
        Content Cell & Content \textit{Cell} \\
        Content Cell & Content Cell \\

        \bottomrule
    \end{tabular}
    \centering
\end{table}
```

Note that this type of table does note have a label and so cannot be references. Also, it does not have a caption.

##### CSV Tables

This table references a CSV file and then reads it in as a table.

In:
```
Table:
    name: tab1
    path: file.csv
    caption: Table **caption**
    parse:
        header: false
    columns:
        -
            header: Header 1
            align: center
        -
            header: Header 2
            align: right
        -   header: Header 3
end
```

Out:
```
\begin{table}[h]
    \label{tab1}
    \caption{Table \textbf{caption}}
    \begin{tabular}{crS}
        \toprule
        {Header 1} & {Header 2} & {Header 3}  \\
        \midrule
        1 & 2 & 1.23 \\
        2 & 3 & 2.345 \\
        3 & 4 & 3.4 \\

        \bottomrule
    \end{tabular}
    \centering
\end{table}
```

`parse` are any options you wish to pass to the [CSV parser](https://dataframesjl.readthedocs.org/en/latest/io.html#advanced-options-for-reading-csv-files).

`columes` is metadata about how the columns should be displayed. This array's length must equal the number of columns in the CSV file, so if you specify metadata for one column, you must acknowledge them all by at least leaving a blank entry. If `headers` is not specified, Marble will use the headers in the CSV file. `align` can have a value of right, center, left, or decimal, where decimal aligns the columns entries at the decimal point (depends on siunitx package).

#### Equation

In:
```
Equation:
    name: eq2
    content: |
        \sum _{n=1}^{\infty}x_{n}+x_{n+1}
end
```

Out:
```
\begin{equation}
    \label{eq2}
    \sum _{n=1}^{\infty}x_{n}+x_{n+1}
\end{equation}
```

#### Tex

Prints raw Latex.

In:
```
Tex:
\pagebreak
end
```

Out:
```
\pagebreak
```

### Document

The document element is not rendered directly; however, it does offer the writer a chance to change some settings within the document itself. Be advised that some settings are used before the document is parsed, so things like `templatedir` and `maindoc` cannot be specified within `Document` blocks. As a matter of form, only use `Document` blocks to specify information that will be displayed in document, such as title, authors, and date. Everything else should go in `settings.yaml`.

```
Document:
    title: My Title
    authors:
        -
            name: Author 1
            email: author1@example.com
        -
            name: Author 2
            email: author2@example.com
    date: January 3, 2016
end
```

## Settings

Settings can be specified in, on order of lowest priority to highest, `$HOME/.mrbl/settings.yaml`, a project's `settings.yaml` or in a `Document` block within the Markup.

### Notable Settings

* `maindoc` -- Specifies which file for Marble to parse as Markdown
* `title` -- Document's title
* `date` -- Document's date
* `authors` -- Array of author information including name, email, affiliation
* `toc` -- Specifies whether to render the table of contents
* `font_main` -- Specifies the main font
* `font_sans` -- Specifies the sans serif font
* `font_mono` -- Specifies the monospace font
* `fontsize` -- The font size specified in `\documentclass`. Defaults to `11pt`
* `papersize` -- The pepersize specified in `\documentclass`. Defaults to `letter`
* `imagewidth` -- The default image width. Defaults to `4in`
* `template` -- The template used to render the document. Current templates are `final` and `draft` where `draft` is double spaced
* `templatedir` -- Directory in which marble looks for templates. Defaults to `templates`
*  `watch` -- Boolean which tell marble whether to rebuild the document each time it's saved
* `analysiscmd` -- The command used to interpret the analysis file
* `analysis` -- The analysis file. Should output JSON to SDTOUT
* `header_tex` -- Injects a dash of latex before `\begin{document}`

### Example `$HOME/.mrbl/settings.yaml`

```yaml
authors:
    -
        name: My Name
        email: myemail@example.com
template: draft
citationfile: ~/.mrbl/library.bib
analysiscmd: julia $filename
fontsize: 12pt
papersize: letter
font_main: CMU Serif
font_sans: CMU Sans Serif
font_mono: Inconsolata
```

## FAQ

### Why no HTML yet?

Marble is a new project and the highest priority was creating a working PDF output. The HTML templates have simply not been written, though doing so would be straight forward.

### How do I customize element output?

Copy the desired template from `$HOME/.julia/v0.4/Marble/tempaltes` to `$HOME/.mrbl/templates` and edit it. Be advised that even though Marble uses Jinja2 for templateing, the block identifiers are different. Instead of `{{}}`, Marble uses `<||>`, and instead of `{%%}` Marble uses `<%%>`. This eliminates ambiguity when parsing latex where `{{` is not uncommon.

Here is a brief example of which makes Header elements [no longer display the section number, while retaining a listing in the table of contents](http://stackoverflow.com/questions/3978203/how-do-i-keep-my-section-numbering-in-latex-but-just-hide-it).

Start of by copying the relevant template, in this case `mkdir -p $HOME/.mrbl/templates/elements/latex && cp $HOME/.julia/v0.4/Marble/templates/ elements/latex/Base.Markdown.Header_1_.tex $HOME/.mrbl/templates/elements/latex`. Currently, Base.Markdown.Header_1_.tex is

```
\section{<|text|>}

```

so change it to

```
\section*{<|text|>}
\addcontentsline{toc}{section}{<|text|>}

```

Congratulations! From now on, sections won't have the section number in front, but will still show up in the TOC.

### How do I customize document templates?

Simply copy it from `$HOME/.julia/v0.4/Marble/templates/documents` to `$HOME/.mrbl/templates/documents` and make the desired changes.

## To Do

1. Make parsing more stable. Provide useful warnings about failure while allow the document to compile.
2. Improve the Julia markdown parser and perhaps eventually make it [compliant](http://commonmark.org)
3. Create HTML templates
4. Improve documentation

