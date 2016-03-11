classdef MPbrtContainer < MPbrtNode
    % Holder for nested nodes inside Begin/End syntax.
    %   The idea here is to build up containers and elements in a nested
    %   fashion.  When printing, we delimit the nested things with
    %   Begin/End syntax as well as indenting.  We can also add, find, and
    %   remove nested elements.
    
    properties
        % Collection of nested containers or elements.
        nested = {};
    end
    
    methods
        function self = MPbrtContainer(identifier, name)
            self.identifier = identifier;
            self.name = name;
        end
        
        function print(self, fid, workingIndent)
            % Required method from MPbrtNode.
            %   Print this container and its nested nodes.  Delimit this
            %   container and its contents with Begin/End and indenting.
            if ~isempty(self.name)
                fprintf(fid, '%s# %s\n', workingIndent, self.name);
            end
            
            if ~isempty(self.name)
                fprintf(fid, '%s# %s\n', workingIndent, self.comment);
            end
            
            if ~isempty(self.identifier)
                if isempty(self.name)
                    fprintf(fid, '%s%sBegin\n', workingIndent, self.identifier);
                else
                    fprintf(fid, '%s%sBegin "%s"\n', workingIndent, self.identifier, self.name);
                end
            end
            
            nestedIndent = [workingIndent self.indent];
            for nn = 1:numel(self.nested)
                self.nested{nn}.print(fid, nestedIndent);
            end
            
            if ~isempty(self.identifier)
                fprintf(fid, '%s%sEnd\n\n', workingIndent, self.identifier);
            end
        end
        
        function index = append(self, node)
            % Append a node nested under this container.
            %   Returns the index where the new node was appended.
            
            if ~isa(node, 'MPbrtNode')
                index = [];
                return;
            end
            
            index = numel(self.nested) + 1;
            self.nested{index} = node;
        end
        
        function existing = find(self, identifier, name, varargin)
            % Find a node nested under this container.
            %   existing = find(self, identifier, name, varargin)
            %   recursively searches this container and nested nodes for a
            %   node that has the given identifier and name.  If found,
            %   returns the node.  Otherwise returns [].
            %
            %   find( ... 'remove', remove) specifies whether to remove the
            %   node that was found from its container (true), or not
            %   (false).  The default is false, don't remove the node.
            
            parser = inputParser();
            parser.addRequired('identifier', @ischar);
            parser.addRequired('name', @ischar);
            parser.addParameter('remove', false, @islogical);
            parser.parse(identifier, name, varargin{:});
            identifier = parser.Results.identifier;
            name = parser.Results.name;
            remove = parser.Results.remove;
            
            % is it this container?
            if strcmp(self.identifier, identifier) && strcmp(self.name, name)
                existing = self;
                return;
            end
            
            % depth-first search of nested nodes
            for nn = 1:numel(self.nested)
                existing = self.nested{nn}.find(identifier, name);
                if ~isempty(existing)
                    if remove
                        self.nested(nn) = [];
                    end
                    return;
                end
            end
            
            % never found a match
            existing = [];
        end
    end
end
