function pbrtScene = mPbrtImportMexximp(mexximpScene, varargin)
%% Convert a mexximp scene struct to an mPbrtScene object.
%
% pbrtScene = mPbrtImportMexximp(mexximpScene) converts the given
% mexximpScene struct to an MPbrtScene object suitable for modifying,
% writing to file, rendering, etc.
%
% This function forwards any named parameters to various helper functions,
% including:
%   - mPbrtImportMexximpCamera()
%   - mPbrtImportMexximpLight()
%   - mPbrtImportMexximpMaterial()
%   - mPbrtImportMexximpMesh()
%   - mPbrtImportMexximpNode()
% Please see these functions documentation about what parameters they
% accept.  (Sorry not to reproduce all of this this parameter documentation
% here. It would be handy for a while, but it would probably go out of
% date.)
%
% Returns an MPbrtScene object based on the given mexximpScene struct.
%
% pbrtScene = mPbrtImportMexximp(mexximpScene, varargin)
%
% Copyright (c) 2016 mexximp Team

parser = inputParser();
parser.addRequired('mexximpScene', @isstruct);
parser.parse(mexximpScene);
mexximpScene = parser.Results.mexximpScene;

%% Fresh scene to add to.
pbrtScene = MPbrtScene();

%% Camera and POV transformations.
elements = mexximpSceneElements(mexximpScene);
elementTypes = {elements.type};
cameraInds = find(strcmp('cameras', elementTypes));
for cc = cameraInds
    pbrtNode = mPbrtImportMexximpCamera(mexximpScene, elements(cc), varargin{:});
    pbrtScene.overall.append(pbrtNode);
end

%% MakeNamedMaterial for each material.
%   Invoked with NamedMaterial by nodes below.
materialInds = find(strcmp('materials', elementTypes));
for mm = materialInds
    pbrtNode = mPbrtImportMexximpMaterial(mexximpScene, elements(mm), varargin{:});
    pbrtScene.world.append(pbrtNode);
end

%% Lights and world transformations with AttributeBegin/End.
lightInds = find(strcmp('lights', elementTypes));
for ll = lightInds
    pbrtNode = mPbrtImportMexximpLight(mexximpScene, elements(ll), varargin{:});
    pbrtScene.world.append(pbrtNode);
end

%% Named ObjectBegin/End for each mesh.
%   Invoked with ObjectInstance by nodes below.
meshInds = find(strcmp('meshes', elementTypes));
for mm = meshInds
    pbrtNode = mPbrtImportMexximpMesh(mexximpScene, elements(mm), varargin{:});
    pbrtScene.world.append(pbrtNode);
end

%% Objects and world transformations with AttributeBegin/End.
nodeInds = find(strcmp('nodes', elementTypes));
for nn = nodeInds
    objects = mPbrtImportMexximpNode(mexximpScene, elements(nn), varargin{:});
    
    % skip nodes that don't invoke any mesh objects
    for oo = 1:numel(objects)
        pbrtScene.world.append(objects{oo});
    end
end
