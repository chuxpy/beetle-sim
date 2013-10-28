Physijs.scripts.worker = '/physijs/physijs_worker.js'
Physijs.scripts.ammo = '/physijs/examples/js/ammo.js'

#Remember to uncomment before deployment!

#To get submodule dependencies, remember to:
#git submodule init
#git submodule update

#Objects:

#GROUND
window.box_material = Physijs.createMaterial(
  new THREE.MeshLambertMaterial(
    color: 0xffffff
    transparent: true
    opacity: 0.2)
  .4
  .9) # ~0.5 restitution is for wood, ~0.4 friction is acceptable f_coeff.

gen_box_side = (side)->
  new Physijs.BoxMesh(
    new THREE.CubeGeometry(side[0], side[1], side[2]) #width, height, depth
    window.box_material
    0)

window.n = Math.floor 25

window.box_sidel = [[[n, 10, n], [0, -9, 0]]
                    [[1, 2*n, n], [-n/2, n/2, 0]] #[1,n,n], [-n/2,0,0]
                    [[1, 2*n, n], [n/2, n/2, 0]]
                    [[n, 2*n, 1], [0, n/2, -n/2]]
                    [[n, 2*n, 1], [0, n/2, n/2]]]

#GLASS
window.glass_density = 1 #kg/m^3
window.glass_material = Physijs.createMaterial(
  new THREE.MeshLambertMaterial(
    color: 0xffffff
    transparent: true
    opacity: 0.7)
  .4
  .5)
window.glass = (radius)->
  new Physijs.SphereMesh(
    new THREE.SphereGeometry(radius, 10, 10)
    glass_material
    glass_density*(4/3*Math.PI*Math.pow(radius,3))
    )

#SAND
window.sand_material = Physijs.createMaterial(
  new THREE.MeshBasicMaterial
    color: 0xefeefe
  0.8
  0.3)
window.sand = ()->
  new Physijs.SphereMesh(
    new THREE.SphereGeometry(1*(1+Math.random()), 3, 2)
    sand_material
    1 #mass
  )

window.food_material = Physijs.createMaterial(
  new THREE.MeshBasicMaterial
    color: 0xccc
    0.8
    0.3)

add_wall = ()->
  dir_light = new THREE.DirectionalLight(0xffffff, 1.0)
  dir_light.position.set(0, 50, 0)
  scene.add(dir_light)
  for side in window.box_sidel
    box_side = gen_box_side side[0]
    box_side.position.set(side[1][0], side[1][1], side[1][2])
    box_side.wall = true
    scene.add(box_side)
  return

window.add_sand = (fooyeeyeo)->
  nn = Math.floor(n/4)
  for i in [1..nn]
    for j in [1..nn]
      if Math.random() < 0.25
        food_nibblet = food()
        food_nibblet.position.set(-nn+(i-2)*4,tallest+4,-nn+(j-2)*4)
        scene.add(food_nibblet)
      else
        sand_grain = sand()
        sand_grain.position.set(-nn+(i-2)*4,tallest+4,-nn+(j-2)*4)
        scene.add(sand_grain)
  true

window.add_glass = (radius, y_offset)->
  glass_marble = glass(radius)
  glass_marble.position.set(0,10+y_offset,0)
  scene.add(glass_marble)
  return

window.add_glass_balls = (num)->
  for i in [1..num]
    window.add_glass(4*Math.random(),4)
  return

window.scalef = 1000

window.beetle_brain = (monte)->
  monte.applyCentralForce(new THREE.Vector3(scalef*monte.rotation.x, scalef*monte.rotation.y, scalef*monte.rotation.z))

loader = new THREE.JSONLoader()

loader.load("assets/roach/roach.js", (geometry)->
  monte_material = Physijs.createMaterial(
    new THREE.MeshLambertMaterial(
      color: 0x000000)
    .4
    .9)
  window.monte = new Physijs.BoxMesh(
    geometry
    monte_material
    5)
  monte.addEventListener('collision',(other_obj)->
    if other_obj.food
      scene.remove(other_obj))
  monte.scale.set(140,140,140)
  monte.position.set(0,20,0)
  scene.add(monte)
  window.food = ()->
    food_mesh = new Physijs.SphereMesh(
      new THREE.SphereGeometry(1*(1+Math.random()), 3, 2)
      food_material
      1)
    food_mesh.food = true
    food_mesh
  add_sand()
  )

window.kill_monte = ()->
  monte.applyCentralForce(new THREE.Vector3(0,100000,0))

init = ()->
  window.renderer = new THREE.WebGLRenderer(antialias: true)
  window.renderer.setSize(window.innerWidth/2, window.innerHeight/2)
  document.getElementById('beetle').appendChild(window.renderer.domElement)
  window.camera = new THREE.PerspectiveCamera(35, window.innerWidth/window.innerHeight, 1, 1000)
  window.camera.position.set(1.2*n, 2.5*n, 2*n)
  window.scene = new Physijs.Scene
  scene.setGravity(new THREE.Vector3(0,-9800/60.0,0))
  window.camera.lookAt window.scene.position
  window.scene.add window.camera
  add_wall()
  requestAnimationFrame render
  scene.addEventListener 'update', ()->
    scene.simulate(undefined, 2)
  scene.simulate()
  add_glass_balls(16)
  return

window.stats = ()->
  window.monte_y = monte.position.y
  window.obj_heights = [item.position.y for item in scene.__objects when not item.wall]
  window.tallest = obj_heights[0].sort((a,b)->b-a)[0]

render = ()->
  requestAnimationFrame render
  if monte!=undefined
    camera.lookAt monte.position
  beetle_brain(monte)
  window.stats()
  if (new Date().getTime())/1000%30<1
    add_sand()
  window.renderer.render window.scene, window.camera
  return

init()

Highcharts.setOptions(
  global:
    useUTC: false)

$("#chart").highcharts(
  chart:
    type: 'spline'
    animation: Highcharts.svg
    marginRight: 10
    events:
      load: ()->
        series = this.series[0]
        setInterval(()->
          x = (new Date()).getTime()
          series.addPoint([x, tallest])
          10000)
  title:
    text: 'Height of Monte\'s simulation'
  xAxis:
    type: 'datetime'
    tickPixelInterval: 100
  yAxis:
    title:
      text: 'Height, in mm'
    plotLines: [
      value: 0
      width: 1
      color: 0x888888]
  series: [
    name: 'Height data'
    data: []])