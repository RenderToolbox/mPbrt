# mPbrt
Matlab tools for constructing and writing PBRT scene files. 

The idea:  We want to be able to auto-generate [PBRT](http://www.pbrt.org/fileformat.html) scene files from Matlab.  We want to start with a convenient Matlab representation of the whole scene.  We should be able to identify elements of the scene by name and type, and add/update/remove them while working.  When done working, we should be able to write out a PBRT scene file based on the matlab representation.

For now we are only going from Matlab to PBRT.  We are not trying to parse existing PBRT files.

# Get Started
To get started, clone this repository and add it to your Matlab path.

See the example script at [examples/exampleOfAPbrtFile.m](https://github.com/RenderToolbox3/mPbrt/blob/master/examples/exampleOfAPbrtFile.m).  You should be able to run the script right away and produce a PBRT scene file like [this one](https://github.com/RenderToolbox3/mPbrt/blob/master/examples/exampleOfAPbrtFile.pbrt).

The idea of this example script is to reproduce the "official" example scene file from the [pber-v2 file format documentation](http://www.pbrt.org/fileformat.html).

# The API
The mPbrt API is based on a Scene, which contains Elements and Containers.  These are written with Matlab's [Object-Oriented Programming](http://www.mathworks.com/help/matlab/object-oriented-programming.html).

In general, you create objects and specify their names, types, values, etc.  Then the objects take care of writing well-formed PBRT statements to a scene file.

### Elements
Elements are things like shapes, light sources, the camera, etc.  Each one has a declaration line followed by zero or more parameter lines.

Here is an example of creating a `LightSource` element:
```
lightSource = MPbrtElement('LightSource', 'type', 'distant');
lightSource.setParameter('from', 'point', [0 0 0]);
lightSource.setParameter('to', 'point', [0 0 1]);
lightSource.setParameter('L', 'rgb', [3 3 3]);
```

This produces the following PBRT syntax in the output file:
```
LightSource "distant"   
  "point from" [0 0 0] 
  "point to" [0 0 1] 
  "rgb L" [3 3 3] 
```

### Containers
Containers are holders for nested elements.  For example the stuff that goes between `WorldBegin` and `WorldEnd` goes in a "World" container.  Likewise for stuff that goes in `AttributeBegin`/`AttributeEnd` sections, and other  `Begin`/`End` sections.

Here is an example of creating an `AttributeBegin`/`AttributeEnd` section that holds a coordinate transform and a light source:
```
lightAttrib = MPbrtContainer('Attribute');

coordXForm = MPbrtElement.transformation('CoordSysTransform', 'camera');
lightAttrib.append(coordXForm);

lightSource = MPbrtElement('LightSource', 'type', 'distant');
lightSource.setParameter('from', 'point', [0 0 0]);
lightSource.setParameter('to', 'point', [0 0 1]);
lightSource.setParameter('L', 'rgb', [3 3 3]);
lightAttrib.append(lightSource);
```

This produces the following PBRT syntax in the output file:
```
AttributeBegin
  CoordSysTransform "camera"   
  LightSource "distant"   
    "point from" [0 0 0] 
    "point to" [0 0 1] 
    "rgb L" [3 3 3] 
AttributeEnd
```

### Comments
Elements and Containers both have the optional properties `name` and `comment`.  When these are provided, the objects will print extra comment lines before any other syntax.

Here is an example of adding a name and comment to a coordinate transform:
```
coordXForm = MPbrtElement.transformation('CoordSysTransform', 'camera', ...
    'name', 'camera-transform', ...
    'comment', 'Move the coordinate system to match the camera.');
```

This produces the following PBRT syntax in the output file:
```
# camera-transform
# Move the coordinate system to match the camera.
CoordSysTransform "camera"   
```

### Add, Find, and Delete from a Scene
