"Creates a glcontext and visualizes the wavefunction in it, for a given iso value"
function visualize_wfc(wfc,iso,args...)
  screen = glscreen()
  visualize_wfc!(screen,wfc,iso,args)
  renderloop(screen)
end

"Creates a glcontext and visualizes multiple wfcs in it."
function visualize_wfc(wfcs::Array{<:Wfc3D},iso,args...)
  screen = glscreen()
  visualize_wfc!(screen,wfcs,iso,args)
  renderloop(screen)
end

"Takes a given glcontext, wavefunction and puts the wavefunction visualization in it."
function visualize_wfc!(screen,wfc::Wfc3D,iso,args...)
  vertices_pos, vertices_neg = marching_cubes(wfc,iso)
  center_pos  = sum(vertices_pos)/length(vertices_pos)
  center_neg  = sum(vertices_neg)/length(vertices_neg)
  normals_pos = Point3f0[]
  normals_neg = Point3f0[]
  for vert in vertices_pos
    push!(normals_pos, normalize(vert-center_pos))
  end
  for vert in vertices_neg
    push!(normals_neg, normalize(vert-center_neg))
  end
  shader = get_shader()

  robj_pos = RenderObject(Dict(:vertices => GLBuffer(vertices_pos),
  :normals => GLBuffer(normals_pos),
  :vertex_color => GLBuffer([RGBA(1f0,0f0,0f0,0.6f0) for i=1:length(vertices_pos)]),
  :model => Mat4f0(eye(4))),shader,GLAbstraction.StandardPrerender())
  robj_pos.postrenderfunction = TransparentPostrender(robj_pos.vertexarray, GL_TRIANGLES,robj_pos.vertexarray.program.uniformloc[:pass][1])

  robj_neg = RenderObject(Dict(:vertices => GLBuffer(vertices_neg),
  :normals => GLBuffer(normals_neg),
  :vertex_color => GLBuffer([RGBA(0f0,0f0,1f0,0.6f0) for i=1:length(vertices_neg)]),
  :model => Mat4f0(eye(4))),shader,GLAbstraction.StandardPrerender())
  robj_neg.postrenderfunction = TransparentPostrender(robj_neg.vertexarray, GL_TRIANGLES,robj_neg.vertexarray.program.uniformloc[:pass][1])
 
  # vertices = [vertices_pos;vertices_neg]
  # colors = [[RGBA(1f0,0f0,0f0,0.6f0) for i=1:length(vertices_pos)];[RGBA(0f0,0f0,1f0,0.6f0) for i=1:length(vertices_neg)]]
  # mesh   = GLNormalVertexcolorMesh(vertices=vertices,faces=[Face(i,i+1,i+2) for i=1:3:length(vertices)],color=colors)
  # bounding_box = const_lift(GLBoundingBox,mesh)
  
  # robj   = RenderObject(Dict(:bounding_box => bounding_box,:program=>shader),shader,,nothing,bounding_box,mesh)
  # robj.postrenderfunction = 
  # println(robj.vertexarray)
  # test = visualize(mesh)
  # visualize_atom!(screen,wfc.atom)
  visualize_cell!(screen,wfc.cell)
  _view(robj_pos,screen,camera=:perspective,position=Vec3f0(0))
  _view(robj_neg,screen,camera=:perspective,position=Vec3f0(0))
end

"Takes a given glcontext, wavefunctions and puts the visualizations for the multiple wavefunctions in it."
function visualize_wfc!(screen,wfcs::Array{<:Wfc3D},iso,rate=10)
  meshes = []
  for wfc in wfcs
    vertices_pos,vertices_neg = marching_cubes(wfc,iso)
    colors = [[RGBA(1f0,0f0,0f0,0.6f0) for i=1:length(vertices_pos)];[RGBA(0f0,0f0,1f0,0.6f0) for i=1:length(vertices_neg)]]
    vertices = [vertices_pos;vertices_neg]
    push!(meshes,GLNormalVertexcolorMesh(vertices=vertices,faces=[Face(i,i+1,i+2) for i=1:3:length(vertices)],color=colors))
  end
  time_signal = loop(1:length(meshes),rate)
  mesh = map(t->meshes[t],time_signal)
  _view(visualize(mesh),screen,camera=:perspective)
end

"Creates a glcontext and visualizes the wavefunctions of a given band of a WannierModel."
function visualize_band(x::WannierModel,band,iso,args...;kwargs...)
  screen = glscreen()
  visualize_band!(screen,x,band,iso,args...;kwargs...)
  renderloop(screen)
end

