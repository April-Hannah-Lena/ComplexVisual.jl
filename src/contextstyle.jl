macro import_contextstyle_huge()
    :(
        using ComplexVisual:
            CV_ContextStyle, cv_create_context, CV_CanvasContextStyle,
            CV_CombiContextStyle, cv_prepare, →,
            CV_ContextColorStyle, cv_color,
            CV_ContextLineWidthStyle, cv_linewidth,
            CV_ContextAntialiasStyle, cv_antialias,
            CV_ContextOperatorStyle, cv_operatormode, cv_opmode,
            cv_op_source, cv_op_over,
            CV_ContextFillStyle, cv_fillstyle, 
            CV_ContextFontFaceStyle, cv_fontface,
            CV_ContextFontSize, cv_fontsize,
            CV_MathCoorStyle
    )
end

import Base:show

abstract type CV_ContextStyle end
abstract type CV_CanvasContextStyle <: CV_ContextStyle end


"""
create_context, execute do_func and destroy context afterwards.
"""
function cv_create_context(do_func::Function, canvas::CV_Canvas,
                           style::Union{Nothing, CV_ContextStyle}=nothing;
                           prepare::Bool=true)
    con = cv_create_context(canvas; prepare=prepare)
    if style isa CV_ContextStyle
        cv_prepare(con, style)
    end
    try
        do_func(con)
    finally
        cv_destroy(con)
    end
    return nothing
end


struct CV_CombiContextStyle{T<:CV_ContextStyle,
                            S<:CV_ContextStyle} <: CV_ContextStyle # {{{
    style1 :: T
    style2 :: S
end

function show(io::IO, s::CV_CombiContextStyle)
    print(io, "CV_CombiContextStyle(style1: "); show(io, s.style1)
    print(io, ", style2: "); show(io, s.style2)
    print(io, ')')
    return nothing
end

function show(io::IO, m::MIME{Symbol("text/plain")}, s::CV_CombiContextStyle)
    outer_indent = (get(io, :cv_indent, "")::AbstractString)
    indent = outer_indent * "  "
    iio = IOContext(io, :cv_indent => indent)
    println(io, "CV_CombiContextStyle(")
    print(io, indent, "style1: "); show(iio, m, s.style1); println(io)
    print(io, indent, "style2: "); show(iio, m, s.style2); println(io)
    print(io, outer_indent, ')')
    return nothing
end

function cv_prepare(con::CV_Context, cstyle::CV_CombiContextStyle{T,S}) where {T,S}
    cv_prepare(con, cstyle.style1)
    cv_prepare(con, cstyle.style2)
    return nothing
end


function →(style1::T, style2::S) where {T<:CV_ContextStyle, S<:CV_ContextStyle}
  return CV_CombiContextStyle(style1, style2)
end

# }}}

struct CV_ContextColorStyle <: CV_CanvasContextStyle  # {{{
    red   :: Float64
    green :: Float64
    blue  :: Float64
    alpha :: Float64
end
cv_color(red::Real, green::Real, blue::Real, alpha::Real) =
    CV_ContextColorStyle(
        convert(Float64, red),
        convert(Float64, green),
        convert(Float64, blue),
        convert(Float64, alpha))
cv_color(red::Real, green::Real, blue::Real) = cv_color(red, green, blue, 1.0)
function cv_prepare(cc::CV_CanvasContext, style::CV_ContextColorStyle)
    set_source_rgba(cc.ctx, style.red, style.green, style.blue, style.alpha)
    return nothing
end 

function show(io::IO, s::CV_ContextColorStyle)
    print(io, "CV_ContextColorStyle(red: "); show(io, s.red)
    print(io, ", green: "); show(io, s.green)
    print(io, ", blue: "); show(io, s.blue)
    print(io, ", alpha: "); show(io, s.alpha)
    print(io, ')')
    return nothing
end
# }}}

struct CV_ContextLineWidthStyle <: CV_CanvasContextStyle # {{{
    width :: Float64
end
cv_linewidth(width::Real) = CV_ContextLineWidthStyle(Float64(width))

function cv_prepare(cc::CV_CanvasContext, style::CV_ContextLineWidthStyle)
    set_line_width(cc.ctx, style.width)
    return nothing
end

function show(io::IO, s::CV_ContextLineWidthStyle)
    print(io, "CV_ContextLineWidthStyle(width: "); show(io, s.width)
    print(io, ')')
    return nothing
end
# }}}

struct CV_ContextAntialiasStyle{T<:Integer} <: CV_CanvasContextStyle # {{{
    antialias :: T
