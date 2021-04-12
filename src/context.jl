macro import_context_huge()
    :(
        using ComplexVisual:
            CV_Context, CV_CanvasContext,
            cv_destroy, CV_2DCanvasContext
    )
end

import Base:show

abstract type CV_Context end

abstract type CV_CanvasContext  <: CV_Context
    # required fields
    # canvas  (subtype of CV_Canvas)
    # ctx     (CairoContext)
end

function show(io::IO, cc::CV_CanvasContext)
    t = typeof(cc)
    show(io, t)
    print(io, '(')
    show(io, cc.canvas)
    print(io, ", ctx: ")
    show(io, cc.ctx.ptr)
    print(io, ')')
    return nothing
end

function cv_destroy(cc::canvasT) where {canvasT<:CV_CanvasContext}
    destroy(cc.ctx)
    return nothing
end

struct CV_2DCanvasContext{canvasT<:CV_2DCanvas} <: CV_CanvasContext
    canvas :: canvasT
    ctx    :: CairoContext

    function CV_2DCanvasContext(canvas::T) where {T<:CV_2DCanvas}
        ctx = CairoContext(canvas.surface)
        return new{T}(canvas, ctx)
    end
end


# vim:syn=julia:cc=79:fdm=marker:sw=4:ts=4:
