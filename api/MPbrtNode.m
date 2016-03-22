classdef MPbrtNode < handle
    % Common interface and utiltiies for things that print themselves to a PBRT file.
    
    properties
        % Arbitrary name for identifying this node.
        name = '';
        
        % PBRT identifier like Shape, Camera, etc.
        identifier = '';
        
        % Arbitrary comment to print along with this node.
        comment = '';
        
        % Prefix for indenting syntax local to this node.
        %   For example, an indented parameter list.
        indent = '  ';
        
        % Format specifier for printing floating point values.
        floatFormat = '%f';
        
        % Format specifier for printing integer values.
        intFormat = '%d';
        
        % Format specifier for parsing numeric values.
        scanFormat = '%f';
    end
    
    methods (Abstract)
        % Print this object to the file at fid.
        %   This object must print itself to the file represented by
        %   fid.  It must prepend the given workingIndent before each
        %   line printed, to maintain "nice" indenting.
        print(self, fid, workingIndent)
    end
    
    methods
        function printSurrounded(self, fid, indent, prefix, string, suffix)
            % Print the given string to the given file, if not empty.
            %   This is a helper method for all nodes.  It handles the
            %   common pattern of printing a string preceeded by an indent
            %   and a prefix and followed by a suffix.  Or, if the given
            %   string is empty, printing nothing.  The idea is to turn
            %   this pattern into a one-liner for calling code.
            %
            %   The given indent, prefix, string, and suffix may contain
            %   escaped characters, like '\n' for newline.
            
            if isempty(string)
                return;
            end
            
            fprintf(fid, [indent, prefix, string, suffix]);
        end
        
        function printValue(self, fid, value, type)
            % Print the given value to the file at fid.
            %   This is a helper method for all nodes.  It takes care
            %   of "quoting" and [bracketing] values as they are printed,
            %   based on the given type and/or the Matlab type of the
            %   given value.  If the given value is empty, prints
            %   nothing.
            %
            %   Prints the value, plus one space.  No indent, no newline.
            %
            %   If the value is a cell array, prints a value for each
            %   element.
            
            if isempty(value)
                return;
            end
            
            % chew through cell arrays recursively
            if iscell(value)
                for vv = 1:numel(value)
                    self.printValue(fid, value{vv}, type);
                end
                return;
            end
            
            % if type missing, check for non-numeric type
            if isempty(type)
                if ischar(value)
                    type = 'string';
                elseif islogical(value)
                    type = 'bool';
                end
            end
            
            % convert vector elements to one string
            value = self.vectorToString(value);
            
            switch type
                case 'raw'
                    fprintf(fid, '%s ', value);
                    
                case {'string', 'texture'}
                    fprintf(fid, '"%s" ', value);
                    
                case 'spectrum'
                    % spectrum may be numeric or string
                    if 0 == numel(self.stringToVector(value))
                        fprintf(fid, '"%s" ', value);
                    else
                        % numeric spectrum should use space, not colon delimiters
                        value(':' == value) = ' ';
                        fprintf(fid, '[%s] ', value);
                    end
                    
                case 'bool'
                    if islogical(value) || isnumeric(value)
                        if value
                            fprintf(fid, '"true" ');
                        else
                            fprintf(fid, '"false" ');
                        end
                    else
                        fprintf(fid, '"%s" ', value);
                    end
                    
                otherwise
                    fprintf(fid, '[%s] ', value);
            end
        end
        
        function string = vectorToString(self, vector)
            % Convert the given numeric vector to a string representation.
            %    Makes a best effort to print the given numeric vector to a
            %    string integer or floating point representation.
            %
            % It's OK if the vector is empty or already a string, we will
            % just return early.
            
            if isempty(vector)
                string = '';
                return;
            end
            
            if ~isnumeric(vector)
                string = vector;
                return;
            end
            
            % try to print compact integers
            if all(vector == round(vector))
                format = [self.intFormat ' '];
            else
                format = [self.floatFormat ' '];
            end
            string = sprintf(format, vector);
            
            % remove trailing space from the final format application
            string = string(1:end-1);
        end
        
        function vector = stringToVector(self, string)
            % Convert the given string representation to a numeric vector.
            %    Makes a best effort to scane the given string for numberic
            %    values and puts them in a 1D matrix.
            %
            % It's OK if the string is empty or already a vector, we will
            % just return early.
            
            if isempty(string)
                vector = [];
                return;
            end
            
            if isnumeric(string)
                vector = string;
                return;
            end
            
            vector = sscanf(string, self.scanFormat);
        end
    end
end