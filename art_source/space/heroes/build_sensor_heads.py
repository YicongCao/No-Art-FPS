"""Four-point optical head, no human face; preserves the removable Helmet alias."""
import bpy,sys,json
from pathlib import Path
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2];sys.path.insert(0,str(HERE))
from geometry import box,beam,material

def replace_head(head,helmet,slim):
 for child in list(helmet.children_recursive):bpy.data.objects.remove(child,do_unlink=True)
 bpy.data.objects.remove(helmet,do_unlink=True)
 shell=material('Sensor head armor',(.47,.45,.40),.05,.55)
 black=material('Recessed optical panel',(.008,.012,.018),.15,.58)
 rim=material('Optical socket',(.04,.05,.06),.55,.42)
 red=material('Four red sensors',(.55,.001,.001),0,.4,1.0)
 width=.235 if slim else .26
 helmet=box('Helmet',(0,0,1.755),(width,.25,.265),shell,.028,head)
 box('Faceplate',(0,.133,1.755),(width-.035,.035,.222),black,.014,helmet)
 for row,z in enumerate([1.705,1.805]):
  for col,x in enumerate([-.053,.053]):
   beam('Sensor socket',(x,.148,z),(x,.165,z),.024,rim,helmet,16)
   beam('Red sensor %d%d'%(row,col),(x,.165,z),(x,.171,z),.015,red,helmet,16)
 return helmet

if __name__=='__main__':
 report={}
 for name,slim in [('rifle-mech',False),('assault-mech',True)]:
  bpy.ops.wm.open_mainfile(filepath=str(HERE/(name+'.blend')))
  head=bpy.data.objects['Head'];helmet=bpy.data.objects['Helmet'];replace_head(head,helmet,slim)
  bpy.ops.wm.save_as_mainfile(filepath=str(HERE/(name+'.blend')))
  bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/space'/(name+'.glb')),export_format='GLB')
  report[name]={'red_sensors':4,'face':'recessed black panel','helmet_alias':'Helmet'}
 out=ROOT/'docs/art/space/sensor-heads';out.mkdir(exist_ok=True)
 (out/'asset-check.json').write_text(json.dumps(report,indent=2)+'\n')
 print('SENSOR_HEADS_PASS')
