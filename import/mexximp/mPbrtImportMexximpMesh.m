function [pbrtNode, includeFile] = mPbrtImportMexximpMesh(scene, mesh, varargin)
%% Convert a mexximp mesh to an mPbrt Object declaration Include file.
%
% pbrtNode = mPbrtImportMexximpMesh(scene, mesh) converts the given
% mexximp mesh to create an mPbrt object declaration within an
% ObjectBegin/ObjectEnd section.
%
% The given mesh should be an element with type "meshes" as
% returned from mexximpSceneElements().  Only the following mesh fields are
% converted:
%   - name
%   - materialIndex
%   - vertices
%   - faces
%   - normals
%   - tangents
%   - textureCoordinates0
%
% The actual vertex data for the given mesh will be written to a separate
% pbrt Include file which to be referenced in the containing pbrt file.
%
% mPbrtImportMexximpMesh( ... 'workingFolder', workingFolder) specify the
% folder where Include file will be written.  The default is pwd().
%
% mPbrtImportMexximpMesh( ... 'meshSubfolder', meshSubfolder) specify the
% sub-folder of the workingFolder where the include file will be written.
% The default is 'pbrt-geometry'.  The Include directive in the containing
% pbrt file will use a relative path which incorporates the meshSubfolder,
% but not the workingFolder.
%
% mPbrtImportMexximpMesh( ... 'rewriteMeshData', rewriteMeshData)
% choose whether to overwrite an existing Include file if it exists (true),
% or to skip over existing files with the same name.  The default is true,
% always write fresh Include files.  Setting rewriteMeshData to false may
% save time for large meshes, at the risk of letting the Include files go
% out of date.
%
% Returns an MPbrtContainer that declares a new named mesh object, along
% with its NamedMaterial and Included geometry.
%
% [pbrtNode, includeFile] = mPbrtImportMexximpMesh(scene, mesh, varargin)
%
% Copyright (c) 2016 mexximp Team

parser = inputParser();
parser.KeepUnmatched = true;
parser.addRequired('scene', @isstruct);
parser.addRequired('mesh', @isstruct);
parser.addParameter('workingFolder', pwd(), @ischar);
parser.addParameter('meshSubfolder', 'pbrt-geometry', @ischar);
parser.addParameter('rewriteMeshData', true, @islogical);
parser.parse(scene, mesh, varargin{:});
scene = parser.Results.scene;
mesh = parser.Results.mesh;
workingFolder = parser.Results.workingFolder;
meshSubfolder = parser.Results.meshSubfolder;
rewriteMeshData = parser.Results.rewriteMeshData;

%% Dig out the name.
meshName = mesh.name;
meshIndex = mesh.path{end};
pbrtName = mexximpCleanName(meshName, meshIndex);

% build the Include folder and file names
includeRelativePath = fullfile(meshSubfolder, [pbrtName '.pbrt']);
includeFile = fullfile(workingFolder, includeRelativePath);
includeFolder = fullfile(workingFolder, meshSubfolder);

%% Add vertex data to an mPbrt trianglemesh Shape.
pbrtShape = MPbrtElement('Shape', ...
    'type', 'trianglemesh', ...
    'name', pbrtName);

data = mPathGet(scene, mesh.path);

if ~isempty(data.faces)
    indices = [data.faces.indices];
    pbrtShape.setParameter('indices', 'integer', indices);
end

if ~isempty(data.vertices)
    pbrtShape.setParameter('P', 'point', data.vertices);
end

if ~isempty(data.textureCoordinates0)
    % only use the first set of texture coordinates
    % always assume 2 uv components (no uvw)
    uv = data.textureCoordinates0(1:2,:);
    pbrtShape.setParameter('uv', 'float', uv);
end

if ~isempty(data.tangents)
    pbrtShape.setParameter('S', 'vector', data.tangents);
end

if ~isempty(data.normals)
    pbrtShape.setParameter('N', 'normal', data.normals);
end

%% Follow 0-based index to the mesh's material.
materialIndex = data.materialIndex + 1;
materialData = scene.materials(materialIndex);

nameQuery = {'key', mexximpStringMatcher('name')};
namePath = {'properties', nameQuery, 'data'};
nameData = mPathGet(materialData, namePath);
materialName = mexximpCleanName(nameData, materialIndex);

%% Build the pbrt object declaration and associated material.
pbrtNode = MPbrtContainer('Object', ...
    'name', pbrtName, ...
    'beginWithName', true);

pbrtMaterial = MPbrtElement.namedMaterial(materialName);
pbrtNode.append(pbrtMaterial);

pbrtInclude = MPbrtElement('Include', 'value', includeRelativePath);
pbrtNode.append(pbrtInclude);


%% Check for opacity textures
opacityTexture = mPbrtQueryProperties(materialData.properties,'textureSemantic','opacity','data','');
if(~isempty(opacityTexture)) 
    
    % Hack to get texture name. We use mPbrtMakeImageMap in
    % mPbrtimportMexximpMaterial in order to create the named texture.
    % We cannot create the texture here, since it cannot within the Object
    % instance (pbrtNode container).
   [~, textureName] = mPbrtMakeImageMap(opacityTexture,'float');
   
   % Attach to mesh
   pbrtOpacity = MPbrtElement('"texture alpha"','value',textureName);
   pbrtNode.append(pbrtOpacity);
end


% if ~rewriteMeshData && skipMeshFileCheck
%    return;
% end

%% If necessary, write the include file.
% if ~rewriteMeshData && 2 == exist(includeFile, 'file')
%    % use an existing Include file
%    return;
% end

% The fopen check is much faster than exist call.
% A file can't be opened for reading if it does not exist.
fid = fopen(includeFile,'r');
if ~rewriteMeshData && (fid ~= -1)
    fclose(fid);
    return;
end

% need a folder to land in
if 7 ~= exist(includeFolder, 'dir')
    mkdir(includeFolder);
end

pbrtShape.printToFile(includeFile);

%% Record the Mexximp element that produced this node.
pbrtNode.extra = mesh;
