function [pbrtMaterial, pbrtTextures] = mPbrtImportMexximpMaterial(scene, material, varargin)
%% Convert a mexximp material to an mPbrt MakeNamedMaterial element.
%
% pbrtMaterial = mPbrtImportMexximpMaterial(scene, material) cherry picks
% material properties from the given mexximp material and scene and uses
% these to create an mPbrt scene Material element.
%
% The given material should be an element with type "materials" as
% returned from mexximpSceneElements().
%
% The Assimp/mexximp material model is flexible, complicated, and messy.
% This function cherry picks from the given mexximp scene and material
% and ignores most material properties.  Only the following mexximp
% material properties are used (see mexximpConstants('materialPropertyKey'))':
%   - 'name'
%   - 'diffuse'
%   - 'specular'
%   - 'texture'
%   - 'glossy'
%   - 'refract_i'
%
% By default, the new pbrt material will have type "uber", diffuse
% parameter "Kd" and specular parameter "Kr".  These may be overidden by
% passing values for these named parameters.  For example:
%   mPbrtImportMexximpMaterial( ...
%       'materialDefault', MPbrtElement.makeNamedMaterial('', 'anisoward'), ...
%       'materialDiffuseParameter', 'Kd', ...
%       'materialSpecularParameter', 'Ks');
%
% Returns an MPbrtElement with identifier MakeNamedMaterial and parameters
% filled in based on mexximp material properties.
%
% pbrtMaterial = mPbrtImportMexximpMaterial(scene, material, varargin)
%
% Copyright (c) 2016 mexximp Team

parser = inputParser();
parser.KeepUnmatched = true;
parser.addRequired('scene', @isstruct);
parser.addRequired('material', @isstruct);
% parser.addParameter('materialDefault', MPbrtElement.makeNamedMaterial('', 'uber'), @isobject);
% parser.addParameter('materialDiffuseParameter', 'Kd', @ischar);
% parser.addParameter('materialSpecularParameter', 'Kr', @ischar);
% parser.addParameter('materialGlossyParameter', 'Ks', @ischar);
% parser.addParameter('materialIorParameter', 'index', @ischar);
% parser.addParameter('materialRoughnessParameter', 'roughness', @ischar);
% parser.addParameter('materialOpacityParameter', 'opacity', @ischar);
parser.parse(scene, material, varargin{:});
% scene = parser.Results.scene;
% material = parser.Results.material;
% materialDefault = parser.Results.materialDefault;
% materialDiffuseParameter = parser.Results.materialDiffuseParameter;
% materialSpecularParameter = parser.Results.materialSpecularParameter;
% materialGlossyParameter = parser.Results.materialGlossyParameter;
% materialIorParameter = parser.Results.materialIorParameter;
% materialRoughnessParameter = parser.Results.materialRoughnessParameter;
% materialOpacityParameter = parser.Results.materialOpacityParameter;



materialDefault = MPbrtElement.makeNamedMaterial('','uber');
materialDefault.setParameter('Kd', 'spectrum', '300:1 800:1');
materialDefault.setParameter('Ks', 'spectrum', '300:0 800:0');
materialDefault.setParameter('Kr', 'spectrum', '300:0 800:0');
materialDefault.setParameter('roughness','float',0.1);
materialDefault.setParameter('index','float',1.5);
materialDefault.setParameter('opacity', 'spectrum', '300:1 800:1');
materialDiffuseParameter = 'Kd';
materialSpecularParameter = 'Kr';
materialGlossyParameter = 'Ks';
materialIorParameter = 'index';
materialOpacityParameter = 'opacity';

pbrtTextures = {};

%% Dig out the material name.
materialName = parser.Results.material.name;

materialIndex = parser.Results.material.path{end};
pbrtName = mexximpCleanName(materialName, materialIndex);

%% Dig out diffuse and specular rgb and texture values.
properties = mPathGet(parser.Results.scene, cat(2, parser.Results.material.path, {'properties'}));
diffuseRgb = mPbrtQueryProperties(properties, 'key', 'diffuse', 'data', []);
specularRgb = mPbrtQueryProperties(properties, 'key', 'specular', 'data', []);
glossyRgb = mPbrtQueryProperties(properties, 'key', 'glossy', 'data', []);

opacity = mPbrtQueryProperties(properties, 'key', 'opacity', 'data', []);
indexOfRefraction = mPbrtQueryProperties(properties, 'key', 'refract_i', 'data', []);

transparency = mPbrtQueryProperties(properties, 'key', 'transparent', 'data', []);
%transparency = 1-transparency;

