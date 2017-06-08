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


%{
materialDefault = MPbrtElement.makeNamedMaterial('','uber');
materialDefault.setParameter('Kd', 'spectrum', '300:1 800:1');
materialDefault.setParameter('Ks', 'spectrum', '300:0 800:0');
materialDefault.setParameter('Kr', 'spectrum', '300:0 800:0');
materialDefault.setParameter('roughness','float',0.1);
materialDefault.setParameter('index','float',1.5);
materialDefault.setParameter('opacity', 'spectrum', '300:1 800:1');
%}

%{
materialName = material.name;

materialIndex = material.path{end};
pbrtName = mexximpCleanName(materialName, materialIndex);

pbrtMaterial = MPbrtElement.makeNamedMaterial(pbrtName,'mix');
pbrtTextures = {};
%}
%% Dig out diffuse and specular rgb and texture values.
properties = mPathGet(parser.Results.scene, cat(2, parser.Results.material.path, {'properties'}));
%{
opacityTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'opacity','data','');
opacity = mPbrtQueryProperties(properties, 'key', 'opacity', 'data', 1);
%}

%% Build the pbrt material.


[pbrtMaterial, pbrtTextures] = importNonTransparentMaterial(parser.Results.material,properties);


end

function [pbrtMaterial, pbrtTextures] = importNonTransparentMaterial(material, properties)

materialURoughnessParameter = 'uroughness';
materialVRoughnessParameter = 'vroughness';

materialAmountParameter = 'amount';

materialRoughnessParameter = 'roughness';
materialDiffuseParameter = 'Kd';
materialSpecularParameter = 'Kr';
materialGlossyParameter = 'Ks';
materialIorParameter = 'index';
materialOpacityParameter = 'opacity';



diffuseRgb = mPbrtQueryProperties(properties, 'key', 'diffuse', 'data', []);
specularRgb = mPbrtQueryProperties(properties, 'key', 'specular', 'data', [0.25 0.25 0.25]);
glossyRgb = mPbrtQueryProperties(properties, 'key', 'glossy', 'data', []);

opacity = mPbrtQueryProperties(properties, 'key', 'opacity', 'data', []);
indexOfRefraction = mPbrtQueryProperties(properties, 'key', 'refract_i', 'data', []);

transparency = mPbrtQueryProperties(properties, 'key', 'transparent', 'data', []);
transparency = 1-transparency;

shininess = mPbrtQueryProperties(properties, 'key', 'shininess', 'data', []);
roughness = mPbrtQueryProperties(properties, 'key', 'roughness', 'data', []);

metallic = mPbrtQueryProperties(properties, 'key', 'metallic', 'data', []);

% emissiveRgb = queryProperties(properties, 'key', 'emissive', 'data', []);
% shadingModel = queryProperties(properties, 'key', 'shading_model','data',0);

diffuseTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'diffuse', 'data', '');
specularTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'specular', 'data', '');
glossyTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'glossy', 'data', '');
opacityTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'opacity','data','');
iorTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'refract_i', 'data', '');
bumpTexture = mPbrtQueryProperties(properties, 'textureSemantic','height','data','');
normalTexture = mPbrtQueryProperties(properties, 'textureSemantic','normals','data','');


metallicTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'metallic','data','');
roughnessTexture = mPbrtQueryProperties(properties, 'textureSemantic', 'roughness','data','');

% Dig out the material name.
materialName = material.name;

materialIndex = material.path{end};
pbrtNameA = mexximpCleanName([materialName 'A'], materialIndex);
pbrtNameB = mexximpCleanName([materialName 'B'], materialIndex);

pbrtName = mexximpCleanName(materialName, materialIndex);

% The basic material is a 'Substrate' material

materialA = MPbrtElement.makeNamedMaterial(pbrtNameA,'substrate');
materialA.setParameter('Kd', 'spectrum', '300:1 800:1');
materialA.setParameter('Ks', 'spectrum', '300:0.25 800:0.25');
materialA.setParameter('uroughness','float',0.1);
materialA.setParameter('vroughness','float',0.1);

pbrtTextures = {}; materialB = {};

