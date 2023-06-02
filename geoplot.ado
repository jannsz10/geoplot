*! version 0.1.9  02jun2023  Ben Jann

capt which colorpalette
if _rc==1 exit _rc
local rc_colorpalette = _rc

capt findfile lcolrspace.mlib
if _rc==1 exit _rc
local rc_colrspace = _rc

capt mata: assert(mm_version()>=200)
if _rc==1 exit _rc
local rc_moremata = _rc

if `rc_colorpalette' | `rc_colrspace' | `rc_moremata' {
    if `rc_colorpalette' {
        di as err "{bf:colorpalette} is required; " _c
        di as err "type {stata ssc install palettes, replace}"
    }
    if `rc_colrspace' {
        di as err "{bf:colrspace} is required; " _c
        di as err "type {stata ssc install colrspace, replace}"
    }
    if `rc_moremata' {
        di as err "{bf:moremata} version 2.0.0 or newer is required; " _c
        di as err "type {stata ssc install moremata, replace}"
    }
    exit 499
}

program geoplot, rclass
    version 17
    _parse comma lhs 0 : 0
    syntax [, /*
        */ LEGend LEGend2(str asis) CLEGend CLEGend2(str asis) /*
        */ rotate(real 0) /* rotate whole map around midpoint by angle
        */ Margin(numlist max=4 >=0) tight /* margin: l r b t (will be recycled)
        */ ASPECTratio(str) YSIZe(passthru) XSIZe(passthru) SCHeme(passthru) /*
        */ frame(str) * ]
    local legend  = `"`legend'`legend2'"'!=""
    local clegend = `"`clegend'`clegend2'"'!=""
    if !`legend' & !`clegend' local legend 1
    _parse_aspectratio `aspectratio' // returns aspectratio, aspectratio_opts
    if "`margin'"=="" local margin 0
    _parse_frame `frame' // returns frame, replace
    
    // parse layers
    _parse expand layer lg : lhs
    if `"`lg_if'"'!="" {
        di as err "global {bf:if} not allowed"
        exit 198
    }
    if `"`lg_in'"'!="" {
        di as err "global {bf:in} not allowed"
        exit 198
    }
    if `"`lg_op'"'!="" {
        error 198
    }
    
    // prepare frame
    local cframe = c(frame)
    tempname main
    frame create `main'
    frame `main' {
        /* default variables:
            LAYER:   layer ID
            ID:      unit ID
            Y:       Y coordinate
            X:       X coordinate
            W:       weight
          further variables possibly generated along the way:
            PLV      plot level for enclaves and exclaves
            Z:       categorized zvar()
            Y2:      secondary Y coordinate (pc)
            X2:      secondary X coordinate (pc)
            MLAB:    marker labels
            MLABPOS: marker label positions
          helper variables that will be dropped at the end
            dY dX:   relative coordinates or non-rotating objects
        */
        gen byte LAYER = .
        char LAYER[Layers] `layer_n'
        gen byte ID = .
        gen double Y = .
        gen double X = .
        qui set obs 2
        gen double W = _n - 1 // 0 and 1
        
    // process layers
        local p 0
        local plots
        nobreak {
            capture noisily break {
                mata: _GEOPLOT_ColrSpace_S = ColrSpace() // global object
                forv i = 1/`layer_n' {
                    local ii `i' // for error message
                    gettoken plottype layer : layer_`i', parse(" ,")
                    _parse_plottype `plottype'
                    gettoken lframe : layer, parse(" ,[")
                    if `"`lframe'"'=="" {
                        // frame may have been specified as ""
                        gettoken lframe layer : layer, parse(" ,[")
                        local lframe `"`cframe'"'
                    }
                    else if inlist(`"`lframe'"', ",", "if", "in", "[") {
                        // leave layer as is
                        local lframe `"`cframe'"'
                    }
                    else {
                        // remove frame from layer
                        gettoken lframe layer : layer, parse(" ,[")
                        if `"`lframe'"'=="." local lframe `"`cframe'"'
                    }
                    _geoplot_`plottype' `i' `p' `lframe' `layer' // => plot, p
                    local plots `plots' `plot'
                }
            }
            local rc = _rc
            capt mata mata drop _GEOPLOT_ColrSpace_S // remove global object
            if `rc' {
                if `rc'!=1 {
                    di as err "(error in layer `ii': `plottype' ...)"
                }
                exit `rc'
            }
        }
        if !`p' {
            di as txt "(nothing to plot)"
            exit
        }
        
    // rotate and process relative (non-rotating) coordinates
        _rotate `rotate'
        capt confirm variable dY, exact
        if _rc==0 {
            qui replace Y = Y + dY if dY<.
            qui replace X = X + dX if dX<.
            drop dY dX
        }
        
    // graph dimensions
        _grdim "`margin'" `aspectratio' // returns yrange, xrange, aratio
        local aspectratio aspectratio(`aratio'`aspectratio_opts')
        if "`tight'"!="" {
            // update ysize and ysize
            _grdim_tight, aratio(`aratio') `scheme' `ysize' `xsize' 
        }
        
    // compile legend
        if `legend' {
            _legend, `legend2' // returns legend
        }
        else local legend legend(off)
        if `clegend' {
            _clegend, `clegend2' // returns plot, clegend
            local plots `plots' `plot'
        }
        else local clegend
        
    // draw graph
         local graph /*
            */ graph twoway `plots',/*
            */ `legend' `clegend' /*
            */ graphregion(margin(small) style(none) istyle(none))/*
            */ plotregion(margin(zero) style(none) istyle(none))/*
            */ bgcolor(white) `scheme'/*
            */ `yrange' `xrange' `aspectratio' `ysize' `xsize' `options'
        `graph'
    }
    
    // returns
    return local graph `graph'
    if "`frame'"!="" {
        local cframe `"`c(frame)'"'
        qui _frame dir
        local framelist = r(contents)
        if `:list frame in framelist' {
            if "`frame'"==`"`cframe'"' { // cannot drop current frame
                frame change `main'
            }
            frame drop `frame'
        }
        frame rename `main' `frame'
        di as txt "(graph data stored as frame {bf:`frame'})"
        if "`frame'"!=`"`cframe'"' {
            frame change `frame'
            di as txt "(current frame now {bf:`frame'})"
        }
    }
end

program _parse_aspectratio
    _parse comma lhs rhs : 0
    if `"`lhs'"'!="" {
        numlist "`lhs'", max(1)
        local lhs `r(numlist)'
    }
    else local lhs 1 // default
    c_local aspectratio `lhs'
    c_local aspectratio_opts `rhs'
end

program _parse_frame
    syntax [name(name=frame)] [, replace ]
    if "`frame'"=="" exit
    if "`replace'"=="" {
        qui _frame dir
        local framelist = r(contents)
        if `:list frame in framelist' {
            di as err "frame {bf:`frame'} already exists"
            exit 499
        }
    }
    c_local frame `frame'
    c_local replace `replace'
end

program _parse_plottype
    local l = strlen(`"`0'"')
    if      `"`0'"'==substr("scatter", 1, max(2,`l')) local 0 scatter
    else if `"`0'"'==substr("labels", 1, max(3,`l'))  local 0 labels
    capt mata: assert(st_islmname(st_local("0")))
    if _rc==1 exit _rc
    if _rc {
        di as err `"`0' invalid plottype"'
        exit 198
    }
    c_local plottype `"`0'"'