"Takes a glcontext and visualizes the WannierBand of the WannierModel."
function visualize_band!(screen,x::WannierModel{T},band,iso,k_points=nothing,args...;rate=10,soc=false,data=:wfc,kwargs...) where T
  if k_points==nothing
    if soc==false
      tbband = calculate_eig_cm(x)[1][band]
    else
      tbband = calculate_eig_cm_SOC(x)[1][band]
    end
  else
    if soc==false
      tbband = calculate_eig_cm(x,k_points)[1][band]
    else
      tbband = calculate_eig_cm_SOC(x,k_points)[1][band]
    end
  end
  meshes = Array{HomogenousMesh,1}(length(tbband.eigvec))
  for (i,vec) in enumerate(tbband.eigvec)
    if soc!=false
      wfc = sum([v*wf for (v,wf) in kp(vec,[x.wfcs;x.wfcs])])
    else
      wfc = sum([v*wf for (v,wf) in kp(vec,x.wfcs)])
    end
    if data == :wfc
      verts_pos,verts_neg = marching_cubes(wfc,iso)
    elseif data == :charge
      verts_pos,verts_neg = marching_cubes(calculate_density_mesh(wfc),iso)
    end      
    colors = [[RGBA(1f0,0f0,0f0,0.6f0) for i=1:length(verts_pos)];[RGBA(0f0,0f0,1f0,0.6f0) for i=1:length(verts_neg)]]
    vertices = [verts_pos;verts_neg]
    meshes[i] = GLNormalVertexcolorMesh(vertices=vertices,faces=[Face(i,i+1,i+2) for i=1:3:length(vertices)],color=colors)
  end
  atoms = PhysAtom{T}[]
  for wfc in x.wfcs
    if !in(wfc.atom,atoms)
      push!(atoms,wfc.atom)
      visualize_atom!(screen,wfc.atom)
    end
  end
  visualize_cell!(screen,x.wfcs[1].cell)
  time_signal = loop(1:length(meshes),rate)
  mesh = map(t->meshes[t],time_signal)
  _view(visualize(mesh,shader=GLVisualizeShader("wfc.vert","wfc.frag")),screen,camera=:perspective)
  # _view(visualize(mesh),screen,camera=:perspective)
end

"Creates a glcontext and visualizes the given band if the wavefunctions are already calculated and supplied."
function visualize_band(band,wfcs,iso,args...;kwargs...)
  screen = glscreen()
  visualize_band!(screen,band,wfcs,iso,args...;kwargs...)
  renderloop(screen)
end

"Takes a glcontext and and visualizes the given band if the wavefunctions are already calculated and supplied."
function visualize_band!(screen,band,wfcs::Array{Wfc3D{T},1},iso,args...;rate=10,data=:wfc,bloch=false,kwargs...) where T
  time_signal = loop(1:length(band.eigvec),rate)
  
  wfcs       = 1000.0*normalize.(wfcs)
  t_wfcs     = 1000.0*normalize.(wfcs)
  points     = [p.p for p in wfcs[1].points]
  
  k_meshes        = Array{HomogenousMesh,1}(length(band.eigvec))
  atoms = PhysAtom[]
  for wfc in wfcs
    if !in(wfc.atom,atoms)
      push!(atoms,wfc.atom)
    end
  end
  k_strings       = Array{String,1}(length(band.eigvec))
  k_angmom_vecs   = Array{Array{Array{Point3f0,1},1},1}(length(band.eigvec))
  k_spin_vecs     = Array{Array{Array{Point3f0,1},1},1}(length(band.eigvec))
  
  
  # for some reason multithreading works very badly here. I believe it's because we use a lot of the same memory and they are doing safe 
  # accesses?
  for i=1:length(band.eigvec)
    vec = band.eigvec[i]
    
    k_strings[i] = "i = $i\n k_a = $(band.k_points[i][1]), k_b = $(band.k_points[i][2]), k_c = $(band.k_points[i][3])\n"
    #Incomplete this is just for Te right now easymode to expand this
    t_angmom_vec =Array{Array{Point3f0,1},1}(length(atoms))
    t_spin_vec =Array{Array{Point3f0,1},1}(length(atoms))
    for (n,atom) in enumerate(atoms)
      t_angmom_vec[n] = [convert(Point3f0,atom.center),convert(Point3f0,atom.center+3*band.angmoms[i][n])]
      t_spin_vec[n]   = [convert(Point3f0,atom.center),convert(Point3f0,atom.center+3*band.spins[i][n])]
    end
    k_angmom_vecs[i] = t_angmom_vec
    k_spin_vecs[i]   = t_spin_vec
    
    if bloch
      k_wfcs = Array{Wfc3D{T},1}(length(wfcs))
      for (j,wfc) in enumerate(wfcs)
        k_wfcs[j] = construct_bloch_sum(wfc,band.k_points[i])
      end
      t_wfcs = k_wfcs
    end
    
    if length(vec) > length(t_wfcs)
      wfc = vec[1]*t_wfcs[1]
      for j = 2:length(vec)
        wfc += vec[j]*t_wfcs[1+rem(j-1,length(t_wfcs))]
      end
      gc()
    else
      wfc = sum([v*w for (v,w) in kp(vec,t_wfcs)])
    end
    
    if data == :wfc
      verts_pos, = marching_cubes([real(x.w) > 0 ? real(x.w) :  0.000001 for x in wfc.points]     ,points,iso)
      verts_neg, = marching_cubes([real(x.w) < 0 ? abs(real(x.w)) :  0.000001 for x in wfc.points],points,iso)
      colors     = [[RGBA(1f0,0f0,0f0,0.6f0) for j=1:length(verts_pos)];[RGBA(0f0,0f0,1f0,0.6f0) for j=1:length(verts_neg)]]
      
      k_meshes[i]  = GLNormalVertexcolorMesh(vertices=[verts_pos;verts_neg],faces=[Face(i,i+1,i+2) for i=1:3:length(verts_pos)+length(verts_neg)],color=colors)
      
    elseif data == :charge
      verts,      = marching_cubes(map(x->real(x.w),calculate_density_wfc_normalized(wfc).points),points,iso)
      colors     = [RGBA(1f0,0f0,0f0,0.6f0) for j=1:length(verts)]
      
      k_meshes[i]  = GLNormalVertexcolorMesh(vertices=verts,faces=[Face(i,i+1,i+2) for i=1:3:length(verts)],color=colors)
    end
  end
  
  for atom in atoms
    visualize_atom!(screen,atom)
  end
  
  visualize_cell!(screen,wfcs[1].cell)
  
  mesh        = map(t->k_meshes[t],time_signal)
  string      = map(t->k_strings[t],time_signal)
  _view(visualize(mesh,shader=GLVisualizeShader("wfc.vert","wfc.frag")),screen,camera=:perspective)
  _view(visualize(string),camera=:orthographic_pixel)
  for i=1:length(atoms)
    angmom_vec = map(t->k_angmom_vecs[t][i],time_signal)
    spin_vec   = map(t->k_spin_vecs[t][i],time_signal)
    _view(visualize(angmom_vec,:linesegment,color=RGBA(1.0f0,0.0f0,1.0f0,1.0f0),width=100.0f0),screen,camera=:perspective)
    _view(visualize(spin_vec,:linesegment,color=RGBA(0.0f0,1.0f0,1.0f0,1.0f0),width=100.0f0),screen,camera=:perspective)
  end
