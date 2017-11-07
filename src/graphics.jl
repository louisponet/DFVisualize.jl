using ,GeometryTypes

const ASSET_PATH =  joinpath(dirname(@__FILE__),"..","assets")

function get_shader(shader=:wfc)
  if shader==:wfc
    vert_shader = load(joinpath(ASSET_PATH,"shaders","wfc.vert"))
    frag_shader = load(joinpath(ASSET_PATH,"shaders","wfc.frag"))
    return LazyShader(vert_shader,frag_shader)
  end
end

#@incomplete, finish this not done yet!
function create_vector(start_point::Point3f0,end_point::Point3f0,width,color::RGBA{Float32})
  cone_verts,cone_normals         = read_obj(joinpath(ASSET_PATH,"renderables","cone.obj"))
  cylinder_verts,cylinder_normals = read_obj(joinpath(ASSET_PATH,"renderables","cylinder.obj"))

  vr = end_point-start_point
  l  = norm(vr)
  angle = acos(vr[3]/l) + 0.00001
  rot_ax = normalize(cross([0.0f0,0.0f0,1.0f0],vr))
  #get the correct rotation matrix!!!!

  buffer_dict = Dict(:vertices => GLBuffer(Point3f0.([cone_verts;cylinder_verts])),
                     :normals => GLBuffer(Point3f0.([cone_normals;cylinder_normals])),
                     :vertex_color => GLBuffer([color for i=1:length(cylinder_verts)+length(cone_verts)],
                     :)

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