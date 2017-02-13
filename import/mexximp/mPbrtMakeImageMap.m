%% Make an imagemap texture with a name like its image file.
% This function was originally elevated from mPbrtImportMexximpMaterial.
% We append the texture type to texture name because the same texture can
% be also used as a bumpmap, in which case its type is different.

% Example: [pbrtTextures{end+1}, textureName] =
% makeImageMap(diffuseTexture,'spectrum');

% Trisha Lian

function [texture, textureName] = mPbrtMakeImageMap(imageFile,textureType)
[~, textureName] = fileparts(imageFile);
textureName = sprintf('%s_%s',textureName,textureType);
texture = MPbrtElement.texture(textureName, textureType, 'imagemap');
texture.setParameter('filename', 'string', imageFile);
