% This is an example of how to import a mexximp sceene and convert to mPbrt.
%
% This example uses the Assimp tool to load a 3D model of the millenium
% falcon obtained from the web.
%   http://www.assimp.org/
%
% It uses the mexximp tool to get the loaded 3D model into Matlab.
%   https://github.com/RenderToolbox3/mexximp
%
% It usees utilities in import/mexximp to convert the mexximp struct
% representation of the scene to an MPbrt object graph.
%
% Finally, it dumps out a PBRT scene file.  If PBRT is found,
% it tries to get the scene file rendered.
%
% 2016 benjamin.heasly@gmail.com

clear;
clc;

%sourceFile = which('millenium-falcon.obj');
%sourceFile = '~/Downloads/1a9b552befd6306cc8f2d5fe7449af61/model.obj';
sourceFile = which('model.obj');
outputFolder = fullfile(tempdir(), 'mexximpImportExample');


%% Load the 3D scene.
[mexximpScene, mexximpElements] = mexximpCleanImport(sourceFile, ...
    'workingFolder', outputFolder, ...
    'toReplace', {'png', 'jpg'}, ...
    'targetFormat', 'exr', ...
    'flipUVs', true);

% add missing camera and lights
mexximpScene = mexximpCentralizeCamera(mexximpScene, 'viewAxis', [.25 .25 1]);
mexximpScene = mexximpAddLanterns(mexximpScene, 'lanternRgb', [10 11 12]);

%% Convert the mexximp scene struct to an mPbrt object graph.

% template material to fill in during conversion
materialDefault = MPbrtElement.makeNamedMaterial('', 'matte');
materialDefault.setParameter('Kd', 'rgb', 0.5 * [1 1 1]);

% convert mexximp struct -> mPbrt objects
pbrtScene = mPbrtImportMexximp(mexximpScene, ...
    'workingFolder', outputFolder, ...
    'materialDefault', materialDefault, ...
    'materialDiffuseParameter', 'Kd');

% add missing elements mexximp doesn't know about
sampler = MPbrtElement('Sampler', 'type', 'lowdiscrepancy');
pbrtScene.overall.append(sampler);

integrator = MPbrtElement('SurfaceIntegrator', 'type', 'directlighting');
pbrtScene.overall.append(integrator);

filter = MPbrtElement('PixelFilter', 'type', 'gaussian');
filter.setParameter('alpha', 'float', 2);
filter.setParameter('xwidth', 'float', 2);
filter.setParameter('ywidth', 'float', 2);
pbrtScene.overall.append(filter);

film = MPbrtElement('Film', 'type', 'image');
film.setParameter('xresolution', 'integer', 640);
film.setParameter('yresolution', 'integer', 480);
pbrtScene.overall.append(film);


%% Print out a PBRT scene file.
sceneFile = fullfile(outputFolder, 'mexximpImportExample.pbrt');
pbrtScene.printToFile(sceneFile);

%% Try to render with PBRT.

% locate a pbrt executable?
pbrt = 'pbrt';
if isempty(pbrt)
    disp('PBRT renderer not found.');
    return;
end

% render
imageFile = fullfile(outputFolder, 'mexximpImportExample.exr');
pbrtCommand = sprintf('%s --outfile "%s" "%s"\n', ...
    pbrt, imageFile, sceneFile);
system(pbrtCommand);

%% Convert exr to png for viewing.
% see exrtools: http://scanline.ca/exrtools/
normalized = mexximpExrTools(imageFile, ...
    'operation', 'exrnormalize', ...
    'outFile', fullfile(outputFolder, 'normalized.exr'));
toneMapped = mexximpExrTools(normalized, ...
    'operation', 'exrpptm', ...
    'outFile', fullfile(outputFolder, 'toneMapped.exr'));
renormalized = mexximpExrTools(toneMapped, ...
    'operation', 'exrnormalize', ...
    'outFile', fullfile(outputFolder, 'renormalized.exr'));
pngFile = mexximpExrTools(renormalized);
imshow(pngFile)
