%% Query a material property, return default if no good match.
% This function was originally elevated from mPbrtImportMexximpMaterial. It
% is used to extract a specific value from the properties of a material
% imported from assimp.

% Example:
% diffuseRgb = queryProperties(properties, 'key', 'diffuse', 'data', []);

% Trisha Lian

function result = mPbrtQueryProperties(properties, queryField, queryValue, resultField, defaultResult)
query = {queryField, mexximpStringMatcher(queryValue)};
[resultIndex, resultScore] = mPathQuery(properties, query);
if 1 == resultScore
    result = properties(resultIndex).(resultField);
else
    result = defaultResult;
end