shininess = mPbrtQueryProperties(properties, 'key', 'shininess', 'data', []);

% emissiveRgb = queryProperties(properties, 'key', 'emissive', 'data', []);
% shadingModel = queryProperties(properties, 'key', 'shading_model','data',0);

diffuseTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'diffuse', 'data', '');
specularTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'specular', 'data', '');
glossyTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'glossy', 'data', '');
opacityTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'opacity','data','');
iorTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'refract_i', 'data', '');
bumpTexture = mPbrtQueryProperties(properties, 'textureSemantic','height','data','');

%% Build the pbrt material.

pbrtMaterial = MPbrtElement.makeNamedMaterial(pbrtName, materialDefault.type);
pbrtMaterial.parameters = materialDefault.parameters;

if ~isempty(materialDiffuseParameter) && ~isempty(pbrtMaterial.getParameter(materialDiffuseParameter))
    if ~isempty(diffuseTexture) && ischar(diffuseTexture)
        [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(diffuseTexture,'spectrum');
        pbrtMaterial.setParameter(materialDiffuseParameter, 'texture', textureName);
    elseif ~isempty(diffuseRgb)
        pbrtMaterial.setParameter(materialDiffuseParameter, 'rgb', diffuseRgb(1:3));
    end
end

%{
if ~isempty(materialSpecularParameter) && ~isempty(pbrtMaterial.getParameter(materialSpecularParameter))
    if ~isempty(specularTexture) && ischar(specularTexture)
        [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(specularTexture,'spectrum');
        pbrtMaterial.setParameter(materialDiffuseParameter, 'texture', textureName);
    elseif ~isempty(specularRgb)
        pbrtMaterial.setParameter(materialSpecularParameter, 'rgb', specularRgb(1:3));
    end
end
%}

% The glossy parameter from PBRT is equivalent to Specular parameter from
% OBJ/MTL
if ~isempty(materialGlossyParameter) && ~isempty(pbrtMaterial.getParameter(materialGlossyParameter))
    if ~isempty(specularTexture) && ischar(specularTexture) %isempty(glossyTexture) && ischar(glossyTexture)
        [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(specularTexture,'spectrum');
        pbrtMaterial.setParameter(materialGlossyParameter, 'texture', textureName);
    elseif ~isempty(specularRgb) %isempty(glossyRgb)
        pbrtMaterial.setParameter(materialGlossyParameter, 'rgb', specularRgb(1:3));
    end
end

if ~isempty(materialIorParameter) && ~isempty(pbrtMaterial.getParameter(materialIorParameter))
    if ~isempty(iorTexture) && ischar(iorTexture)
        [pbrtTextures{end+1}, textureName] = mPbrtImageImageMap(iorTexture,'float');
        pbrtMaterial.setParameter(materialIorParameter, 'texture', textureName);
    elseif ~isempty(indexOfRefraction)
        pbrtMaterial.setParameter(materialIorParameter, 'float', indexOfRefraction);
    end
end

if ~isempty(materialOpacityParameter) && ~isempty(pbrtMaterial.getParameter(materialOpacityParameter))
    if ~isempty(opacityTexture) && ischar(opacityTexture)
        [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(opacityTexture,'spectrum');
        pbrtMaterial.setParameter(materialOpacityParameter, 'texture', textureName);
    elseif ~isempty(opacity)
        pbrtMaterial.setParameter(materialOpacityParameter, 'rgb', transparency);
    end
end

% Roughness in PBRT is 1/shininess from OBJ/MTL file
if ~isempty(shininess)
    pbrtMaterial.setParameter('roughness', 'float', 1/shininess);
end



% Add bump map if present
if ~isempty(bumpTexture)&& ischar(bumpTexture)
    [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(bumpTexture,'float');
    materialBumpParameter = 'bumpmap';
    pbrtMaterial.setParameter(materialBumpParameter, 'texture', textureName);
end

% Create an opacity (i.e. mask) texture if present. This texture is later linked in
% mPbrtImportMexximpMesh.
% We export opacity maps both as floats and spectrum because the two representations are used
% for textures (spectrum) and meshes (float).
if ~isempty(opacityTexture) && ischar(opacityTexture)
    [pbrtTextures{end+1}, ~] = mPbrtMakeImageMap(opacityTexture,'spectrum');
    [pbrtTextures{end+1}, ~] = mPbrtMakeImageMap(opacityTexture,'float');
end

%% Record the Mexximp element that produced this node.
pbrtMaterial.extra = material;