end

"Creates a glcontext and visualizes the sum of the two supplied bands. This is intended to visualize the density of the sum of the spin up and spin down components of a band."
function visualize_two_spin_band(up_band,down_band,wfcs,iso,args...;kwargs...)
  screen = glscreen()
  visualize_two_spin_band!(screen,up_band,down_band,wfcs,iso,args...;kwargs...)
  renderloop(screen)
end

"Takes a glcontext and visualizes the sum of the two supplied bands. This is intended to visualize the density of the sum of the spin up and spin down components of a band."
function visualize_two_spin_band!(screen,band_up::WannierBand{T},band_dn::WannierBand{T},wfcs::Array{Wfc3D{T},1},iso,args...;rate=10,data=:wfc,bloch=false,kwargs...) where T
  k_vertices = Array{Array{Point3f0,1},1}(length(band_up.k_points))
  k_colors = Array{Array{RGBA{Float32},1},1}(length(band_up.k_points))
  wfcs = 1000.0*normalize.(wfcs)
  Threads.@threads for i=1:length(band_up.eigvec)
    vec_up = band_up.eigvec[i]
    vec_dn = band_dn.eigvec[i]
    if bloch
      k_wfcs = Array{Wfc3D{T},1}(length(wfcs))
      for (j,wfc) in enumerate(wfcs)
        k_wfcs[j] = construct_bloch_sum(wfc,band_up.k_points[i])
      end
    else
      k_wfcs = wfcs
    end
    if length(vec_up)>length(wfcs)
      wfc_up = sum([v*wf for (v,wf) in kp(vec_up,[k_wfcs;k_wfcs])])
      wfc_dn = sum([v*wf for (v,wf) in kp(vec_dn,[k_wfcs;k_wfcs])])
    else
      wfc_up = sum([v*wf for (v,wf) in kp(vec_up,k_wfcs)])
      wfc_dn = sum([v*wf for (v,wf) in kp(vec_dn,k_wfcs)])
    end
    if data == :wfc
      verts_pos,verts_neg = marching_cubes(wfc_tot,iso)
      k_colors[i] = [[RGBA(1f0,0f0,0f0,0.6f0) for j=1:length(verts_pos)];[RGBA(0f0,0f0,1f0,0.6f0) for j=1:length(verts_neg)]]
      k_vertices[i]=[verts_pos;verts_neg]
    elseif data == :charge
      k_vertices[i], = marching_cubes(calculate_density_mesh(wfc_up)+calculate_density_mesh(wfc_dn),iso)
      k_colors[i] = [RGBA(1f0,0f0,0f0,0.6f0) for j=1:length(k_vertices[i])]
    end
  end
  atoms = PhysAtom[]
  for wfc in wfcs
    if !in(wfc.atom,atoms)
      push!(atoms,wfc.atom)
      visualize_atom!(screen,wfc.atom)
    end
  end
  
  visualize_cell!(screen,wfcs[1].cell)
  
  meshes = Array{HomogenousMesh,1}(length(band_up.eigvec))
  for (i,colors) in enumerate(k_colors)  
    meshes[i] = GLNormalVertexcolorMesh(vertices=k_vertices[i],faces=[Face(i,i+1,i+2) for i=1:3:length(k_vertices[i])],color=colors)
  end
  
  time_signal = loop(1:length(meshes),rate)
  mesh = map(t->meshes[t],time_signal)
  _view(visualize(mesh,shader=GLVisualizeShader("wfc.vert","wfc.frag")),screen,camera=:perspective)
