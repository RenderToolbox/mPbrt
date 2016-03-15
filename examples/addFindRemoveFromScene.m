% This is an example of how to build, search and update an mPbrt scene.
%
% This example creates a scene that contains two elements.  It searches the
% scene for one of the elements and updates it.  Then it removes the other
% element from the scene altogether.
%
% These operations, add, find, and remove, should make mPbrt fun!  They
% should also make it possible to integrate mPbrt with other Matlab scripts
% and toolboxes that wish to generate PBRT files.
%

%% Start with a blank scene.
clear;
clc;

scene = MPbrtScene();

%% Add a camera element at the "overall" level.
scene.overall.append(MPbrtElement('Camera', 'type', 'perspective'));

%% Add a light to the world, nested inside an Attribute section.
lightAttrib = MPbrtContainer('Attribute');
scene.world.append(lightAttrib);
lightAttrib.append(MPbrtElement('LightSource', 'type', 'distant', 'name', 'the-light'));

%% Find the camera and update it.
camera = scene.overall.find('Camera');
camera.setParameter('fov', 'float', 30);

%% Find the light and remove it.
% remove using the find() method, plus the "remove" flag
removedLight = scene.world.find('LightSource', ...
    'name', 'the-light', ...
    'remove', true);

% since the light was removed, we can no longer find it in the scene
shouldBeEmpty = scene.world.find('LightSource', ...
    'name', 'the-light');
