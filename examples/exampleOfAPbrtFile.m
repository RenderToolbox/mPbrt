% This is an example of how to build and write a PBRT scene with mPbrt.
%
% This example recreates the "original" example PBRT file from the official
% PBRT onlint documentation:
%   http://www.pbrt.org/fileformat.html
%
% Here's what the original looks like:
%     LookAt 0 10 100   0 -1 0 0 1 0
%     Camera "perspective" "float fov" [30]
%     PixelFilter "mitchell" "float xwidth" [2] "float ywidth" [2]
%     Sampler "bestcandidate"
%     Film "image" "string filename" ["simple.exr"]
%          "integer xresolution" [200] "integer yresolution" [200]
% 
%     WorldBegin
%     AttributeBegin
%       CoordSysTransform "camera"
%       LightSource "distant"
%                   "point from" [0 0 0] "point to"   [0 0 1]
%                   "rgb L"    [3 3 3]
%     AttributeEnd
% 
%     AttributeBegin
%       Rotate 135 1 0 0
%       Texture "checks" "spectrum" "checkerboard"
%               "float uscale" [4] "float vscale" [4]
%               "rgb tex1" [1 0 0] "rgb tex2" [0 0 1]
%       Material "matte"
%                "texture Kd" "checks"
%       Shape "disk" "float radius" [20] "float height" [-1]
%     AttributeEnd
%     WorldEnd
%
% Now let's build it!
%
% BSH

%% Start with a blank scene.
clear;
clc;

scene = MPbrtScene();

%% Add the content at the "overall" level.
lookAt = MPbrtElement('LookAt', '', '');
lookAt.value = [0 10 100   0 -1 0 0 1 0];
lookAt.valueType = 'raw';
scene.overall.append(lookAt);

camera = MPbrtElement('Camera', 'perspective', '');
camera.setParameter('fov', 'float', 30);
scene.overall.append(camera);

filter = MPbrtElement('PixelFilter', 'mitchell', '');
filter.setParameter('xwidth', 'float', 2);
filter.setParameter('ywidth', 'float', 2);
scene.overall.append(filter);

sampler = MPbrtElement('Sampler', 'bestcandidate', '');
scene.overall.append(sampler);

film = MPbrtElement('Film', 'image', '');
film.setParameter('filename', 'string', 'simple.exr');
film.setParameter('xresolution', 'integer', 200);
film.setParameter('yresolution', 'integer', 200);
scene.overall.append(film);

%% Add a light to the world.
lightAttrib = MPbrtContainer('Attribute', '');
scene.world.append(lightAttrib);

coordXForm = MPbrtElement('CoordSysTransform', '', '');
coordXForm.value = 'camera';
lightAttrib.append(coordXForm);

lightSource = MPbrtElement('LightSource', 'distant', '');
lightSource.setParameter('from', 'point', [0 0 0]);
lightSource.setParameter('to', 'point', [0 0 1]);
lightSource.setParameter('L', 'rgb', [3 3 3]);
lightAttrib.append(lightSource);

%% Add a shape to the world.
shapeAttrib = MPbrtContainer('Attribute', '');
scene.world.append(shapeAttrib);

rotate = MPbrtElement('Rotate', '', '');
rotate.value = [135 1 0 0];
rotate.valueType = 'raw';
shapeAttrib.append(rotate);

texture = MPbrtElement('Texture', 'checkerboard', '');
texture.value = {'checks', 'spectrum'};
texture.setParameter('uscale', 'float', 4);
texture.setParameter('vscale', 'float', 4);
texture.setParameter('tex1', 'rgb', [1 0 0]);
texture.setParameter('tex2', 'rgb', [0 0 1]);
shapeAttrib.append(texture);

material = MPbrtElement('Material', 'matte', '');
material.setParameter('Kd', 'texture', 'checks');
shapeAttrib.append(material);

shape = MPbrtElement('Shape', 'disk', '');
shape.setParameter('radius', 'float', 20);
shape.setParameter('height', 'float', -1);
shapeAttrib.append(shape);

%% Print the scene to a file.
%   how did it come out?

pathHere = fileparts(which('exampleOfAPbrtFile.m'));
outputFile = fullfile(pathHere, 'exampleOfAPbrtFile.pbrt');
scene.printToFile(outputFile);