if ~isempty(materialDiffuseParameter) && ~isempty(materialA.getParameter(materialDiffuseParameter))
    if ~isempty(diffuseTexture) && ischar(diffuseTexture)
        [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(diffuseTexture,'spectrum');
        materialA.setParameter(materialDiffuseParameter, 'texture', textureName);
    elseif ~isempty(diffuseRgb)
        materialA.setParameter(materialDiffuseParameter, 'rgb', diffuseRgb(1:3));
    end
end


if ~isempty(materialURoughnessParameter) && ~isempty(materialA.getParameter(materialURoughnessParameter))
    if ~isempty(roughnessTexture) && ischar(roughnessTexture)
        [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(roughnessTexture,'float');
        materialA.setParameter(materialURoughnessParameter, 'texture', textureName);
    elseif ~isempty(roughness)
        materialA.setParameter(materialURoughnessParameter, 'float', roughness);
    end
end

if ~isempty(materialVRoughnessParameter) && ~isempty(materialA.getParameter(materialVRoughnessParameter))
    if ~isempty(roughnessTexture) && ischar(roughnessTexture)
        [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(roughnessTexture,'float');
        materialA.setParameter(materialVRoughnessParameter, 'texture', textureName);
    elseif ~isempty(roughness)
        materialA.setParameter(materialVRoughnessParameter, 'float', roughness);
    end
end

% Add bump map if present
if ~isempty(bumpTexture)&& ischar(bumpTexture)
    [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(bumpTexture,'float');
    materialBumpParameter = 'bumpmap';
    materialA.setParameter(materialBumpParameter, 'texture', textureName);
end

% Add normal map if present
if ~isempty(normalTexture)&& ischar(normalTexture)
    [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(normalTexture,'spectrum');
    materialNormalParameter = 'normalmap';
    materialA.setParameter(materialNormalParameter, 'texture', textureName);
end

if isempty(metallicTexture) && isempty(metallic)
    % We have the Albedo+spectular workflow
    % We don't use a metal to simulate shine.
   
    
    if ~isempty(materialGlossyParameter) && ~isempty(materialA.getParameter(materialGlossyParameter))
        if ~isempty(specularTexture) && ischar(specularTexture) %isempty(glossyTexture) && ischar(glossyTexture)
            [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(specularTexture,'spectrum');
            materialA.setParameter(materialGlossyParameter, 'texture', textureName);
        elseif ~isempty(specularRgb) %isempty(glossyRgb)
            materialA.setParameter(materialGlossyParameter, 'rgb', specularRgb(1:3));
        end
    end
    
    metallic = [0 0 0];
    metallicTexture = [];
    
end
    
%% Otherwise we are in the albedo+metalness workflow

% The other material is a 'Metal' material
materialB = MPbrtElement.makeNamedMaterial(pbrtNameB,'shinymetal');
materialB.setParameter('Ks','spectrum', '300:0.9 800:0.9');
materialB.setParameter('Kr', 'spectrum', '300:1 800:1');
materialB.setParameter('roughness','float',0.1);


if ~isempty(materialSpecularParameter) && ~isempty(materialB.getParameter(materialSpecularParameter))
    if ~isempty(diffuseTexture) && ischar(diffuseTexture)
        [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(diffuseTexture,'spectrum');
        materialB.setParameter(materialSpecularParameter, 'texture', textureName);
    elseif ~isempty(diffuseRgb)
        materialB.setParameter(materialSpecularParameter, 'rgb', diffuseRgb(1:3));
    end
end

if ~isempty(materialRoughnessParameter) && ~isempty(materialB.getParameter(materialRoughnessParameter))
    if ~isempty(roughnessTexture) && ischar(roughnessTexture)
        [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(roughnessTexture,'float');
        materialB.setParameter(materialRoughnessParameter, 'texture', textureName);
    elseif ~isempty(roughness)
        materialB.setParameter(materialRoughnessParameter, 'float', roughness);
    end
end

% Add bump map if present
if ~isempty(bumpTexture)&& ischar(bumpTexture)
    [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(bumpTexture,'float');
    materialBumpParameter = 'bumpmap';
    materialB.setParameter(materialBumpParameter, 'texture', textureName);
end

% Add normal map if present
if ~isempty(normalTexture)&& ischar(normalTexture)
    [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(normalTexture,'spectrum');
    materialNormalParameter = 'normalmap';
    materialB.setParameter(materialNormalParameter, 'texture', textureName);
end

    
% Finally we mix the two together
pbrtMaterial = MPbrtElement.makeNamedMaterial(pbrtName,'mix');
pbrtMaterial.setParameter('amount','rgb',[0 0 0]);
pbrtMaterial.setParameter('namedmaterial1','string',pbrtNameB);
pbrtMaterial.setParameter('namedmaterial2','string',pbrtNameA);
pbrtMaterial.setParameter('opacity','rgb',[1 1 1]);


if ~isempty(materialAmountParameter) && ~isempty(pbrtMaterial.getParameter(materialAmountParameter))
    if ~isempty(metallicTexture) && ischar(metallicTexture)
        [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(metallicTexture,'spectrum');
        pbrtMaterial.setParameter(materialAmountParameter, 'texture', textureName);
    elseif ~isempty(metallic)
        pbrtMaterial.setParameter(materialAmountParameter, 'rgb', metallic);
    end
end


if ~isempty(materialOpacityParameter) && ~isempty(pbrtMaterial.getParameter(materialOpacityParameter))
    if ~isempty(opacityTexture) && ischar(opacityTexture)
        [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(opacityTexture,'spectrum');
        pbrtMaterial.setParameter(materialOpacityParameter, 'texture', textureName);
        
        % We also add a 'float' texture used by alpha parameter in the
        % mesh definition
        [pbrtTextures{end+1}, textureName] = mPbrtMakeImageMap(opacityTexture,'float');
    elseif ~isempty(opacity)
        pbrtMaterial.setParameter(materialOpacityParameter, 'rgb', [opacity opacity opacity]);
    end
end
    





%{
% Create an opacity (i.e. mask) texture if present. This texture is later linked in
% mPbrtImportMexximpMesh.
% We export opacity maps both as floats and spectrum because the two representations are used
% for textures (spectrum) and meshes (float).
if ~isempty(opacityTexture) && ischar(opacityTexture)
    [pbrtTextures{end+1}, ~] = mPbrtMakeImageMap(opacityTexture,'spectrum');
    [pbrtTextures{end+1}, ~] = mPbrtMakeImageMap(opacityTexture,'float');
end
%}

%% Record the Mexximp element that produced this node.
pbrtMaterial.extra = material;

pbrtMaterial = {materialA, materialB, pbrtMaterial};

end


