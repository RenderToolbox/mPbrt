%% Make an imagemap texture with a name like its image file.
% This function was originally elevated from mPbrtImportMexximpMaterial.

% Example: [pbrtTextures{end+1}, textureName] =
% makeImageMap(diffuseTexture,'spectrum');

% Trisha Lian

function [texture, textureName] = mPbrtMakeImageMap(imageFile,textureType)
[~, textureName] = fileparts(imageFile);
texture = MPbrtElement.texture(textureName, textureType, 'imagemap');
texture.setParameter('filename', 'string', imageFile);