end
cv_antialias(antialias) = CV_ContextAntialiasStyle(antialias)
function cv_prepare(cc::CV_CanvasContext, style::CV_ContextAntialiasStyle)
    set_antialias(cc.ctx, style.antialias)
    return nothing
end

function show(io::IO, s::CV_ContextAntialiasStyle)
    print(io, "CV_ContextAntialiasStyle(width: "); show(io, s.antialias)
    print(io, ')')
    return nothing
end
# }}}

struct CV_ContextOperatorStyle{T<:Integer} <: CV_CanvasContextStyle # {{{
    opmode :: T
end
cv_operatormode(mode::Integer) = CV_ContextOperatorStyle(mode)
cv_opmode(mode::Integer) = CV_ContextOperatorStyle(mode)

const cv_op_source = CV_ContextOperatorStyle(Cairo.OPERATOR_SOURCE)
const cv_op_over = CV_ContextOperatorStyle(Cairo.OPERATOR_OVER)

function cv_prepare(cc::CV_CanvasContext, style::CV_ContextOperatorStyle)
    set_operator(cc.ctx, style.opmode)
    return nothing
end

function show(io::IO, s::CV_ContextOperatorStyle)
    print(io, "CV_ContextOperatorStyle(opmode: "); show(io, s.opmode)
    print(io, ')')
    return nothing
end
# }}}

struct CV_ContextFillStyle{T<:Integer} <: CV_CanvasContextStyle   # {{{
    fillstyle :: T
end
cv_fillstyle(style) = CV_ContextFillStyle(style)
function cv_prepare(cc::CV_CanvasContext, style::CV_ContextFillStyle)
    set_fill_type(cc.ctx, style.fillstyle)
  return nothing
end 

function show(io::IO, s::CV_ContextFillStyle)
    print(io, "CV_ContextFillStyle(fillstyle: "); show(io, s.fillstyle)
    print(io, ')')
    return nothing
end
# }}}

struct CV_ContextFontFaceStyle{sT<:Integer,
                               wT<:Integer} <: CV_CanvasContextStyle # {{{
    name   :: AbstractString
    slant  :: sT
    weight :: wT
end
cv_fontface(name::AbstractString, slant::sT,
            weight::wT) where {sT<:Integer, wT<:Integer} =
    CV_ContextFontFaceStyle(name, slant, weight)
cv_fontface(name::AbstractString, weight::wT) where {wT<:Integer} =
    cv_fontface(name, Cairo.FONT_SLANT_NORMAL, weight)
cv_fontface(name::AbstractString) = cv_fontface(name, Cairo.FONT_WEIGHT_NORMAL)
function cv_prepare(cc::CV_CanvasContext, style::CV_ContextFontFaceStyle)
    select_font_face(cc.ctx, style.name, style.slant, style.weight)
    return nothing
end

function show(io::IO, s::CV_ContextFontFaceStyle)
    print(io, "CV_ContextFontFaceStyle(name: "); show(io, s.name)
    print(io, ", slant: "); show(io, s.slant)
    print(io, ", weight: "); show(io, s.weight)
    print(io, ')')
    return nothing
end
# }}}

struct CV_ContextFontSize{T<:Real} <: CV_CanvasContextStyle # {{{
    size    :: T
end
cv_fontsize(size::T) where {T<:Real} = CV_ContextFontSize(size)
function cv_prepare(cc::CV_CanvasContext, style::CV_ContextFontSize)
    set_font_size(cc.ctx, style.size)
    return nothing
end

function show(io::IO, s::CV_ContextFontSize)
    print(io, "CV_ContextFontSize(size: "); show(io, s.size)
    print(io, ')')
    return nothing
end
# }}}

struct CV_MathCoorStyle <: CV_CanvasContextStyle  # {{{
    canvas :: CV_Math2DCanvas
end
function cv_prepare(cc::CV_CanvasContext, style::CV_MathCoorStyle)
    canvas = style.canvas
    ctx = cc.ctx
    scale(ctx, canvas.resolution, -canvas.resolution)
    translate(ctx, -real(canvas.corner_ul), -imag(canvas.corner_ul))
    return nothing
end

function show(io::IO, s::CV_MathCoorStyle)
    print(io, "CV_MathCoorStyle(canvas: "); show(io, s.canvas)
    print(io, ')')
    return nothing
end
# }}}

# }}}

# vim:syn=julia:cc=79:fdm=marker:sw=4:ts=4:
