{smcl}
{* 22may2023}{...}
{hi:help geoplot}{...}
{right:{browse "https://github.com/benjann/geoplot/"}}
{hline}

{title:Title}

{pstd}{hi:geoplot} {hline 2} Command to draw maps from shape files


{title:Syntax}

{p 8 15 2}
    {cmd:geoplot} {cmd:(}{it:layer}{cmd:)} [{cmd:(}{it:layer}{cmd:)} ...]
    [{cmd:,}
    {help geoplot##opt:{it:global_options}}
    ]

{pstd}
    where {it:layer} is

{p 8 15 2}
    {help geoplot##plottypes:{it:plottype}} [{it:frame}] [{it:...}] [{cmd:,}
    {help geoplot##cvaropts:{it:cvar_options}}
    {it:other_options} ]

{pstd}
    and {it:frame} is the name of a frame containing data prepared by
    {helpb geoframe}. {it:frame} may be omitted if
    there are no subsequent arguments (apart from {it:{help if}},
    {it:{help in}}, {it:{help weight}}, or options); in this case, the
    current (working) frame will be used. To use the current (working) frame
    you may also type {it:frame} as {cmd:.} (missing).


{synoptset 20 tabbed}{...}
{marker plottypes}{synopthdr:plottypes}
{synoptline}
{synopt :{helpb geoplot##area:area}}plot shapes, potentially filled
    {p_end}
{synopt :{helpb geoplot##line:line}}plot shapes, line only
    {p_end}
{synopt :{helpb geoplot##point:point}}plot single-coordinate markers
    {p_end}
{synopt :{helpb geoplot##labels:{ul:lab}els}}plot single-coordinate labels
    {p_end}

{synopt :{helpb geoplot##pcspike:pcspike}}plot paired-coordinate spikes
    {p_end}
{synopt :{helpb geoplot##pccapsym:pccapsym}}plot paired-coordinate spikes capped with symbols
    {p_end}
{synopt :{helpb geoplot##pcarrow:pcarrow}}plot paired-coordinate arrows
    {p_end}
{synopt :{helpb geoplot##pcbarrow:pcbarrow}}plot paired-coordinate arrows with two heads
    {p_end}
{synopt :{helpb geoplot##pcpoint:pcpoint}}plot paired-coordinate markers
    {p_end}

{p2coldent:* {helpb geoplot##pointi:pointi}}{cmd:point} with immediate arguments
    {p_end}
{p2coldent:* {helpb geoplot##pci:pci}}{cmd:pcspike} with immediate arguments
    {p_end}
{p2coldent:* {helpb geoplot##pcarrowi:pcarrowi}}{cmd:pcarrow} with immediate arguments
    {p_end}
{synoptline}
{p 4 6 2}
    * {help geoplot##cvaropts:{it:cvar_options}} not supported.


{synoptset 20 tabbed}{...}
{marker cvaropts}{synopthdr:cvar_options}
{synoptline}
{synopt :{helpb geoplot##cvar:{ul:cv}ar({it:cvar})}}variable to control color
    {p_end}
{synopt :{helpb geoplot##color:{ul:col}or({it:palette})}}color palette to be used
    {p_end}
{synopt :{helpb geoplot##levels:{ul:lev}els({it:spec})}}number of levels and method to determine cuts
    {p_end}
{synopt :{helpb geoplot##cuts:cuts({it:numlist})}}use levels defined by specified cuts
    {p_end}
{synopt :{helpb geoplot##discrete:{ul:discr}ete}}treat {it:cvar} as discrete instead of continuous
    {p_end}
{synopt :{helpb geoplot##missing:{ul:mis}sing({it:colorspec})}}color to be used for missing values
    {p_end}
{synoptline}


{synoptset 20 tabbed}{...}
{marker opt}{synopthdr:global_options}
{synoptline}
{syntab :Main}
{synopt :{helpb geoplot##wmax:wmax({it:#})}}custom upper bound of weights
    {p_end}
{synopt :{helpb geoplot##tight:tight}}adjust graph size to dimension of map
    {p_end}
{synopt :{helpb geoplot##margin:{ul:m}argin({it:spec})}}specify (minimum) margin
    around map
    {p_end}
{synopt :{helpb geoplot##rotate:rotate({it:angle})}}rotate map by {it:angle}
    {p_end}
{synopt :{helpb geoplot##aspect:{ul:aspect}ratio({it:spec})}}adjust aspect
    ratio of map
    {p_end}
{synopt :{it:{help twoway_options}}}twoway options, other than {cmd:by()}

{syntab :Legend}
{synopt :{helpb geoplot##legend:{ul:leg}end({it:suboptions})}}add standard legend
    {p_end}
{synopt :{helpb geoplot##nolegend:{ul:noleg}end}}suppress default legend
    {p_end}
{synopt :{helpb geoplot##clegend:{ul:cleg}end({it:suboptions})}}add {helpb contour} plot legend
    {p_end}

{syntab :Data}
{synopt :{helpb geoplot##frame:frame({it:spec})}}store ploted data in new frame
    {p_end}
{synoptline}


{title:Description}

{pstd}
    {cmd:geoplot} draws maps from shape files and other datasets prepared by
    {helpb geoframe}. The procedure is to first create one or several frames
    containing the source data using {helpb geoframe} and then apply
    {cmd:geoplot} to plot the data from these frames.

{pstd}
    Multiple layers of elements such as regions, borders, lakes, roads, labels, etc.,
    can be freely combined. Elements can be colored based on values of variables.

{pstd}
    {cmd:geoplot} requires {helpb colorpalette}, {helpb colrspace}, and {helpb moremata}. To
    install the relevant packaged type

        {com}. {stata ssc install palettes}{txt}
        {com}. {stata ssc install colrspace}{txt}
        {com}. {stata ssc install moremata}{txt}


{title:Plottypes}

{marker area}{...}
{dlgtab:shapes, potentially filled}

{p 8 15 2}
    {cmd:area} [{it:frame} [{it:cvar}]] {ifin}
    [{cmd:,}
    {it:options} ]

{pstd}
    where {it:frame} is the frame containing the coordinates of the shapes to be
    plotted (see {helpb geoframe}), {it:cvar} is an optional variable to determine colors,
    and {it:options} are as follows.

{phang2}
    {it:{help geoplot##cvaropts:cvar_options}} are options determining the coloring of the shapes
    as described {help geoplot##cvar_options:below}.

{phang2}
    {cmdab:ec:olor(}{help colorpalette##colorlist:{it:colorspec}}{cmd:)}
    sets the fill color used for enclaves. {it:colorspec} is a (single) color
    specification as described in {helpb colorpalette##colorlist:colorpalette}. Default
    is {cmd:ecolor(white)}. The color of an enclave will only be visible if not
    covered by a corresponding exclave.

{phang2}
    {it:{help area_options}} are options to affect the look of areas as described in
    {helpb twoway area}. For example, use option {cmd:lcolor()} to set
    the outline color. Options {cmd:color()}, {cmd:fcolor()}, and {cmd:lcolor()}
    support {it:colorspec} as described in {helpb colorpalette##colorlist:colorpalette}.

{marker line}{...}
{dlgtab:shapes, line only}

{p 8 15 2}
    {cmd:line} [{it:frame} [{it:cvar}]] {ifin}
    [{cmd:,}
    {it:options} ]

{pstd}
    where {it:frame} is the frame containing the coordinates of the shapes to be
    plotted (see {helpb geoframe}), {it:cvar} is an optional variable to determine colors,
    and {it:options} are as follows.

{phang2}
    {it:{help geoplot##cvaropts:cvar_options}} are options determining the coloring of the lines
    as described {help geoplot##cvar_options:below}.

{phang2}
    {it:{help line_options}} are options to affect the look of lines as described in
    {helpb twoway line}. For example, use option {cmd:lwidth()} to set
    the width of lines. Option {cmd:lcolor()} supports {it:colorspec} as
    described in {helpb colorpalette##colorlist:colorpalette}.

{marker point}{...}
{dlgtab:single-coordinate markers}

{p 8 15 2}
    {cmd:point} [{it:frame} [{it:Y} {it:X}]] {ifin} {weight}
    [{cmd:,}
    {it:options} ]

{pstd}
    where {it:frame} is the frame containing the coordinates of the points to be
    plotted (see {helpb geoframe}), {it:Y} and {it:X} are custom variables names
    for the coordinates, and {it:weight} scales the size of the markers (see
    {help scatter##remarks14:Weighted markers} in {helpb twoway scatter}. The weights
    will be normalized to make marker sizes comparable across layers; also see
    option {helpb geoplot##wmax:wmax()} for normalization across different
    graphs. {cmdab:sc:atter} may be used as a synonym for {cmd:point}. {it:options}
    are as follows.

{phang2}
    {it:{help geoplot##cvaropts:cvar_options}} are options determining the coloring of the markers
    as described {help geoplot##cvar_options:below}.

{phang2}
    {it:{help marker_options}}, {it:{help marker_label_options}},
    {it:{help connect_options}}, and {it:jitter_options} are options to affect
    the look of markers as described in {helpb twoway scatter}. For example,
    use option {cmd:msymbol()} to set the marker symbol. Options {cmd:mcolor()},
    {cmd:mfcolor()}, {cmd:mlcolor()}, {cmd:mlabcolor()}, and {cmd:lcolor()}
    support {it:colorspec} as described in {helpb colorpalette##colorlist:colorpalette}.

{marker labels}{...}
{dlgtab:single-coordinate labels}

{p 8 15 2}
    {cmd:labels} [{it:frame} {it:labelvar} [{it:Y} {it:X}]] {ifin}
    [{cmd:,}
    {it:options} ]

{pstd}
    where {it:frame} is the frame containing the coordinates of the points to be
    plotted (see {helpb geoframe}), {it:labelvar} is a (numeric or string) variable
    providing the labels, {it:Y} and {it:X} are custom variables names
    for the coordinates, and {it:options} are as follows.

{phang2}
    {it:{help geoplot##cvaropts:cvar_options}} are options determining the coloring of the labels
    as described {help geoplot##cvar_options:below}.

{phang2}
    {opth pos:ition(clockposstyle)},
    {opth vpos:ition(varname)},
    {opth gap(size)},
    {opth ang:le(anglestyle)},
    {opth tsty:le(textstyle)},
    {opth si:ze(textsizestyle)},
    {cmdab:col:or(}{help colorpalette##colorlist:{it:colorspec}}{cmd:)}, and
    {opth f:ormat(%fmt)} are marker label options equivalent to the corresponding options
    described in help {it:{help marker_label_options}}. Option
    {cmd:color()} supports {it:colorspec} as described in
    {helpb colorpalette##colorlist:colorpalette}.

{phang}
    Plot type {cmd:labels} is implemented as a wrapper for plot type {cmd:point}.

{marker pcspike}{...}
{dlgtab:paired-coordinate spikes}

{p 8 15 2}
    {cmd:pcspike} [{it:frame} [{it:Y1} {it:X1} {it:Y2} {it:X2}]] {ifin}
    [{cmd:,} {it:options} ]

{pstd}
    where {it:frame} is the frame containing the coordinates of the spikes to be
    plotted (see {helpb geoframe}), {it:Y1}, {it:X1}, {it:Y2}, and {it:X3} are custom
    variables names for the coordinates, and {it:options} are
    {it:{help geoplot##cvaropts:cvar_options}} as described {help geoplot##cvar_options:below},
    as well as further options to affect the rendering of the spike lines
    as described in {helpb twoway pcspike}. Option {cmd:lcolor()} supports {it:colorspec} as
    described in {helpb colorpalette##colorlist:colorpalette}.

{marker pccapsym}{...}
{dlgtab:paired-coordinate spikes capped with symbols}

{p 8 15 2}
    {cmd:pccapsym} [{it:frame} [{it:Y1} {it:X1} {it:Y2} {it:X2}]] {ifin}
    [{cmd:,} {it:options} ]

{pstd}
    where {it:frame} is the frame containing the coordinates of the spikes to be
    plotted (see {helpb geoframe}), {it:Y1}, {it:X1}, {it:Y2}, and {it:X3} are custom
    variables names for the coordinates, and {it:options} are
    {it:{help geoplot##cvaropts:cvar_options}} as described {help geoplot##cvar_options:below},
    as well as further options to affect the rendering of the spike lines and markers
    as described in {helpb twoway pccapsym}. Options {cmd:mcolor()},
    {cmd:mfcolor()}, {cmd:mlcolor()}, {cmd:mlabcolor()}, and {cmd:lcolor()}
    support {it:colorspec} as described in {helpb colorpalette##colorlist:colorpalette}.

{marker pcarrow}{...}
{dlgtab:paired-coordinate arrows}

{p 8 15 2}
    {cmd:pcarrow} [{it:frame} [{it:Y1} {it:X1} {it:Y2} {it:X2}]] {ifin}
    [{cmd:,} {it:options} ]

{pstd}
    where {it:frame} is the frame containing the coordinates of the arrows to be
    plotted (see {helpb geoframe}), {it:Y1}, {it:X1}, {it:Y2}, and {it:X3} are custom
    variables names for the coordinates, and {it:options} are
    {it:{help geoplot##cvaropts:cvar_options}} as described {help geoplot##cvar_options:below},
    as well as further options to affect the rendering of the arrows
    as described in {helpb twoway pcarrow}. Options {cmd:mcolor()},
    {cmd:mfcolor()}, {cmd:mlcolor()}, {cmd:mlabcolor()}, and {cmd:lcolor()}
    support {it:colorspec} as described in {helpb colorpalette##colorlist:colorpalette}.

{marker pcbarrow}{...}
{dlgtab:paired-coordinate arrows with two heads}

{p 8 15 2}
    {cmd:pbcarrow} [{it:frame} [{it:Y1} {it:X1} {it:Y2} {it:X2}]] {ifin}
    [{cmd:,} {it:options} ]

{pstd}
    where {it:frame} is the frame containing the coordinates of the arrows to be
    plotted (see {helpb geoframe}), {it:Y1}, {it:X1}, {it:Y2}, and {it:X3} are custom
    variables names for the coordinates, and {it:options} are
    {it:{help geoplot##cvaropts:cvar_options}} as described {help geoplot##cvar_options:below},
    as well as further options to affect the rendering of the arrows
    as described in {helpb twoway pcarrow}. Options {cmd:mcolor()},
    {cmd:mfcolor()}, {cmd:mlcolor()}, {cmd:mlabcolor()}, and {cmd:lcolor()}
    support {it:colorspec} as described in {helpb colorpalette##colorlist:colorpalette}.

{marker pcpoint}{...}
{dlgtab:plot paired-coordinate markers}

{p 8 15 2}
    {cmd:pcpoint} [{it:frame} [{it:Y1} {it:X1} {it:Y2} {it:X2}]] {ifin}
    [{cmd:,} {it:options} ]

{pstd}
    where {it:frame} is the frame containing the coordinates of the arrows to be
    plotted (see {helpb geoframe}), {it:Y1}, {it:X1}, {it:Y2}, and {it:X3} are custom
    variables names for the coordinates, and {it:options} are
    {it:{help geoplot##cvaropts:cvar_options}} as described {help geoplot##cvar_options:below},
    as well as further options to affect the rendering of the markers
    as described in {helpb twoway pcscatter}. Options {cmd:mcolor()},
    {cmd:mfcolor()}, {cmd:mlcolor()}, and {cmd:mlabcolor()}
    support {it:colorspec} as described in
    {helpb colorpalette##colorlist:colorpalette}. {cmd:pcscatter} may be used as a
    synonym for {cmd:pcpoint}.

{marker pointi}{...}
{dlgtab:point with immediate arguments}

{p 8 15 2}
    {cmd:pointi} {it:immediate_values} [{cmd:,} {it:options} ]

{pstd}
    where {it:immediate_values} and {it:options} as described in
    {helpb twoway scatteri}. Options {cmd:mcolor()},
    {cmd:mfcolor()}, {cmd:mlcolor()}, {cmd:mlabcolor()}, and {cmd:lcolor()}
    support {it:colorspec} as described in
    {helpb colorpalette##colorlist:colorpalette}. {cmd:scatteri} may be used as a
    synonym for {cmd:pointi}.

{marker pci}{...}
{dlgtab:pcspike with immediate arguments}

{p 8 15 2}
    {cmd:pci} {it:immediate_values} [{cmd:,} {it:options} ]

{pstd}
    where {it:immediate_values} and {it:options} as described in
    {helpb twoway pci}. Option {cmd:lcolor()} supports {it:colorspec} as
    described in {helpb colorpalette##colorlist:colorpalette}.

{marker pcarrowi}{...}
{dlgtab:pcarrow with immediate arguments}

{p 8 15 2}
    {cmd:pcarrowi} {it:immediate_values} [{cmd:,} {it:options} ]

{pstd}
    where {it:immediate_values} and {it:options} as described in
    {helpb twoway pcarrowi}. Options {cmd:mcolor()},
    {cmd:mfcolor()}, {cmd:mlcolor()}, {cmd:mlabcolor()}, and {cmd:lcolor()}
    support {it:colorspec} as described in {helpb colorpalette##colorlist:colorpalette}.


{title:Options}

{marker cvar_options}{...}
{dlgtab:Cvar options}

{marker cvar}{...}
{phang}
    {opt cvar(cvar)} specifies that the colors of the areas, lines, or markers
    in a layer be determined by the values of (numeric) variable {help varname:{it:cvar}}. The
    range of values of {it:cvar} will be divided into levels and each
    level will be represented by a different color. {opt colorvar()} may be
    used as a synonym for {opt cvar()}

{pmore}
    Some {help geoplot##plottype:{it:plottypes}} allow {it:cvar} as an
    argument. In these cases option {cmd:cvar()} is not needed; if specified nonetheless,
    it takes precedence over {it:cvar} specified as an argument.

{marker colors}{...}
{phang}
    {cmd:color(}[{it:{help colorpalette##palette:palette}}] [{cmd:,}
    {it:{help colorpalette##opts:palette_options}}]{cmd:)}
    selects the colors to be used for the levels. {it:palette} is any
    palette allowed by {helpb colorpalette} (which can also be a simple list of colors, see
    help {it:{help colorpalette##colorlist:colorlist}}) and {it:palette_options} are
    corresponding options. The default is {cmd:colors(viridis)}. For example, to use a
    red to blue HCL color scheme, you could type {cmd:colors(hcl bluered, reverse)}. An
    appropriate number of colors will automatically retrieved from {it:palette}
    (applying interpolation or recycling, if necessary, depending on type of palette).

{marker levels}{...}
{phang}
    {cmd:levels(}[{it:#}][{cmd:,} {it:method} {opt w:eight(varname)}]{cmd:)} specifies the number of
    levels to be formed by {it:cvar}. By default, a regular grid
    (equidistant cuts) of 5 intervals from the observed minimum to the observed
    maximum of {it:cvar} will be used (first interval closed, remaining intervals
    left-open). Specify {opt levels(#)} to use {it:#} levels. Specify {it:method}
    to use a non-regular grid. {it:method} can be {cmdab:q:uantile} (use quantiles as
    cuts) or {cmdab:k:means} (use cut points determined by kmeans clustering). In case
    of {cmdab:quantile}, weights to be taken into account when computing the 
    quantiles can be specified in {cmd:weight()}. Option
    {cmd:levels()} has no effect if {cmd:discrete} is specified.

{marker cuts}{...}
{phang}
    {opth cuts(numlist)} is an alternative to {cmd:levels()} and
    specifies the breaks for the levels to be formed by {it:cvar}. Specify
    {it:#}+1 breaks to form {it:#} intervals (first interval closed, remaining
    intervals left-open). Values below the first break or above the last break
    will be ignored. If {cmd:discrete}
    is specified, {it:numlist} is interpreted as the distinct values of
    {it:cvar} to be selected.

{marker discrete}{...}
{phang}
    {opt discr:ete} treats {it:cvar} as a discrete variable. Each unique value
    of {it:cvar} will form a separate level.

{marker missing}{...}
{phang}
    {cmdab:mis:sing(}{help colorpalette##colorlist:{it:colorspec}}{cmd:)}
    specifies the color to be used for missing values. {it:colorspec} is a (single) color
    specification as described in {helpb colorpalette##colorlist:colorpalette}. Default
    is {cmd:missing(gs14)}.

{dlgtab:Global options}

{marker wmax}{...}
{phang}
    {cmd:wmax(#)} specifies the maximum weight used to normalize the weights
    when determining marker sizes. This is only relevant for plottype 
    {helpb geoplot##point:point}. Use this option to make marker sizes
    comparable across graphs (given the graphs have the same size). Typically,
    {it:#} should not be smaller than the observed maximum weight.

{marker tight}{...}
{phang}
    {opt tight} adjusts the size of the overall graph such that it tightly fits
    the map. If {cmd:tight} is not specified, the size of the graph is as set by
    the chosen {help scheme:graph scheme}. Specify {cmd:tight} to remove
    possible white space. By default, {cmd:tight} preserves the vertical size
    of the graph and adjust the horizontal size such that the graph has the
    same aspect ratio as the map. However, if {helpb region_options:xsize()}
    is specified, the vertical size is adjusted. If {helpb region_options:xsize()}
    and {helpb region_options:ysize()} are both specified, {cmd:tight} has no effect.

{pmore}
    Note that {cmd:tight} may not remove all white space if elements outside the
    plot region, e.g. a {helpb title_options:title()}, are added to the
    graph (in this case the available space for the map may have a different
    aspect ratio than the overall graph, which means that the map will not use up
    all available space). Also note that, by default, {cmd:geoplot} includes a small margin around
    the plotregion such that the map will not touch the edges of the
    graph. Specify {helpb region_options:graphregion(margin(zero))} to remove this margin.

{marker margin}{...}
{phang}
    {cmd:margin(}{it:#} [{it:#} {it:#} {it:#}]{cmd:)} sets the margin by which
    the plotregion extends the size of the map. Default is {cmd:margin(0)},
    which means that the plotregion will tightly fit the map. Specify, for example,
    {cmd:margin(1)} to increase the plotregion horizontally by 1 percent of the
    horizontal size of the map and vertically by 1 percent of the vertical size
    of the map (the size of the map is determined by the minimum and maximum coordinates
    of the elements included in the map).

{pmore}
    Specify {cmd:margin(}{it:l} {it:r} {it:b} {it:t}{cmd:)} to use different
    margins on the left, right, bottom, and top (numbers will be recycled if
    less than four numbers are specified). For example, {cmd:margin(10 5 0 7)}
    will increase the plotregion by 10 percent on the left, 5 percent on the
    right, 0 percent at the bottom, and 7 percent at the top.

{pmore}
    {cmd:margin()} may be useful, for example, if you need to make space for a
    legend, such that it does not cover parts of the map.

{marker rotate}{...}
{phang}
    {opt rotate(angle)} rotates map by {it:angle} degrees.

{marker aspect}{...}
{phang}
    {cmd:aspectratio(}[{it:#}] [{cmd:,} {it:pos_option}]{cmd:)} may be used to
    adjust the aspect ratio of the map and to determine the placement of the
    plotregion in the graph. By default, {cmd:geoplot} sets the aspect ratio
    in a way such that horizontal and vertical distances are proportional to
    the numeric values of the coordinates. Specify {opt aspectratio(#)} to multiply
    the aspect ratio determine by {cmd:geoplot} by {it:#} (values between 0 and 1
    will compress the map vertically, values larger than 1 will compress the map
    horizontally). For {it:pos_option} see help {it:{help aspect_option}}.

{phang}
    {it:twoway_options} are general twoway options, other than {cmd:by()}, as
    documented in help {it:{help twoway_options}}. {cmd:geoplot} imposes own
    default settings for options such as {helpb region_options:graphregion()},
    {helpb region_options:plotregion()}, {helpb axis_scale_options:xscale()},
    {helpb axis_scale_options:yscale()}, or {cmd:bgcolor()} (an apparently
    undocumented option to set the color of the canvas, which only becomes
    visible if the graphregion has no color). Specify such options manually to
    override {cmd:geoplot}'s defaults.

{marker legend}{...}
{phang}
    {opt legend(suboptions)} prints a standard legend of the colors used in
    one of the layers that include a {help geoplpot##cvar:{it:cvar}}. At
    most one such legend can be included in the graph (but you may
    use {cmd:clegend()} to create a second legend). {it:suboptions} are as follows:

{phang2}
    {opt l:ayer(#)} selects the layer for which the legend be created. The default
    is to use the first layer containing a color gradient (unless already
    covered by {cmd:clegend()}). For example, if your
    graph contains, say, five layers, and layers 3 and 4 have a
    {help geoplpot##cvar:{it:cvar}}, type {cmd:layer(4)} to create a legend
    for layer 4.

{phang2}
    {opt hor:izontal} arranges the legend horizontally (one row of legend
    keys). The default is to arrange the legend vertically (one column of legend
    keys).

{phang2}
    {opt desc:ending} arranges the legend keys in descending order of the
    values of {help geoplpot##cvar:{it:cvar}}. The default is to use
    ascending order.

{phang2}
    {opth f:ormat(%fmt)} select the display format to be applied to the values
    in the legend labels. The default is to use the display format of
    {help geoplpot##cvar:{it:cvar}}.

{phang2}
    {opt nolab:el} omits the use value labels in case of a
    {help geoplpot##cvar:{it:cvar}} declared as
    {helpb geoplpot##discrete:discrete}.

{phang2}
    {opt mis:sing(options)} determines details about the legend key for missing
    values. {it:options} are {opt l:abel(string)} to define a custom label
    (default is {cmd:"no data"}), {opt first} to place the missing key
    at the top or leftmost (default is to place the missing key at the bottom
    or rightmost).

{phang2}
    {opt nomis:sing} omits the legend key for missing values.

{phang2}
    {opt nogap} omits the gap between the missing key and the other keys.

{phang2}
    {it:contents} and {it:location} options to affect the rendering of the
    legend as documented in {it:{help legend_option}}. For example, use option
    {opth bplace:ment(compassdirstyle)} to determine the placement of the
    legend. Note that {cmd:geoplot} compiles an own {cmd:order()} option,
    which will be overwritten if you specify {cmd:order()} manually; better do
    not specify {cmd:order()}.

{marker nolegend}{...}
{phang}
    {opt nolegend} suppresses the legend that is printed by default if at least one
    layer contains a color gradient.

{marker clegend}{...}
{phang}
    {opt clegend(suboptions)} prints a {help clegend_option:contour} plot legend
    of the colors used in one of the layers that include a
    {help geoplpot##cvar:{it:cvar}}. At most one such legend can be included
    in the graph (but you may use {cmd:legend()} to create a second
    legend). {it:suboptions} are as follows:

{phang2}
    {opt l:ayer(#)} selects the layer for which the legend be created. The default
    is to use the first layer containing a color gradient (unless already
    covered by {cmd:legend()}). For example, if your
    graph contains, say, five layers, and layers 3 and 4 have a
    {help geoplpot##cvar:{it:cvar}}, type {cmd:layer(4)} to create a legend
    for layer 4.

{phang2}
    {opth f:ormat(%fmt)} select the display format to be applied to the values
    in the legend labels. The default is to use the display format of
    {help geoplpot##cvar:{it:cvar}}.

{phang2}
    {opt nolab:el} omits the use value labels in case of a
    {help geoplpot##cvar:{it:cvar}} declared as
    {helpb geoplpot##discrete:discrete}.

{phang2}
    {opt mis:sing}[{cmd:(}{it:string}{cmd:)} requests that missing value is
    included in the legend and, optionally, specifies a custom label. The
    default label is {cmd:"no data"}.

{phang2}
    Further {it:suboptions} to affect the rendering of the
    legend as documented in {it:{help clegend_option}}. For example, use option
    {opth bplace:ment(compassdirstyle)} to determine the placement of the
    legend, or use options {opth width(size)} and {opth height(size)}
    to set the size of the legend.

{pmore}
    The rendering of the axis included in the contour legend is controlled by
    options specified outside of {cmd:clegend()}. In particular, use
    option {helpb axis_title_options:ztitle()} to set the axis title, options
    {helpb axis_label_options:zlabel()} and {helpb axis_label_options:ztick()}
    to affect the axis labels and ticks, and option
    {helpb axis_scale_options:zscale()} to control further aspects of the axis.

{marker frame}{...}
{phang}
    {cmd:frame(}{it:name}[{cmd:, replace}]{cmd:)} stores the compiled data of
    the plot in a {helpb frame} called {it:name}. Option {cmd:replace} allows overwriting
    an existing frame. Applying the command in {cmd:r(graph)} to the frame
    will reproduce the map.


{title:Examples}

{pstd}
    Load data

{p 8 12 2}
    {stata "local url http://fmwww.bc.edu/repec/bocode/i/"}
    {p_end}
{p 8 12 2}
    {stata geoframe create regions `url'Italy-RegionsData.dta, id(id) coord(xcoord ycoord) shpfile(`url'Italy-RegionsCoordinates.dta)}
    {p_end}
{p 8 12 2}
    {stata geoframe create country `url'Italy-OutlineCoordinates.dta}
    {p_end}
{p 8 12 2}
    {stata geoframe create capitals `url'Italy-Capitals.dta, coord(xcoord ycoord)}
    {p_end}
{p 8 12 2}
    {stata geoframe create lakes `url'Italy-Lakes.dta, feature(water)}
    {p_end}
{p 8 12 2}
    {stata geoframe create rivers `url'Italy-Rivers.dta, feature(water)}
    {p_end}

{pstd}
    Basic map of Italian regions

{p 8 12 2}
    {stata geoplot (area regions) (line country, lwidth(medthick)), tight}
    {p_end}

{pstd}
    Basic map with lakes and rivers

{p 8 12 2}
    {stata geoplot (area regions) (area lakes) (line rivers), tight}
    {p_end}

{pstd}
    Regions colored by number of fortune tellers (per million population)

{p 8 12 2}
    {stata geoplot (area regions fortell) (area regions), tight legend(bplace(ne))}
    {p_end}

{pstd}
    Similar graph with more colors and alternative type of legend (requires Stata 18)

{p 8 12 2}
    {stata geoplot (area regions fortell, levels(50) lcolor(gray)), tight clegend(bplace(ne)) zlabel(4(3)28)}
    {p_end}

{pstd}
    Map with provincial capitals

{p 8 12 2}
    {stata local layer1 (area regions)}
    {p_end}
{p 8 12 2}
    {stata local layer2 (point capitals [aw=pop98], cvar(size) discrete color(Set1, opacity(50)) mlcolor(%0))}
    {p_end}
{p 8 12 2}
    {stata local layer3 (labels capitals city if pop98>250000, color(black))}
    {p_end}
{p 8 12 2}
    {stata geoplot `layer1' `layer2' `layer3', tight legend(bplace(sw))}
    {p_end}


{title:Returned results}

{pstd}
    {cmd:geoplot} returns a copy of the called graph command in macro
    {cmd:r(graph)}.


{title:Author}

{pstd}
    Ben Jann, University of Bern, ben.jann@unibe.ch

{pstd}
    Thanks for citing this software as follows:

{pmore}
    Jann, B. (2023). geoplot: Stata module to draw maps. Available from
    {browse "https://github.com/benjann/geoplot/"}.


{title:Also see}

{psee}
    Online:  help for
    {helpb geoframe}, {helpb graph}, {helpb frames}, {helpb spshape2dta}