end

program _rotate
    if `0'==0 exit
    local r = `0' * _pi / 180
    tempname min max
    foreach v in Y X {
        su `v', mean
        scalar `min' = r(min)
        scalar `max' = r(max)
        capt confirm variable `v'2, exact
        if _rc==0 {
            su `v'2, mean
            scalar `min' = min(`min', r(min))
            scalar `max' = max(`max', r(max))
        }
        tempname `v'mid
        scalar ``v'mid' = (`max'-`min') / 2
    }
    tempvar y x
    qui gen double `y' = Y - `Ymid'
    qui gen double `x' = X - `Xmid'
    qui replace Y = (`x' * sin(`r') + `y' * cos(`r')) + `Ymid'
    qui replace X = (`x' * cos(`r') - `y' * sin(`r')) + `Xmid'
    capt confirm variable Y2, exact
    if _rc==0 {
        qui replace `y' = Y2 - `Ymid'
        qui replace `x' = X2 - `Xmid'
        qui replace Y2 = (`x' * sin(`r') + `y' * cos(`r')) + `Ymid'
        qui replace X2 = (`x' * cos(`r') - `y' * sin(`r')) + `Xmid'
    }
end

program _grdim
    args margin aratio
    tempname min max
    foreach v in X Y {
        tempname `v'min `v'max `v'range
        su `v', mean
        scalar ``v'min' = r(min)
        scalar ``v'max' = r(max)
        capt confirm variable `v'2, exact
        if _rc==0 {
            su `v'2, mean
            scalar ``v'min' = min(``v'min', r(min))
            scalar ``v'max' = max(``v'max', r(max))
        }
        scalar ``v'range' = ``v'max' - ``v'min'
        if "`MRG'"=="" local MRG `margin' // recycle
        gettoken m MRG : MRG
        scalar ``v'min' = ``v'min' - ``v'range' * (`m'/100)
        if "`MRG'"=="" local MRG `margin' // recycle
        gettoken m MRG : MRG
        scalar ``v'max' = ``v'max' + ``v'range' * (`m'/100)
    }
    c_local yrange yscale(off range(`=`Ymin'' `=`Ymax'')) ylabel(none)
    c_local xrange xscale(off range(`=`Xmin'' `=`Xmax'')) xlabel(none)
    c_local aratio = (`Ymax'-`Ymin') / (`Xmax'-`Xmin') * `aratio'
end

program _grdim_tight
     syntax, aratio(str) [ YSIZe(str) XSIZe(str) SCHeme(str) ]
     // ysize specified
     if `"`ysize'"'!="" {
         if `"`xsize'"'!="" exit // nothing to do
         local unit = substr(`"`ysize'"',-2,.)
         if inlist(`"`unit'"', "in", "pt", "cm") {
             local ysize = strtrim(substr(`"`ysize'"',1,strlen(`"`ysize'"')-2))
         }
         else local unit
         local xsize = `ysize' / `aratio'
         c_local xsize xsize(`xsize'`unit')
         exit
     }
     // xsize specified
     if `"`xsize'"'!="" {
         local unit = substr(`"`xsize'"',-2,.)
         if inlist(`"`unit'"', "in", "pt", "cm") {
             local xsize = strtrim(substr(`"`xsize'"',1,strlen(`"`xsize'"')-2))
         }
         else local unit
         local ysize = `xsize' * `aratio'
         c_local ysize ysize(`ysize'`unit')
         exit
     }
     // get ysize from scheme
     if `"`scheme'"'=="" local scheme `"`c(scheme)'"'
     if `"`.__SCHEME.scheme_name'"'!=`"`scheme'"' {
         qui .__SCHEME = .scheme.new, scheme(`scheme')
     }
     local ysize `.__SCHEME.graphsize.y'
     if `"`ysize'"'=="" local ysize 4.5
     local xsize = `ysize' / `aratio'
     c_local ysize ysize(`ysize')
     c_local xsize xsize(`xsize')
end

program _legend
    // syntax
    syntax [, off Layout(str asis) HORizontal OUTside POSition(str)/*
        */ SIze(passthru) SYMYsize(passthru) SYMXsize(passthru)/*
        */ KEYGap(passthru) COLGap(passthru) ROWGap(passthru)/*
        */ BMargin(passthru) REGion(passthru)/*
        */ order(passthru) HOLes(passthru) Cols(passthru)/* will be ignored
        */ Rows(passthru) BPLACEment(passthru)/* will be ignored
        */ on all NOCOLFirst COLFirst/* will be ignored
        */ * ]
    if `"`off'"'!="" {
        c_local legend legend(off)
        exit
    }
    foreach opt in order holes cols rows bplacement on all nocolfirst colfirst {
        local `opt'
    }
    // select layer if layer() is empty
    local zlayers: char LAYER[Layers_Z]
    if `"`layout'"'=="" {
        gettoken layout : zlayers // first layer containing Z
        if "`layout'"=="" {
            c_local legend legend(off)
            exit
        }
    }
    // compile legend
    local LAYOUT
    local ncols 0
    local kmax 0
    local nkeys 0
    // - first analyze layout
    while (1) {
        gettoken l layout : layout, parse(".|- ")
        if `"`l'"'=="" continue, break
        if `"`l'"'=="." {
            local ++nkeys
            local LAYOUT `LAYOUT' .
        }
        else if `"`l'"'=="|" {
            if !`nkeys' continue // ignore empty columns
            local ++ncols
            local kmax = max(`kmax', `nkeys')
            local nkeys 0
            local LAYOUT `LAYOUT' |
        }
        else if `"`l'"'=="-" {
            gettoken l : layout, quotes qed(hasquotes)
            local titl
            local space
            while (`hasquotes') {
                gettoken l layout : layout, quotes
                local titl `"`titl'`space'`l'"'
                local space " "
                gettoken l : layout, quotes qed(hasquotes)
            }
            local LAYOUT `LAYOUT' - `"`titl'"'
            local ++nkeys
        }
        else {
            capt n numlist `"`l'"', int range(>0)
            if _rc==1 exit 1
            if _rc {
                di as err "(error in legend(layer()))"
                exit _rc
            }
            local L `r(numlist)'
            foreach l of local L {
                local lsize: char LAYER[Lsize_`l']
                if `"`lsize'"'=="" continue
                if !`lsize' continue
                local nkeys = `nkeys' + `lsize'
                local LAYOUT `LAYOUT' `l'
            }
        }
    }
    if `nkeys' { // close last column
        local ++ncols
        local kmax = max(`kmax', `nkeys')
        local LAYOUT `LAYOUT' |
    }
    if !`kmax' { // legend is empty
        c_local legend legend(off)
        exit
    }
    local nkeys 0
    while (1) {
        gettoken l LAYOUT : LAYOUT
        if `"`l'"'=="" continue, break
        if `"`l'"'=="." {
            local ++nkeys
            local order `order' - " "
        }
        else if `"`l'"'=="|" {
            while (`nkeys'<`kmax') {
                local ++nkeys
                local order `order' - " "
            }
            local nkeys 0
        }
        else if `"`l'"'=="-" {
            gettoken l LAYOUT : LAYOUT
            local ++nkeys
            local order `order' - `l'
        }
        else {
            local nkeys = `nkeys' + `: char LAYER[Lsize_`l']'
            local order `order' `: char LAYER[Legend_`l']'
        }
    }
    // orientation / layout
    if `"`size'"'==""     local size size(vsmall)
    if `"`symysize'"'=="" local symysize symysize(3)
    if `"`symxsize'"'=="" local symxsize symxsize(3)
    if `"`keygap'"'==""   local keygap keygap(1)
    if `"`colgap'"'==""   local colgap colgap(2)
    if "`horizontal'"!="" {
        local opts rows(`ncols') nocolfirst
    }
    else {
        local opts cols(`ncols') colfirst
        if `"`rowgap'"'=="" local rowgap rowgap(0)
    }
    local opts `opts' `size' `symysize' `symxsize' `keygap' `colgap' `rowgap'
    if `"`position'"'=="" local position 2
    if "`outside'"!=""    local position position(`position')
    else                  local position position(0) bplace(`position')
    if `"`bmargin'"'==""  local bmargin bmargin(zero)
    if `"`region'"'==""   local region region(style(none) margin(zero))
    local opts `opts' `position' `bmargin' `region' `options'
    // return legend option
    c_local legend legend(order(`order') on all `opts')
end

program _clegend
    if c(stata_version)<18 {
        di as err "{bf:clegend()} requires Stata 18"
        exit 9
    }
    // syntax
    syntax [, off Layer(numlist int max=1 >0) noLABel MISsing Format(str)/*
        */ OUTside POSition(str) width(passthru) height(passthru)/*
        */ BMargin(passthru) REGion(passthru)/*
        */ BPLACEment(passthru) * ]
    if `"`off'"'!="" {
        c_local clegend
        c_local plot
        exit
    }
    local bplacement
    // select layer
    local k `layer'
    local clayers: char LAYER[Layers_C]
    if "`k'"=="" gettoken k : clayers // first layer that has colors
    else local k: list k & clayers
    if "`k'"=="" {
        if "`layer'"!="" di as txt /*
            */"(clegend omitted; layer `layer' does not contain color gradient)"
        else di as txt /*
            */ "(clegend omitted; no layer containing color gradient found)"
        c_local clegend
        c_local plot
        exit
    }
    // collect info on levels, colors, and labels
    local values:   char LAYER[Values_`k']
    local colors:   char LAYER[Colors_`k']
    local hasmis:   char LAYER[Hasmis_`k']
    local discrete: char LAYER[Discrete_`k']
    if `hasmis' {
        if `"`missing'"'=="" {
            if !`: list sizeof colors' {
                di as txt "(clegend omitted: "/*
                    */ "layer `k' contains no non-missing color keys)"
                c_local clegend
                c_local plot
                exit
            }
            local hasmis 0
        }
    }
    if `hasmis' {
        local labmis:   char LAYER[Labmis_`k']
        if `: list sizeof labmis'>1 {
            local labmis `"`"`labmis'"'"'
        }
        local colors `"`:char LAYER[Colmis_`k']' `colors'"'
    }
    if `discrete' {
        if "`label'"=="" local LABELS: char LAYER[Labels_`k']
        else             local LABELS `values'
        local i 0
        foreach lbl of local LABELS {
            local labels `labels' `i'.5 `"`lbl'"'
            local ++i
        }
    }
    if `"`format'"'!="" {
        capt confirm numeric format `format'
        if _rc local format
    }
    else local format: char LAYER[Format_`k']
    if `"`format'"'=="" local format format(%7.0g)
    else                local format format(`format')
    // append data for clegend plot
    qui gen byte CLEG_Y = .
    qui gen byte CLEG_X = .
    qui gen double CLEG_Z = .
    local K: list sizeof values
    local N = `K' + `discrete' + `hasmis' 
    if `N'>_N {
        set obs `N'
    }
    if `discrete' {
        qui replace CLEG_Z = .0001
        local values 0
        forv i = 1/`K' {
            qui replace CLEG_Z = `i' in `=`i'+1'
            local values `values' `i'
        }
        local i = `K' + 1
        if `hasmis' {
            local ++i
            qui replace CLEG_Z = 0 in 1
            qui replace CLEG_Z = -.9999 in `i'
            local labels -.5 `labmis' `labels'
            local values -1 `values'
        }
        local hght = min(100, (`N'-`hasmis')*3)
        local zlabels zlabel(`labels', `format' labsize(vsmall) notick labgap(1))/*
            */ zscale(noline)
    }
    else {
        local labels `values'
        if `hasmis' {
            local K: list sizeof values
            local v0: word 1 of `values'
            local v: word `K' of `values'
            local v0 = `v0'- (`v'-`v0')/`K'
            local values `v0' `values'
            local labels `v0' `labmis' `labels'
        }
        gettoken v0 VALUES : values
        gettoken v         : VALUES
        qui replace CLEG_Z = `v0' + (`v'-`v0')/10000 in 1 /* shift first point
            slightly up */
        local i 1
        foreach v of local VALUES {
            local ++i
            qui replace CLEG_Z = `v' in `i'
        }
        local hght = min(40, (`N'-`hasmis')*3)
        local zlabels zlabel(`labels', `format' labsize(vsmall))
    }
    // layout of clegend
    if `"`position'"'==""  local position 4
    if "`outside'"!=""     local position position(`position')
    else                   local position position(0) bplace(`position')
    if `"`width'"'==""     local width width(3)
    if `"`height'"'==""    local height height(`hght')
    if `"`bmargin'"'==""   local bmargin bmargin(l=0 r=0 b=1 t=1)
    if `"`region'"'==""    local region region(margin(zero))
    local options `position' `width' `height' `bmargin' `region' `options'
    // return clegend plot and clegend option
    c_local plot (scatter CLEG_Y CLEG_X in 1/`i', colorvar(CLEG_Z)/*
        */ colorcuts(`values') colorlist(`colors') colorkeysrange)
    c_local clegend ztitle("") `zlabels' clegend(`options')
end

program _process_coloropts // pass standard color options through ColrSpace
    _parse comma nm 0 : 0
    local opts COLor FColor LColor MColor MFColor MLColor MLABColor
    foreach o of local opts {
        local OPTS `OPTS' `o'(str asis)
    }
    syntax [, `OPTS' * ]
    local opts = strlower("`opts'")
    local OPTS
    foreach o of local opts {
        if `"``o''"'!="" {
            mata: _get_colors("`o'")
            local OPTS `OPTS' `o'(``o'')
        }
    }
    c_local `nm' `OPTS' `options'
end

program _geoplot_area
    _layer area `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_line
    _layer line `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_point
    _layer scatter `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_scatter
    _layer scatter `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_labels
    gettoken layer 0 : 0
    gettoken p 0 : 0
    gettoken frame 0 : 0
    gettoken mlabl 0 : 0, parse(" ,[")
    if inlist(`"`mlabl'"', "", ",", "if", "in", "[") {
        di as err "label: variable name containing labels required"
        exit 198
    }
    _parse comma lhs 0 : 0
    syntax [, /*
        */ POSition(str) VPOSition(str) gap(str) ANGle(str) TSTYle(str) /*
        */ SIze(str) COLor(str) Format(str) * ]
    if `"`position'"'=="" local position 0
    foreach opt in position vposition gap angle size color format {
        if `"``opt''"'!="" local `opt' mlab`opt'(``opt'')
    }
    if `"`tstyle'"'!="" local tstyle mlabtextstyle(`tstyle')
    _layer scatter `layer' `p' `frame' `lhs', /*
        */ msymbol(i) mlabel(`mlabl') `position' `vposition' `gap' /*
        */ `angle' `tstyle' `size' `color' `format' /*
        */ `options'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_pcspike
    _layer pcspike `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_pccapsym
    _layer pccapsym `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_pcarrow
    _layer pcarrow `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_pcbarrow
    _layer pcbarrow `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_pcpoint
    _layer pcscatter `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_pcscatter
    _layer pcscatter `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_pointi
    _layeri scatteri `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_scatteri
    _layeri scatteri `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_pci
    _layeri pci `0'
    c_local plot `plot'
    c_local p `p'
end

program _geoplot_pcarrowi
    _layeri pcarrowi `0'
    c_local plot `plot'
    c_local p `p'
end

program _layeri
    gettoken plottype 0 : 0
    gettoken layer 0 : 0
    gettoken p 0 : 0
    _parse comma lhs 0 : 0
    syntax [, LABel(str asis) * ]
    _process_coloropts options, `options'
    local ++p
    _parse_label `label'
    _add_quotes label `label'
    if `"`label'"'=="" local label `""""'
    local legend `p' `label'
    local lsize 1
    char LAYER[Keys_`layer'] `p'
    char LAYER[Legend_`layer'] `legend'
    char LAYER[Lsize_`layer'] `lsize'
    c_local p `p'
    c_local plot (`plottype' `lhs', `options')
end

program _layer
    // setup
    gettoken plottype 0 : 0
    gettoken layer 0 : 0
    gettoken p 0 : 0
    gettoken frame 0 : 0
    local hasSHP 0
    local TYPE
    local SIZEopt
    local hasPLV 0
    local PLVopts
    local WGT
    local MLABopts
    local Zopts Zvar(varname numeric) COLORVar(varname numeric)/*
        */ LEVels(str) cuts(numlist sort min=2) DISCRete MISsing(str asis) /*
        */ COLor COLor2(str asis) LWidth(passthru) LPattern(passthru)
    local Zel color lwidth lpattern
    local zvlist 1
    local YX Y X // coordinate variable names used in plot data
    if `"`plottype'"'=="area" {
        local TYPE   shape
        local hasSHP 1
        local SIZEopt size(str asis)
        local hasPLV 1
        local PLVopts FColor(str asis) EColor(str asis)
        local varlist [varlist(default=none numeric max=1)]
        local WGT [iw/]
        local Zopts `Zopts' FIntensity(passthru)
        local Zel `Zel' fintensity
        local zvlist 1
    } 
    else if `"`plottype'"'=="line" {
        local TYPE   shape
        local hasSHP 1
        local SIZEopt size(str asis)
        local varlist [varlist(default=none numeric max=1)]
        local WGT [iw/]
        local WGTopt wmax(numlist max=1 >0)
        local zvlist 1
    }
    else {
        if substr(`"`plottype'"',1,2)=="pc" { // paired coordinate plot
            local TYPE pc
            local varlist [varlist(default=none max=4 numeric)]
            local YX  Y  X Y2 X2 // variable names used in plot data
        }
        else {  // scatter assumed
            local TYPE unit
            local varlist [varlist(default=none max=2 numeric)]
            local WGT [iw/]
            local WGTopt wmax(numlist max=1 >0)
            local wgt "[aw=W]"
        }
        local MLABopts MLabel(varname) MLABVposition(varname numeric) /*
            */ MLABFormat(str)
        local Zopts `Zopts' Msymbol(passthru) MSIZe(passthru) /*
            */ MSAngle(passthru) MLWidth(passthru) MLABSize(passthru) /*
            */ MLABANGle(passthru) MLABColor(passthru)
        local Zel `Zel' msymbol msize msangle mlwidth mlabsize mlabangle/*
            */ mlabcolor
    }
    frame `frame' {
        // syntax
        qui syntax `varlist' [if] [in] `WGT' [, LABel(str asis) `Zopts'/*
            */ `SIZEopt' `WGTopt' `PLVopts' `MLABopts' * ]
        local cuts: list uniq cuts
        _parse_size `size' // => size, s_max, s_scale
        local hasSIZE = `"`size'"'!=""
        _parse_levels `levels' // => levels, method, l_wvar
        if `"`fcolor'"'!="" mata: _get_colors("fcolor")
        marksample touse, novarlist
        geoframe get feature, l(FEATURE)
        // check Z
        if `"`colorvar'"'!="" {
            local color color
            if "`zvar'"=="" local zvar `colorvar'
        }
        if `zvlist' {
            if "`zvar'"=="" local zvar `varlist'
            local varlist
        }
        local hasZ = `"`zvar'"'!=""
        if `"`color2'"'!=""   local color color(`color2')
        else if "`color'"!="" local color color()
        local color2
        // check shpframe
        if `hasSHP' {
            geoframe get shpframe, local(shpframe)
            local hasSHP = `"`shpframe'"'!=""
        }
        if `hasSHP' {
            local org `touse'
            local tgt `touse'
        }
        else local shpframe `frame'
        // handle coordinates, PLV, and unit ID
        frame `shpframe' {
            if "`TYPE'"=="pc" local typeSHP pc // enforce pc
            else {
                geoframe get type, local(typeSHP)
                if `"`typeSHP'"'=="" local typeSHP `TYPE'
            }
            if "`varlist'"!="" local yx `varlist'
            else geoframe get coordinates, strict flip local(yx) `typeSHP'
            if `:list sizeof yx'!=`: list sizeof YX' {
                di as err "wrong number of coordinate variables"
                exit 498
            }
            local ORG `yx'
            local TGT `YX'
            _get_PLV `hasPLV' `hasZ' `"`fcolor'"' `"`FEATURE'"' // => PLV
            if `hasPLV' {
                local ORG `ORG' `PLV'
                local TGT `TGT' PLV
            }
            geoframe get id, local(ID)
            if "`ID'"!="" {
                local ORG `ORG' `ID'
                local TGT `TGT' ID
            }
        }
        // handle weights
        local hasWGT = "`weight'"!=""
        if `hasWGT' {
            tempname wvar
            qui gen double `wvar' = abs(`exp') if `touse'
            markout `touse' `wvar'          // exclude obs with missing weight!
            if `"`wmax'"'=="" {
                su `wvar' if `touse', meanonly
                local wmax = max(1, r(max))
            }
            qui replace `wvar' = `wvar' / `wmax' if `touse'
            if `hasSHP' {
                tempname WVAR
                local org `org' `wvar'
                local tgt `tgt' `WVAR'
            }
            else local WVAR `wvar'
            local ORG `ORG' `WVAR'
            local TGT `TGT' W
        }
        else local wgt
        // handle Z
        if `hasZ' {
            local zfmt: format `zvar'
            if `hasSHP' {
                tempname ZVAR
                local org `org' `zvar'
                local tgt `tgt' `ZVAR'
            }
            else local ZVAR `zvar'
            local ORG `ORG' `ZVAR'
            local TGT `TGT' Z
            if "`l_wvar'"!="" {
                tempname L_WVAR
                if `hasSHP' {
                    local org `org' `l_wvar'
                    local tgt `tgt' `L_WVAR'
                    local ORG `ORG' `L_WVAR'
                }
                else local ORG `ORG' `l_wvar'
                local TGT `TGT' `L_WVAR'
           }
        }
        else {
            foreach el of local Zel {
                if `"``el''"'=="" continue
                local options ``el'' `options'
                local `=strupper("`el'")' `el'
                local `el'
            }
        }
        // handle size
        if `hasSIZE' {
            geoframe get area, local(AREA)
            if !`: list sizeof AREA' {
                di as txt "layer `layer': area variable (original size) not"/*
                    */ " found; computing areas on the fly"
                di as txt "generate/declare area variable using " /*
                    */ "{helpb geoframe} to avoid such extra computations"
                tempvar AREA
                qui geoframe gen area `AREA', noset
            }
            tempname svar
            qui gen double `svar' = abs(`size') / `AREA' if `touse'
            if `"`s_max'"'=="" {
                su `svar' if `touse', meanonly
                local s_max = r(max)
            }
            qui replace `svar' = `svar' * (`s_scale'/`s_max') if `touse'
            if `hasSHP' {
                tempname SVAR
                local Svar `SVAR'
                local org `org' `svar'
                local tgt `tgt' `SVAR'
            }
            else {
                local SVAR `svar'
                tepname Svar
            }
            local ORG `ORG' `SVAR'
            local TGT `TGT' `Svar' // tempvar only
        }
        // get centroids (used by weights and size() in area/line)
        if (`hasWGT' & ("`TYPE'"=="shape")) | `hasSIZE' {
            geoframe get centroids, flip local(cYX)
            if !`: list sizeof cYX' {
                di as txt "layer `layer': centroids not found;"/*
                    */ " computing centroids on the fly"
                di as txt "generate/declare centroids using " /*
                    */ "{helpb geoframe} to avoid such extra computations"
                tempvar tmp_CX tmp_CY
                qui geoframe gen centroids `tmp_CX' `tmp_CY', noset
                local cYX `tmp_CY' `tmp_CX'
            }
            if `hasSHP' {
                tempname CY CX
                local cY `CY'
                local cX `CX'
                local org `org' `cYX'
                local tgt `tgt' `CY' `CX'
            }
            else {
                gettoken CY cYX : cYX
                gettoken CX cYX : cYX
                tempname cY cX
            }
            local ORG `ORG' `CY' `CX'
            local TGT `TGT' `cY' `cX' // tempvars only
        }
        // handle marker labels
        local hasMLAB = `"`mlabel'"'!=""
        if `hasMLAB' {
            if `"`mlabformat'"'!="" confirm format `mlabformat'
            if "`mlabvposition'"!="" {
                if `hasSHP' {
                    tempname MLABPOS
                    local org `org' `mlabvposition'
                    local tgt `tgt' `MLABPOS'
                }
                else local MLABPOS `mlabvposition'
                local ORG `ORG' `MLABPOS'
                local TGT `TGT' MLABPOS
            }
            tempname MLAB
            qui gen strL `MLAB' = ""
            mata: _generate_mlabels("`MLAB'", "`mlabel'", "`mlabformat'",/*
                */ "`touse'")
            if `hasSHP' {
                tempname MLAB
                local org `org' `MLAB'
                local tgt `tgt' `MLAB'
            }
            local ORG `ORG' `MLAB'
            local TGT `TGT' MLAB
        }
        // inject colors
        _process_coloropts options, `options'
        if `"`fcolor'"'!="" {
            local options fcolor(`fcolor') `options'
        }
    }
    // copy data
    if `hasSHP' {
        // copy relevant variables from unit frame into shape frame
        qui frame `shpframe': geoframe copy `frame' `org', target(`tgt')
        qui frame `shpframe': replace `touse' = 0 if `touse'>=. 
    }
    local n0 = _N + 1
    qui geoframe append `shpframe' `ORG', target(`TGT') touse(`touse')
    local n1 = _N
    if "`TYPE'"=="shape" { // only if plottype area or line
        if !inlist(`"`typeSHP'"', "unit", "pc") { // only if data not unit or pc
            if "`ID'"!="" { // only if ID variable is available
                // remove units without shape data (i.e. units that only have
                // a single observation and for which the coordinate variables
                // are missing)
                mata: _drop_empty_shapes(`n0', `n1', "ID", tokens("`YX'"))
            }
        }
    }
    local n1 = _N
    if `n1'<`n0' {
        c_local plot
        c_local p `p'
        di as txt "(layer `layer' is empty)"
        exit
    }
    local in in `n0'/`n1'
    qui replace LAYER = `layer' `in'
    // process size (area/line only)
    if `hasSIZE' {
        qui replace Y = `cY' + (Y-`cY') * sqrt(`Svar') if `Svar'<. `in'
        qui replace X = `cX' + (X-`cX') * sqrt(`Svar') if `Svar'<. `in'
    }
    // process weights (area/line only)
    if `hasWGT' & ("`TYPE'"=="shape") {
        qui replace Y = `cY' + (Y-`cY') * sqrt(W) if W<. & `cY'<. & `cX'<. `in'
        qui replace X = `cX' + (X-`cX') * sqrt(W) if W<. & `cY'<. & `cX'<. `in'
    }
    // prepare PLV
    if `hasPLV' {
        if `"`ecolor'"'=="" local ecolor white // default for enclaves
        mata: _get_colors("ecolor")
        qui replace PLV = 0 if PLV>=. `in' // treat missing as 0
        qui levelsof PLV `in'
        local plevels `r(levels)'
    }
    else local plevels .
    // handle Z elements
    local opts
    if `hasZ' {
        // - categorize Z
        tempname CUTS
        mata: _z_cuts("`CUTS'", (`n0', `n1')) // => CUTS, cuts, levels
        _z_categorize `CUTS' `in', levels(`levels') `discrete'
            // => zlevels hasmis discrete
        if `discrete' {
            frame `frame': _z_labels `zvar' `cuts' // => zlabels
        }
        // - process options
        if `levels' {
            local ZEL
            foreach el of local Zel {
                if "`el'"=="mlabcolor" {
                    if `hasMLAB' {
                        if `"`COLOR'"'!="" {
                            // color() takes precedence over mlabcolor()
                            _process_coloropts mlabcolor, `mlabcolor'
                            local opts mlabcolor(`mlabcolor')
                            local mlabcolor `"`color'"'
                        }
                        else {
                            if `"``el''"'=="" continue
                            _z_colors `levels' mlabcolor `mlabcolor'
                            local color `"`mlabcolor'"'
                        }
                    }
                    else {
                        local mlabcolor
                        continue
                    }
                }
                else {
                    if `"``el''"'=="" continue
                    if "`el'"=="color"/*
                        */ _z_colors `levels' color `color'
                    else _z_recycle `levels' `el', ``el''
                }
                if `: list sizeof `el''==0 continue
                local `=strupper("`el'")' `el'
                local ZEL `ZEL' `el'
            }
        }
        // - process hasmis
        if `hasmis' z_parse_missing `plottype', `missing' /*
            => missing missing_color missing_lab */
    }
    else local zlevels 0
    // Set default options
    if `"`plottype'"'=="area" {
        local opts cmissing(n) nodropbase lalign(center) `opts'
        if `"`FEATURE'"'=="water" {
            if "`COLOR'"=="" local opts color("135 206 235") `opts' // SkyBlue
            if "`FINTENSITY'"=="" local opts finten(50) `opts'
            if "`LWIDTH'"=="" local opts lwidth(thin) `opts'
        }
        else {
            if "`COLOR'"=="" {
                local opts lcolor(gray) `opts'
                if `"`fcolor'"'=="" local opts fcolor(none) `opts'
            }
            if "`FINTENSITY'"=="" local opts finten(100) `opts'
            if "`LWIDTH'"=="" {
                local opts lwidth(thin) `opts'
                if `hasZ' local opts lcolor(%0) `opts'
            }
        }
        if "`LPATTERN'"=="" local opts lpattern(solid) `opts'
    }
    else if "`plottype'"'=="line" {
        local opts `opts' cmissing(n)
        if "`COLOR'"=="" {
            if `"`FEATURE'"'=="water"/*
                */ local opts color("135 206 235") `opts' // SkyBlue
            else   local opts lcolor(gray) `opts'
        }
        if "`LWIDTH'"==""   local opts lwidth(thin) `opts'
        if "`LPATTERN'"=="" local opts lpattern(solid) `opts'
    }
    if `hasMLAB' {
        if "`mlabel'"!=""        local opts `opts' mlabel(MLAB)
        if "`mlabvposition'"!="" local opts `opts' mlabvposition(MLABPOS)
        if "`mlabformat'"!=""    local opts `opts' mlabformat(`mlabformat')
    }
    // compile plot
    if `hasWGT' local in inrange(_n,`n0',`n1')) | (_n<3)
    local plot
    local p0 = `p' + 1
    gettoken pl0 : plevels
    foreach pl of local plevels {
        local iff
        if `pl'<. {
            local iff PLV==`pl'
            local enclave = mod(`pl',2)
        }
        else local enclave 0
        if `hasZ' {
            foreach el of local ZEL {
                local EL = strupper("`el'")
                local `EL': copy local `el'
            }
        }
        foreach i of local zlevels {
            local IFF `iff'
            if `hasZ' {
                if `i'==0 local OPTS `missing' // missing
                else {
                    local OPTS
                    foreach el of local ZEL {
                        local EL = strupper("`el'")
                        gettoken tmp `EL' : `EL', quotes
                        local OPTS `OPTS' `el'(`tmp')
                    }
                    local OPTS `opts' `OPTS'
                }
                if `"`IFF'"'!="" local IFF `IFF' & Z==`i'
                else             local IFF Z==`i'
                if `pl'!=`pl0' {
                    // skip empty plots in additional layers
                    qui count `IFF' `in'
                    if r(N)==0 continue
                }
            }
            else local OPTS `opts'
            if `hasWGT' {
                if `"`IFF'"'!=""  local IFF if (`IFF' & `in'
                else              local IFF if (`in'
            }
            else if `"`IFF'"'!="" local IFF if `IFF' `in'
            else                  local IFF `in'
            local IFF `IFF' `wgt'
            if `enclave' local OPTS `OPTS' fcolor(`ecolor')
            local OPTS `OPTS' `options'
            if `"`OPTS'"'!="" {
                local IFF `IFF', `OPTS'
            }
            local plot `plot' (`plottype' `YX' `IFF')
            local ++p
        }
        if `pl'==`pl0' local p1 `p'
    }
    numlist "`p0'/`p1'"
    local keys `r(numlist)'
    // compile legend keys
    _parse_label `label'
    if `hasZ' {
        local lkeys: copy local keys
        if `"`format'"'=="" local format `zfmt'
        if `hasmis'    gettoken mis_key lkeys : lkeys
        if `nomissing' local mis_key
        local legend
        local lsize 0
        if `discrete' {
            _label_separate `label' // => lab_keys, lab_lbls
            if "`nolabels'"!="" local lbls: copy local cuts
            else                local lbls: copy local zlabels
            local i 0
            foreach key of local lkeys {
                local ++i
                gettoken lbl lbls : lbls
                capt confirm number `lbl'
                if _rc==0 {
                    local lbl `: di `format' `lbl''
                }
                mata: _get_lbl("`i'", "lab_keys", "lab_lbls", `"`"`lbl'"'"')
                if `reverse' local legend `legend' `key' `lbl'
                else         local legend `key' `lbl' `legend'
                local ++lsize
            }
        }
        else {
            if `"`label'"'=="" local label 1 "[@lb,@ub]"
            _label_separate `label' // => lab_keys, lab_lbls
            local CUTS: copy local cuts
            gettoken lb CUTS : CUTS
            local i 0
            foreach key of local lkeys {
                local ++i
                gettoken ub CUTS : CUTS
                local mid `: di `format' (`ub'+`lb')/2'
                local lb  `: di `format' `lb''
                local ub  `: di `format' `ub''
                mata: _get_lbl("`i'", "lab_keys", "lab_lbls", `""(@lb,@ub]""')
                local lbl: subinstr local lbl "@lb" "`lb'", all
                local lbl: subinstr local lbl "@ub" "`ub'", all
                local lbl: subinstr local lbl "@mid" "`mid'", all
                if `reverse' local legend `legend' `key' `lbl'
                else         local legend `key' `lbl' `legend'
                local lb `ub'
                local ++lsize
            }
        }
        if "`mis_key'"!="" {
            local mis_key `mis_key' `missing_lab'
            if `gap' {
                if `mfirst' local legend - " " `legend'
                else        local legend `legend' - " "
                local ++lsize
            }
            if `mfirst' local legend `mis_key' `legend'
            else        local legend `legend' `mis_key'
            local ++lsize
        }
    }
    else {
        _add_quotes label `label'
        if `"`label'"'=="" local label `""`frame'""'
        local legend `p1' `label'
        local lsize 1
    }
    // return results
    char LAYER[Keys_`layer'] `keys'
    char LAYER[Legend_`layer'] `legend'
    char LAYER[Lsize_`layer'] `lsize'
    if `hasZ' {
        char LAYER[Layers_Z] `:char LAYER[Layers_Z]' `layer'
        char LAYER[Discrete_`layer'] `discrete'
        char LAYER[Hasmis_`layer'] `hasmis'
        char LAYER[Format_`layer'] `zfmt'
        char LAYER[Values_`layer'] `cuts'
        char LAYER[Labels_`layer'] `"`zlabels'"'
        char LAYER[Labmis_`layer'] `"`missing_lab'"'
        if `"`color'"'!="" {
            char LAYER[Layers_C] `:char LAYER[Layers_C]' `layer'
            char LAYER[Colors_`layer'] `"`color'"'
            char LAYER[Colmis_`layer'] `"`missing_color'"'
        }
    }
    c_local plot `plot'
    c_local p `p'
end

program _parse_size
    _parse comma size 0 : 0
    c_local size `"`size'"'
    if `"`size'"'=="" exit
    syntax [, Dmax(numlist max=1 >0) Scale(numlist max=1 >0) ]
    if "`scale'"=="" local scale 1
    c_local s_max `dmax'
    c_local s_scale `scale'
end

program _parse_levels
    if `"`0'"'=="" exit
    capt n __parse_levels `0'
    if _rc==1 exit _rc
    if _rc {
        di as err "(error in option levels())"
        exit _rc
    }
    c_local levels `levels'
    c_local method `method'
    c_local l_wvar `l_wvar'
end

program __parse_levels
    _parse comma n 0 : 0
    if `"`n'"'!="" {
        numlist `"`n'"', int min(0) max(1) range(>0)
        local n "`r(numlist)'"
    }
    else local n .
    local methods Quantiles Kmeans //Jenks
    syntax [, `methods' Weight(varname numeric) ]
    local methods = strlower("`methods'")
    foreach m of local methods {
        local method `method' ``m''
    }
    if `:list sizeof method'>1 {
        di as err "too many methods specified; only one method allowed"
        exit 198
    }
    if "`method'"=="kmeans" {
        if "`weight'"!="" {
            di as err "{bf:weight()} not allowed with method {bf:kmeans}"
            exit 198
        }
    }
    c_local levels `n'
    c_local method `method'
    c_local l_wvar `weight'
end

program _z_categorize
    syntax anything(name=CUTS) in, levels(str) [ discrete ]
    tempname tmp
    qui gen byte `tmp' = . `in'
    if "`discrete'"!="" {
        forv i=1/`levels' {
            qui replace `tmp' = `i' if Z==`CUTS'[1,`i'] `in'
        }
    }
    else {
        forv i=1/`levels' {
            if `i'==1 local iff inrange(Z, `CUTS'[1,`i'], `CUTS'[1,`i'+1])
            else      local iff Z>`CUTS'[1,`i'] & Z<=`CUTS'[1,`i'+1]
            qui replace `tmp' = `i' if `iff' `in'
        }
    }
    local hasmis 0
    qui count if Z>=. `in'
    if r(N) { // set missings to 0
        qui replace `tmp' = 0 if Z>=. `in'
        local hasmis 1
    }
    qui replace Z = `tmp' `in'
    numlist "`=1-`hasmis''/`levels'"
    c_local zlevels `r(numlist)'
    c_local hasmis `hasmis'
    c_local discrete = "`discrete'"!=""
end

program _get_PLV
    args hasPLV hasZ fcolor FEATURE
    if !`hasPLV' exit
    if `hasZ' {
        if strtrim(`"`fcolor'"')=="none" local hasPLV 0
    }
    else {
        if `"`fcolor'"'=="" & `"`FEATURE'"'!="water" local hasPLV 0
        else if strtrim(`"`fcolor'"')=="none"        local hasPLV 0
    }
    if `hasPLV' {
        geoframe get plevel, l(PLV)
        if "`PLV'"=="" local hasPLV 0
    }
    c_local hasPLV `hasPLV'
    c_local PLV `PLV'
end

program _z_labels
    gettoken var 0 : 0
    local labname: value label `var'
    if `"`labname'"'=="" {
        local labels `0'
    }
    else {
        local labels
        local space
        foreach val of local 0 {
            local lab: label `labname' `val'
            local labels `"`labels'`space'`"`lab'"'"'
            local space " "
        }
    }
    c_local zlabels `"`labels'"'
end

program _z_colors
    gettoken levels 0 : 0
    gettoken nm 0 : 0
    local 0 `", `0'"'
    syntax [, `nm'(str asis) ]
    _parse comma color 0 : `nm'
    if `"`color'"'=="" local color viridis
    syntax [, NOEXPAND n(passthru) IPolate(passthru) * ]
    if "`noexpand'"=="" local noexpand noexpand
    if `"`n'`ipolate'"'=="" local n n(`levels')
    colorpalette `color', nograph `noexpand' `n' `ipolate' `options'
    local color `"`r(p)'"'
    if `:list sizeof color'<`levels' {
        // recycle or interpolate colors if too few colors have been obtained
        colorpalette `color', nograph n(`levels') class(`pclass')
        local color `"`r(p)'"'
    }
    c_local `nm' `"`color'"'
end

program _z_recycle
    _parse comma lhs 0 : 0
    gettoken k  lhs : lhs
    gettoken el lhs : lhs
    syntax [, `el'(str asis) ]
    loca opt: copy local `el'
    // try numlist
    capt numlist `"`opt'"'
    if _rc==1 _rc
    if _rc==0 {
        local opt `"`r(numlist)'"'
        if `: list sizeof opt'==2 {
            // generate range
            gettoken lb opt : opt
            gettoken ub opt : opt
            mata: st_local("opt", /*
                */ invtokens(strofreal(rangen(`lb', `ub', `k')')))
        }
    }
    // expand
    mata: st_local("opt", invtokens(_vecrecycle(`k', tokens(st_local("opt")))))
    c_local `el' `"`opt'"'
end

program z_parse_missing
    _parse comma plottype 0 : 0
    syntax [, LABel(str asis) COLor(str asis) * ]
    _add_quotes label `label'
    if `"`label'"'=="" local label `""no data""'
    _process_coloropts options, `options'
    if `"`color'"'=="" local color gs14
    local options color(`color') `options'
    if `"`plottype'"'=="area" {
        local options cmissing(n) nodropbase lalign(center) finten(100)/*
            */ lwidth(thin) lpattern(solid) lcolor(%0) `options'
    }
    else if "`plottype'"'=="line" {
        local options cmissing(n) lwidth(thin) lpattern(solid) `options'
    }
    c_local missing `options'
    c_local missing_color `"`color'"'
    c_local missing_lab   `"`label'"'
end

program _parse_label
    _parse comma label 0 : 0
    syntax [, NOLabel Format(str) Reverse NOMissing MFirst noGap ]
    c_local label `"`label'"'
    c_local nolabel `nolabel'
    c_local format `format'
    c_local reverse = "`reverse'"!=""
    c_local nomissing = "`nomissing'"!=""
    c_local mfirst = "`mfirst'"!=""
    c_local gap = "`gap'"==""
end

program _label_separate
    // add "* =" if needed
    gettoken l : 0, quotes qed(hasquotes) parse("= ")
    if `hasquotes' local 0 `"* = `0'"'
    else {
        // check whether 1st token is integer (possibly including wildcards)
        local l: subinstr local l "*" "", all
        local l: subinstr local l "?" "", all
        if `"`l'"'=="" local l 0
        capt confirm integer number `l'
        if _rc==1 exit 1
        if _rc local 0 `"* = `"`0'"'"'
    }
    // parse list
    local keys
    local lbls
    while (1) {
        gettoken key 0 : 0, parse("= ")
        if `"`key'"'=="" continue, break
        local keys `"`keys' `key'"'
        local lbl
        local space
        gettoken eq : 0, parse("= ")
        if `"`eq'"'=="=" {
            gettoken eq 0 : 0, parse("= ")
        }
        gettoken l : 0, quotes qed(hasquotes)
        while (`hasquotes') {
            gettoken l 0 : 0, quotes
            local lbl `"`lbl'`space'`l'"'
            local space " "
            gettoken l : 0, quotes qed(hasquotes)
        }
        local lbls `"`lbls' `"`lbl'"'"'
    }
    c_local lab_keys `"`keys'"'
    c_local lab_lbls `"`lbls'"'
end

program _add_quotes
    gettoken nm 0 : 0
    __add_quotes `0'
    c_local `nm' `"`0'"'
end

program __add_quotes
    if `"`0'"'=="" {
        c_local 0
        exit
    }
    gettoken tmp : 0, qed(hasquote)
    if !`hasquote' {
        local 0 `"`"`0'"'"'
    }
    c_local 0 `"`0'"'
end


version 17
mata:
mata set matastrict on

void _drop_empty_shapes(real scalar n0, real scalar n1, string scalar ID,
    string rowvector YX)
{
    real colvector id, p
    real matrix    yx
    
    if (n1<n0) return // no data
    // look for units that only have a single obs
    id = st_data((n0,n1), ID) // assuming data is ordered by ID
    p = (_mm_unique_tag(id) + _mm_unique_tag(id, 1)):==2 // first = last
    p = selectindex(p)
    if (!length(p)) return // all units have more than one obs
    // check whether coordinate variables are missing
    st_view(yx=., (n0,n1), YX)
    p = select(p, rowmissing(yx[p,]):==cols(yx))
    // remove single-obs units for which all coordinate variables are missing
    if (length(p)) st_dropobsin((n0-1):+p) // remove empty obs
}

transmorphic vector _vecrecycle(real scalar k, transmorphic vector x)
{   // x must have at least one element
    real scalar r, c
    
    r = rows(x); c = cols(x)
    if (r>c) return(J(ceil(k/c), 1, x)[|1\k|]) // => rowvector if x is 1x1
    return(J(1, ceil(k/c), x)[|1\k|])
}

void _z_cuts(string scalar CUTS, real rowvector range)
{
    string scalar  cuts, method, wvar
    real scalar    discrete, k, lb, ub
    real rowvector minmax
    real colvector C, X, w, p
    
    // CASE 1: cuts() specified
    discrete = st_local("discrete")!=""
    cuts     = st_local("cuts")
    if (cuts!="") { // cuts() specified
        C = strtoreal(tokens(cuts)')
        k = length(C)
        if (!discrete) k = k - 1
        st_matrix(CUTS, C')
        st_local("levels", strofreal(k))
        return
    }
    // tag first obs of each unit (if ID is available)
    if (st_local("ID")!="") {
        // assuming data is ordered by ID; assuming Z is constant
        // within ID
        p = selectindex(_mm_unique_tag(st_data(range, "ID")))
    }
    else p = .
    // CASE 2: discrete
    if (discrete) { // discrete specified
        C = mm_unique(st_data(range, "Z")[p])
        C = select(C, C:<.) // remove missing codes
        st_matrix(CUTS, C')
        st_local("cuts", invtokens(strofreal(C)'))
        st_local("levels", strofreal(length(C)))
        return
    }
    // get data
    X = st_data(range, "Z")[p]
    minmax = minmax(X)
    // SPECIAL CASE 1: no nonmissing data
    if (minmax==J(1,2,.)) {
        st_matrix(CUTS, J(1,0,.))
        st_local("cuts", "")
        st_local("levels", "0")
        return
    }
    // get requested number of levels and method
    k = strtoreal(st_local("levels"))
    if (k>=.) k = 5 // default number of levels
    method = st_local("method")
    // SPECIAL CASE 2: no variance
    lb = minmax[1]; ub = minmax[2]
    if (lb==ub) {
        st_matrix(CUTS, minmax)
        st_local("cuts", invtokens(strofreal(minmax)))
        st_local("levels", "1")
        return
    }
    // CASE 3: equidistant intervals
    if (method=="") {
        C = rangen(lb, ub, k+1) 
        st_matrix(CUTS, C')
        st_local("cuts", invtokens(strofreal(C)'))
        st_local("levels", strofreal(length(C)-1))
        return
    }
    // get weights
    wvar  = st_local("L_WVAR")
    if (wvar!="") {
        w = st_data(range, wvar)[p]
        _editmissing(w, 0)
    }
    else w = 1
    // CASE 4: quantiles
    if (method=="quantiles") {
        p = selectindex(X:<.) // remove missings
        X = X[p]
        if (wvar!="") w = w[p]
        C = mm_quantile(X, w, rangen(0, 1, k+1))
    }
    // CASE 5: kmeans
    else if (method=="kmeans") {
        X = select(X, X:<.) // remove missings
        C = lb \ _z_cuts_kmeans(k, X)
    }
    else exit(error(3499))
    // return results from CASE 4 or 5
    C = _mm_unique(C)
    k = length(C)
    if (C[1]>lb) C[1] = lb // make sure that min is included
    if (C[k]<ub) C[k] = ub // make sure that max is included
    st_matrix(CUTS, C')
    st_local("cuts", invtokens(strofreal(C)'))
    st_local("levels", strofreal(k-1))
}

real colvector _z_cuts_kmeans(real scalar k, real colvector X)
{
    real colvector C, p
    string scalar  frame, cframe

    cframe = st_framecurrent()
    frame  = st_tempname()
    st_framecreate(frame)
    st_framecurrent(frame)
    (void) st_addvar("double", "X")
    st_addobs(rows(X))
    st_store(., "X", X)
    stata(sprintf("cluster kmeans X, k(%g) name(C) start(segments)", k))
    C = st_data(., "C")
    st_framecurrent(cframe)
    st_framedrop(frame) // (not really needed)
    // return sorted list of upper bounds of clusters
    p = order((C,X), (1,2))
    return(sort(select(X[p], _mm_unique_tag(C[p], 1)), 1))
}

void _generate_mlabels(string scalar var, string scalar VAR, string scalar fmt, 
    string scalar touse)
{
    real scalar      isstr
    real colvector   X
    string scalar    vl
    string colvector L

    isstr = st_isstrvar(VAR)
    if (isstr) L = st_sdata(., VAR, touse)
    else {
        X = st_data(., VAR, touse)
        vl = st_varvaluelabel(VAR)
        if (vl!="") {
            if (!st_vlexists(vl)) vl = ""
        }
        if (vl!="") {
            L = st_vlmap(vl, X)
            if (anyof(L, "")) {
                L = L + (L:=="") :* 
                    strofreal(X, fmt!="" ? fmt : st_varformat(VAR))
            }
        }
        else {
            L = strofreal(X, fmt!="" ? fmt : st_varformat(VAR))
        }
    }
    st_sstore(., var, touse, L)
}

void _get_colors(string scalar lname, | string scalar lname2)
{   /* function assumes that global ColrSpace object "_GEOPLOT_ColrSpace_S"
       exists; maintaining a global is less work than initializing ColrSpace
       in each call */
    real scalar      i
    string scalar    c
    string rowvector C, kw1, kw2
    pointer (class ColrSpace scalar) scalar S
    
    if (args()<2) lname2 = lname
    kw1 = ("none", "bg", "fg", "background", "foreground")
    kw2 = ("*", "%")
    S = findexternal("_GEOPLOT_ColrSpace_S")
    //if ((S = findexternal("_GEOPLOT_ColrSpace_S"))==NULL) S = &(ColrSpace())
    C = tokens(st_local(lname2))
    i = length(C)
    for (;i;i--) {
        c = C[i]
        if (anyof(kw1, c)) continue
        if (anyof(kw2, substr(c,1,1))) continue
        S->colors("`"+`"""' + C[i] + `"""'+"'")
        C[i] = S->colors()
    }
    st_local(lname, invtokens(C))
}

void  _get_lbl(string scalar key, string scalar keys, string scalar lbls,
    string scalar def)
{
    real scalar   i, n
    string vector Keys
    
    Keys = tokens(st_local(keys))
    n = length(Keys)
    for (i=1;i<=n;i++) {
        if (strmatch(key, Keys[i])) break
    }
    if (i>n) st_local("lbl", def)
    else st_local("lbl", tokens(st_local(lbls))[i])
}

end


