using GeometryTypes,GLAbstraction

const ASSET_PATH =  joinpath(dirname(@__FILE__),"..","assets")
const GLBoundingBox = AABB{Float32}
function get_shader(shader=:wfc)
  if shader==:wfc
    vert_shader = load(joinpath(ASSET_PATH,"shaders","wfc.vert"))
    frag_shader = load(joinpath(ASSET_PATH,"shaders","wfc.frag"))
    return LazyShader(vert_shader,frag_shader)
  end
end


function create_vector(start_point::Point3f0, end_point::Point3f0, color::RGBA{Float32}; width=0.15, arrow_length = 0.2, arrow_width = 2*width)
  vr = end_point-start_point
  l  = norm(vr)
  angle = Float32(acos(vr[3]/l) + 0.00001)
  rot_ax = normalize(cross([0.0f0,0.0f0,1.0f0],vr))
  rot_mat = rotate(angle,Vec3f0(rot_ax))
  model_mat = translationmatrix(Vec3f0(start_point))*rot_mat*scalematrix(Vec3f0(1.0,1.0,l-arrow_length))
  offset = width/2
  #get the correct rotation matrix!!!! 
  vector_m = map(GLNormalMesh,[ (Pyramid(Point3f0(0.,0.,1-arrow_length),Float32(arrow_length),Float32(arrow_width)),color),(AABB{Float32}(Vec3f0(-offset,-offset,0.0),Vec3f0(width,width,1-arrow_length)),color)])

  return visualize(merge(vector_m),model=model_mat)
end

function read_obj(filename)
  t_vertices     = Array{Array{Float32,1},1}()
  t_normals      = Array{Array{Float32,1},1}()
  vert_indices   = Array{Int,1}()
  norm_indices   = Array{Int,1}()
  open(filename,"r") do f
    while !eof(f)
      line = readline(f)
      if line[1]=='#'
        continue
      end
      split_line = split(line)
      if split_line[1] == "v"
        push!(t_vertices,parse.(Float32,split_line[2:end]))
      elseif split_line[1] == "vn"
        push!(t_normals,parse.(Float32,split_line[2:end]))
      elseif split_line[1] == "f"
        for s in split_line[2:end]
          push!(vert_indices,parse(Int,split(s,"/")[1]))
          push!(norm_indices,parse(Int,split(s,"/")[end]))
        end
      end
    end
  end
  vertices = [t_vertices[i] for i in vert_indices]
  normals  = [t_normals[i] for i in norm_indices]
  return vertices, normals
end 

@inline const_lift(f::Union{DataType, Type, Function}, inputs...) = map(f, map(GLAbstraction.makesignal, inputs)...)
export const_lift

struct TransparentPostrender
  vao::GLVertexArray
  primitive::GLenum
  pass_loc
end

function (tp::TransparentPostrender)()
  glDisable(GL_CULL_FACE)
  glDepthFunc(GL_LESS)
  gluniform(tp.pass_loc,Cint(1))
  render(tp.vao, tp.primitive)
  
  gluniform(tp.pass_loc, Cint(2))
  glEnable(GL_CULL_FACE)
  glCullFace(GL_FRONT)
  glDepthFunc(GL_ALWAYS)
  render(tp.vao, tp.primitive)
  
  gluniform(tp.pass_loc, Cint(3))
  # glDepthFunc(GL_LEQUAL)
  render(tp.vao, tp.primitive)
  
  # gluniform(tp.pass_loc, Cint(2))
  # glCullFace(GL_BACK)
  # glDepthFunc(GL_LEQUAL)
  # render(tp.vao, tp.primitive)

  gluniform(tp.pass_loc, Cint(0))
  
  render(tp.vao, tp.primitive)
end
# function render_isosurface(list::Vector{<:RenderObject})
#   isempty(list) && return nothing
#   first(list).prerenderfunction()
#   vertexarray = first(list).vertexarray
#   program = vertexarray.program
#   glUseProgram(program.id)
#   glBindVertexArray(vertexarray.id)
#   for renderobject in list
#     Bool(Reactive.value(renderobject.uniforms[:visible])) || continue # skip invisible
#     # make sure we only bind new programs and vertexarray when it is actually
#     # different from the previous one
#     if renderobject.vertexarray != vertexarray
#       vertexarray = renderobject.vertexarray
#       if vertexarray.program != program
#         program = renderobject.vertexarray.program
#         glUseProgram(program.id)
#       end
#       glBindVertexArray(vertexarray.id)
#     end
#     for (key,value) in program.uniformloc
#       if haskey(renderobject.uniforms, key)
#         if length(value) == 1
#           gluniform(value[1], renderobject.uniforms[key])
#         elseif length(value) == 2
#           gluniform(value[1], value[2], renderobject.uniforms[key])
#         else
#           error("Uniform tuple too long: $(length(value))")
#         end
#       end
#     end
#     renderobject.postrenderfunction()
#   end
#   # we need to assume, that we're done here, which is why
#   # we need to bind VertexArray to 0.
#   # Otherwise, every glBind(::GLBuffer) operation will be recorded into the state
#   # of the currently bound vertexarray
#   glBindVertexArray(0)
#   return
  
  