end

function generate_spin_colors(wfc_up::Wfc3D{T},wfc_dn::Wfc3D{T},vertices::Array{Point3f0,1}) where T
  colors = RGBA[]
  i = 1
  while i<=length(vertices)
    vert = vertices[i]
    j=1
    while j<=length(wfc_up.points)
      point_up = wfc_up.points[j]
      point_dn = wfc_dn.points[j]
      if point_up.p.x == vert[1] && point_up.p.y == vert[2] && point_up.p.z == vert[3]
        n_up = Float32(norm(point_up.w))
        n_dn = Float32(norm(point_dn.w))
        push!(colors,RGBA(n_up/(n_up+n_dn),0f0,n_dn/(n_up+n_up),0.6f0))
        i+=1
        vert = vertices[i]
      end 
      j+=1
    end
    i+=1
  end
  return colors
end

"Visualizes an atom."
function visualize_atom!(screen,atom::PhysAtom,radius=0.5f0,color=RGBA(0f0,0.1f0,0f0,1f0))
  sphere   = HyperSphere(convert(Point3f0,atom.center),radius)
  vertices = decompose(Point3f0, sphere, 50)
  faces    = decompose(GLTriangle, sphere, 50)
  mesh     = GLNormalColorMesh(vertices=vertices,faces=faces,color=color)
  _view(visualize(mesh),screen,camera=:perspective)
end

"Visualizes the unit cell."
function visualize_cell!(screen,cell)
  positions = [Point3f0(0f0,0f0,0f0),convert(Point3f0,cell[1]),
  Point3f0(0f0,0f0,0f0),convert(Point3f0,cell[2]),
  Point3f0(0f0,0f0,0f0),convert(Point3f0,cell[3]),
  convert(Point3f0,cell[1]),convert(Point3f0,cell[1]+cell[2]),
  convert(Point3f0,cell[1]),convert(Point3f0,cell[1]+cell[3]),
  convert(Point3f0,cell[2]),convert(Point3f0,cell[2]+cell[3]),
  convert(Point3f0,cell[2]),convert(Point3f0,cell[1]+cell[2]),
  convert(Point3f0,cell[3]),convert(Point3f0,cell[2]+cell[3]),
  convert(Point3f0,cell[3]),convert(Point3f0,cell[1]+cell[3]),
  convert(Point3f0,cell[1]+cell[2]),convert(Point3f0,cell[1]+cell[2]+cell[3]),
  convert(Point3f0,cell[2]+cell[3]),convert(Point3f0,cell[1]+cell[2]+cell[3]),
  convert(Point3f0,cell[1]+cell[3]),convert(Point3f0,cell[1]+cell[2]+cell[3])]
  dirlen    = 2f0
  baselen   = 0.2f0             
  axes      = [(HyperRectangle{3,Float32}(Vec3f0(0), Vec3f0(dirlen, baselen, baselen)), RGBA(1f0,0f0,0f0,1f0)),
  (HyperRectangle{3,Float32}(Vec3f0(0), Vec3f0(baselen, dirlen, baselen)), RGBA(0f0,1f0,0f0,1f0)),
  (HyperRectangle{3,Float32}(Vec3f0(0), Vec3f0(baselen, baselen, dirlen)), RGBA(0f0,0f0,1f0,1f0))]
  rect_meshes = map(GLNormalMesh, axes)
  rect_mesh = merge(rect_meshes)
  _view(visualize(positions,:linesegment,color=RGBA(0f0,0f0,0f0,1f0),width=1f0),screen,camera=:perspective)
  _view(visualize(rect_mesh),screen)
end