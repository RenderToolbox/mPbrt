# mPbrt
Matlab tools for constructing and writing PBRT scene files. 

For now this is a sandbox repository.  Once we get things working and stable, we should add better intro/info below.

# Initial Thoughts
The basic idea goes like this:  We want to be able to auto-generate [PBRT](http://www.pbrt.org/fileformat.html) scene files from Matlab.  We want to start with a convenient Matlab representation of the whole scene.  We should be able to identify elements of the scene by name and type, and add/update/remove them while working.  When done working, we should have a "dumb" or "mechanical" utility for writing the Matlab representation out to a PBRT text file.

The matlab representation should not be over strict about what can go into the scene.  For example, if PBRT introduces a new scene element of type `Foo` that we haven't seen before, we should still be able to add a `Foo` to the scene in Matlab and get it written to the text file.  We should not have to scratch our heads and say, "Gee, I wish we had thought of Foo back when we were writing this.  Now what do we do?"

So the overall falvor will be "Here's a collection of PBRT top-level and world elements to write out in a formatted way," rather than "Here's a Matlab-based PBRT scene modeling tool."  3D modeling is a separate problem.

For now we are only going one way: from a Matlab representation of a PBRT scene to a PBRT text file.  We are not trying to parse existing PBRT files.
